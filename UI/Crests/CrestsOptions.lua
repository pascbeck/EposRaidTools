-- ui/crests/CrestsOptionsUI.lua

local _, Epos = ...


-- Cached Globals
local DF               = _G.DetailsFramework          -- DetailsFramework library
local UIParent         = _G.UIParent                  -- Parent for UI panels
local CreateFrame      = _G.CreateFrame               -- Frame creation function
local table_insert     = table.insert                 -- Table insert function
local table_sort       = table.sort                   -- Table sort function
local tonumber         = tonumber                     -- Convert string to number
local print            = print                        -- Print to chat
local C                = Epos.Constants               -- Constants table (templates, etc.)
local C_CurrencyInfo   = _G.C_CurrencyInfo            -- Blizzard API for currency info


-- Local Constants
local PANEL_WIDTH    = 485                            -- Width of the options panel
local PANEL_HEIGHT   = 420                            -- Height of the options panel
local SCROLL_WIDTH   = PANEL_WIDTH - 40               -- ScrollBox width (pad 10 each side)
local SCROLL_HEIGHT  = 300                            -- ScrollBox height
local ROW_HEIGHT     = 36                             -- Height of each scroll row
local VISIBLE_ROWS   = 15                             -- Number of visible rows in ScrollBox

--- BuildCrestsOptions()
-- @return Frame  The created crests options frame (hidden by default).
function BuildCrestsOptions()
    -- Create the Main Panel
    local crests_options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "Crests Options",
            "CrestsOptionsFrame",
            { DontRightClickClose = true }
    )
    crests_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    --- Local Helper: PrepareData
    --- Gathers all currently fetched currency IDs into a sorted table with info.
    -- @return table  Array of { id, name, description, iconFileID } entries.
    local function PrepareData()
        local data = {}
        for _, id in ipairs(EposRT.CrestsOptions.fetch) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            local name = (info and info.name) or "Invalid ID"
            local description = (info and info.description) or ""
            local iconFileID = (info and info.iconFileID) or nil

            table_insert(data, {
                id          = id,
                name        = name,
                description = description,
                iconFileID  = iconFileID,
            })
        end

        table_sort(data, function(a, b)
            return a.id < b.id
        end)

        return data
    end

    --- Local Helper: MasterRefresh
    --- Clears and repopulates the ScrollBox with updated currency data.
    -- @param self  ScrollBox  The ScrollBox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    --- Local Helper: refresh
    --- Populates each ScrollBox line with currency icon, name, description.
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
                line.currencyID = entry.id

                -- Icon (if valid)
                if entry.iconFileID then
                    line.iconTexture:SetTexture(entry.iconFileID)
                    line.iconTexture:Show()
                else
                    line.iconTexture:Hide()
                end

                -- Name
                line.nameLabel:SetText(entry.name)

                -- Description (truncate if desired)
                line.descLabel:SetText(entry.description)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the ScrollBox: icon, name, desc, delete button.
    -- @param self  Frame  The parent ScrollBox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with:
    --   - iconTexture   (Texture): Currency icon.
    --   - nameLabel     (FontString): Currency name.
    --   - descLabel     (FontString): Currency description.
    --   - deleteButton  (Button): Button to remove this currency ID from fetch list.
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
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
                    local id = line.currencyID
                    if not id then
                        return
                    end

                    -- Remove id from fetch list
                    local list = EposRT.CrestsOptions.fetch
                    for i = #list, 1, -1 do
                        if list[i] == id then
                            table.remove(list, i)
                            break
                        end
                    end

                    -- Update “show” to first entry or nil
                    if EposRT.CrestsOptions.show == id then
                        EposRT.CrestsOptions.show = list[1] or nil
                    end


                    -- Refresh the dropdown and tab if they exist
                    if EposUI and EposUI.crests_tab then
                        local dd = EposUI.crests_tab.__crestDropdown
                        if dd then
                            dd:Refresh()
                            dd:Select(EposRT.CrestsOptions.show)
                            EposUI.crests_tab:MasterRefresh()
                        end
                    end

                    -- Refresh this options panel’s scrollbox
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
    local crests_scrollbox = DF:CreateScrollBox(
            crests_options_frame,
            "$parentCrestsScrollBox",
            refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            createLineFunc
    )
    crests_options_frame.scrollbox = crests_scrollbox
    crests_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(crests_scrollbox)
    crests_scrollbox.ReajustNumFrames = true
    crests_scrollbox:SetPoint("TOPLEFT", crests_options_frame, "TOPLEFT", 10, -50)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        crests_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the panel is shown
    crests_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    -- Input Area: Add New Currency ID
    local new_label = DF:CreateLabel(crests_options_frame, "New Identifier:", 11)
    new_label:SetPoint("TOPLEFT", crests_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(crests_options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            crests_options_frame,
            function()
                local text = new_entry:GetText():trim()
                local id = tonumber(text)
                if not id then
                    print("Invalid currency ID. Please enter a number.")
                    return
                end

                -- Avoid duplicates
                for _, existing in ipairs(EposRT.CrestsOptions.fetch) do
                    if existing == id then
                        return
                    end
                end

                table_insert(EposRT.CrestsOptions.fetch, id)
                EposRT.CrestsOptions.show = id
                new_entry:SetText("")
                crests_scrollbox:MasterRefresh()

                if EposUI and EposUI.crests_tab then
                    local dd = EposUI.crests_tab.__crestDropdown
                    if dd then
                        dd:Refresh()
                        dd:Select(id)
                        EposUI.crests_tab:MasterRefresh()
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
    crests_options_frame:Hide()
    return crests_options_frame
end
