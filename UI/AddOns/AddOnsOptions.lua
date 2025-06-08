-- ui/addons/AddOnsOptions.lua

local _, Epos = ...

-- Cached Globals
local DF               = _G.DetailsFramework               -- DetailsFramework library
local UIParent         = _G.UIParent                       -- Blizzard UI parent frame
local CreateFrame      = _G.CreateFrame                    -- Frame creation function
local C_AddOns         = _G.C_AddOns                       -- AddOns namespace
local table_insert     = table.insert                      -- Table insert
local table_sort       = table.sort                        -- Table sort
local print            = print                             -- Print to chat
local C                = Epos.Constants                    -- Constants table (templates, sizes, colors)

-- Local Constants
local PANEL_WIDTH    = 485                                 -- Width of the options panel
local PANEL_HEIGHT   = 420                                 -- Height of the options panel
local SCROLL_WIDTH   = PANEL_WIDTH - 40                    -- ScrollBox width (pad 10 each side)
local SCROLL_HEIGHT  = 300                                 -- ScrollBox height
local ROW_HEIGHT     = 40                                  -- Height of each scroll row
local VISIBLE_ROWS   = 15                                  -- Number of visible rows in ScrollBox

--- BuildAddOnsOptions()
-- @return Frame  The created AddOns options frame (hidden by default).
function BuildAddOnsOptions()
    -- Create the Main Panel
    local ao_options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "AddOns Options",
            "AddOnsOptionsFrame",
            { DontRightClickClose = true }
    )
    ao_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    --- Local Helper: PrepareData
    --- Gathers all currently tracked AddOn folder names into a sorted table with info.
    -- @return table  Array of { id, name, description, iconFileID } entries.
    local function PrepareData()
        local data = {}
        for _, folderName in ipairs(EposRT.AddOnsOptions.fetch) do
            -- Check metadata for Title/Notes/IconTexture
            local title       = C_AddOns.GetAddOnMetadata(folderName, "Title") or folderName
            local description = C_AddOns.GetAddOnMetadata(folderName, "Notes") or ""
            local iconFileID  = C_AddOns.GetAddOnMetadata(folderName, "IconTexture") or nil

            table_insert(data, {
                id          = folderName,
                name        = title,
                description = description,
                iconFileID  = iconFileID,
            })
        end
        table_sort(data, function(a, b) return a.id < b.id end)
        return data
    end

    --- Local Helper: MasterRefresh
    --- Clears and repopulates the ScrollBox with updated AddOn data.
    -- @param self  ScrollBox  The ScrollBox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    --- Local Helper: refresh
    --- Populates each ScrollBox line with AddOn info.
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
                line.addonID = entry.id

                -- Icon (if provided by metadata; otherwise hide)
                local iconPath = entry.iconFileID or ""
                if iconPath ~= "" then
                    line.iconTexture:SetTexture(iconPath)
                    line.iconTexture:Show()
                else
                    line.iconTexture:Hide()
                end

                -- Name (Title)
                line.nameLabel:SetText(entry.name)

                -- Description (Notes)
                -- line.descLabel:SetText(entry.description)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the ScrollBox: icon, name, desc, delete button.
    -- @param self  Frame  The parent ScrollBox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with:
    --   - iconTexture   (Texture): AddOn icon (if any).
    --   - nameLabel     (FontString): AddOn title.
    --   - descLabel     (FontString): AddOn notes.
    --   - deleteButton  (Button): Button to remove this AddOn from fetch list.
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
        line.iconTexture:SetSize(32, 32)
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
                    local id = line.addonID
                    if not id then
                        return
                    end

                    -- Remove id from fetch list
                    local list = EposRT.AddOnsOptions.fetch
                    for i = #list, 1, -1 do
                        if list[i] == id then
                            table.remove(list, i)
                            break
                        end
                    end

                    -- Update “show” to first entry or nil
                    if EposRT.AddOnsOptions.show == id then
                        EposRT.AddOnsOptions.show = list[1] or nil
                    end
                    if not next(EposRT.AddOnsOptions.fetch or {}) then
                        EposRT.AddOnsOptions.show = nil
                    end

                    -- Refresh the dropdown and tab if they exist
                    if EposUI and EposUI.addons_tab then
                        local dd = EposUI.addons_tab.__addonDropdown
                        if dd then
                            dd:Refresh()
                            dd:Select(EposRT.AddOnsOptions.fetch[1])
                            EposUI.addons_tab:MasterRefresh()
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
    local ao_scrollbox = DF:CreateScrollBox(
            ao_options_frame,
            "$parentAddOnsScrollBox",
            refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            createLineFunc
    )
    ao_options_frame.scrollbox = ao_scrollbox
    ao_scrollbox.MasterRefresh = MasterRefresh
    ao_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(ao_scrollbox)
    ao_scrollbox:SetPoint("TOPLEFT", ao_options_frame, "TOPLEFT", 10, -50)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        ao_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the panel is shown
    ao_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    -- Input Area: Add New AddOn Folder Name
    local new_label = DF:CreateLabel(ao_options_frame, "New AddOn Folder:", 11)
    new_label:SetPoint("TOPLEFT", ao_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(ao_options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            ao_options_frame,
            function()
                local input = new_entry:GetText():trim()
                if input == "" then
                    return
                end

                -- Avoid duplicates
                for _, existing in ipairs(EposRT.AddOnsOptions.fetch) do
                    if existing == input then
                        return
                    end
                end

                -- Validate that this AddOn folder actually exists (via metadata Title)
                local title = C_AddOns.GetAddOnMetadata(input, "Title")
                if not title then
                    print("Invalid AddOn folder: "..input)
                    return
                end

                table_insert(EposRT.AddOnsOptions.fetch, input)
                EposRT.AddOnsOptions.show = input
                new_entry:SetText("")
                ao_scrollbox:MasterRefresh()

                if EposUI and EposUI.addons_tab then
                    local dd = EposUI.addons_tab.__addonDropdown
                    if dd then
                        dd:Refresh()
                        dd:Select(input)
                        EposUI.addons_tab:MasterRefresh()
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
    ao_options_frame:Hide()
    return ao_options_frame
end
