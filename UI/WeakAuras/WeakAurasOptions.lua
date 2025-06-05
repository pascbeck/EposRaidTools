-- ui/weakauras/WeakAurasOptionsUI.lua

local _, Epos = ...

-- Cached Globals
local DF               = _G.DetailsFramework               -- DetailsFramework library
local UIParent         = _G.UIParent                       -- Blizzard UI parent frame
local CreateFrame      = _G.CreateFrame                    -- Frame creation function
local WeakAuras        = _G.WeakAuras                      -- WeakAuras global
local table_insert     = table.insert                      -- Table insert
local table_sort       = table.sort                        -- Table sort
local strfind          = _G.strfind                        -- String find
local print            = print                             -- Print to chat
local C                = Epos.Constants                    -- Constants table (templates, sizes, colors)

-- Local Constants
local PANEL_WIDTH    = 485                                 -- Width of the options panel
local PANEL_HEIGHT   = 420                                 -- Height of the options panel
local SCROLL_WIDTH   = PANEL_WIDTH - 40                    -- ScrollBox width (pad 10 each side)
local SCROLL_HEIGHT  = 300                                 -- ScrollBox height
local ROW_HEIGHT     = 36                                  -- Height of each scroll row
local VISIBLE_ROWS   = 15                                  -- Number of visible rows in ScrollBox

--- BuildWeakAurasOptions()
-- @return Frame  The created WeakAuras options frame (hidden by default).
function BuildWeakAurasOptions()
    -- Create the Main Panel
    local wa_options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "WeakAuras Options",
            "WeakAurasOptionsFrame",
            { DontRightClickClose = true }
    )
    wa_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    --- Local Helper: PrepareData
    --- Gathers all currently fetched WeakAura set IDs into a sorted table with info.
    -- Replace WeakAuras.GetData(id) with your actual API if needed.
    -- @return table  Array of { id, name, description, iconFileID } entries.
    local function PrepareData()
        local data = {}
        for _, id in ipairs(EposRT.WeakAurasOptions.fetch) do
            local info = WeakAuras and WeakAuras.GetData(id) or nil
            local name = (info and info.id) or id
            local description = (info and info.desc) or ""
            local iconFileID = (info and info.icon) or nil

            table_insert(data, {
                id          = id,
                name        = name,
                description = description,
                iconFileID  = iconFileID,
            })
        end
        table_sort(data, function(a, b) return a.id < b.id end)
        return data
    end

    --- Local Helper: MasterRefresh
    --- Clears and repopulates the ScrollBox with updated WeakAura data.
    -- @param self  ScrollBox  The ScrollBox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    --- Local Helper: refresh
    --- Populates each ScrollBox line with WeakAura set info.
    -- @param self       ScrollBox  The ScrollBox instance.
    -- @param data       table      Array returned by PrepareData().
    -- @param offset     number     Starting index offset into data.
    -- @param totalLines number     Number of line frames to update.
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]
            if entry then
                local line = self:GetLine(i)
                line.waSetID = entry.id

                -- Icon
                line.iconTexture:SetTexture("Interface\\AddOns\\EposRaidTools\\Media\\logo_64.tga")
                line.iconTexture:Show()

                -- Name
                line.nameLabel:SetText(entry.name)

                -- Description (truncate if needed)
                line.descLabel:SetText(entry.description)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the ScrollBox: icon, name, desc, delete button.
    -- @param self  Frame  The parent ScrollBox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with:
    --   - iconTexture   (Texture): WeakAura icon.
    --   - nameLabel     (FontString): WeakAura name.
    --   - descLabel     (FontString): WeakAura description.
    --   - deleteButton  (Button): Button to remove this WeakAura ID from fetch list.
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine"..index, self, "BackdropTemplate")
        line:SetPoint(
                "TOPLEFT",
                self,
                "TOPLEFT",
                1,
                -((index - 1) * ROW_HEIGHT) - 1
        )
        line:SetSize(self:GetWidth() - 2, ROW_HEIGHT)
        DF:ApplyStandardBackdrop(line)

        -- Icon (24x24) at left
        line.iconTexture = line:CreateTexture(nil, "ARTWORK")
        line.iconTexture:SetSize(24, 24)
        line.iconTexture:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Name label (next to icon)
        line.nameLabel = DF:CreateLabel(line, "")
        line.nameLabel:SetPoint("LEFT", line.iconTexture, "RIGHT", 8, 0)
        line.nameLabel:SetWidth(240)

        -- Description label (to the right of name)
        line.descLabel = DF:CreateLabel(line, "")
        line.descLabel:SetPoint("LEFT", line.nameLabel, "RIGHT", 10, 0)
        line.descLabel:SetWidth(200)
        line.descLabel:SetJustifyH("LEFT")

        -- Delete button (12x12) at far right
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    local id = line.waSetID
                    if not id then
                        return
                    end

                    -- Remove id from fetch list
                    local list = EposRT.WeakAurasOptions.fetch
                    for i = #list, 1, -1 do
                        if list[i] == id then
                            table.remove(list, i)
                            break
                        end
                    end

                    -- Update “show” to first entry or nil
                    if EposRT.WeakAurasOptions.show == id then
                        EposRT.WeakAurasOptions.show = list[1] or nil
                    end
                    if not next(EposRT.WeakAurasOptions.fetch or {}) then
                        EposRT.WeakAurasOptions.show = nil
                    end

                    -- Refresh the dropdown and tab if they exist
                    if EposUI and EposUI.weakauras_tab then
                        local dd = EposUI.weakauras_tab.__waDropdown
                        if dd then
                            dd:Refresh()
                            dd:Select(EposRT.WeakAurasOptions.fetch[1])
                            EposUI.weakauras_tab:MasterRefresh()
                        end
                    end

                    -- Refresh this panel’s scrollbox
                    line:GetParent():MasterRefresh()
                end,
                12,
                12
        )
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    -- ScrollBox Setup
    local wa_scrollbox = DF:CreateScrollBox(
            wa_options_frame,
            "$parentWeakAurasScrollBox",
            refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            createLineFunc
    )
    wa_options_frame.scrollbox = wa_scrollbox
    wa_scrollbox.MasterRefresh = MasterRefresh
    wa_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(wa_scrollbox)
    wa_scrollbox:SetPoint("TOPLEFT", wa_options_frame, "TOPLEFT", 10, -50)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        wa_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the panel is shown
    wa_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    -- Input Area: Add New WeakAura Set ID
    local new_label = DF:CreateLabel(wa_options_frame, "New Identifier:", 11)
    new_label:SetPoint("TOPLEFT", wa_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(wa_options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            wa_options_frame,
            function()
                local input = new_entry:GetText():trim()
                if input == "" then
                    return
                end

                -- Avoid duplicates
                for _, existing in ipairs(EposRT.WeakAurasOptions.fetch) do
                    if existing == input then
                        return
                    end
                end

                local waData = WeakAuras and WeakAuras.GetData(input) or nil
                if not waData then
                    print("Invalid WeakAura ID: "..input)
                    return
                end

                table_insert(EposRT.WeakAurasOptions.fetch, input)
                EposRT.WeakAurasOptions.show = input
                new_entry:SetText("")
                wa_scrollbox:MasterRefresh()

                if EposUI and EposUI.weakauras_tab then
                    local dd = EposUI.weakauras_tab.__waDropdown
                    if dd then
                        dd:Refresh()
                        dd:Select(input)
                        EposUI.weakauras_tab:MasterRefresh()
                    end
                end
            end,
            60,
            20,
            "Add",
            nil, nil, nil,
            C.templates.button
    )
    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)

    -- Hide Panel by Default
    wa_options_frame:Hide()
    return wa_options_frame
end
