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
local ROW_HEIGHT     = 37                                  -- Height of each scroll row
local VISIBLE_ROWS   = 15                                  -- Number of visible rows in ScrollBox

function BuildSetupsManagerOptions()
    -- Create the Main Panel
    local setup_options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "AddOns Options",
            "AddOnsOptionsFrame",
            { DontRightClickClose = true }
    )
    setup_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local importRosterData = DF:CreateButton(
            setup_options_frame,
            function()
                local popup = DF:CreateSimplePanel(EposUI, 300, 150, "Import SetupsDev", "EposImportSetupsPopup",
                        { DontRightClickClose = true })
                popup:SetPoint("CENTER")
                popup:SetFrameLevel(100)

                popup.editBox = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "SendWATextEdit", true, false, true)
                popup.editBox:SetPoint("TOPLEFT", 10, -30)
                popup.editBox:SetPoint("BOTTOMRIGHT", -30, 40)
                DF:ApplyStandardBackdrop(popup.editBox)
                DF:ReskinSlider(popup.editBox.scroll)
                popup.editBox:SetFocus()

                popup.confirmBtn = DF:CreateButton(popup, nil, 280, 20, "Import", nil,nil,nil,nil,nil,nil, C.templates.button)
                popup.confirmBtn:SetPoint("BOTTOM", 0, 10)

                popup.confirmBtn:SetScript("OnClick", function()
                    local cleaned = popup.editBox:GetText()
                    popup.editBox:SetText(cleaned)
                    local data, err = json.decode(cleaned)
                    if not data then
                        print("JSON decode error:", err)
                    else
                        DevTools_Dump(data)
                        wipe(EposRT.SetupsManager.setups or {})
                        wipe(EposRT.SetupsManager.orderedBosses or {})
                        -- keep keys in the order they appear in the pasted JSON
                        local orderedBosses = {}
                        for boss in cleaned:gmatch('"([^"]+)"%s*:%s*{') do
                            table_insert(orderedBosses, boss)
                        end

                        EposRT.SetupsManager.setups = data
                        EposRT.SetupsManager.orderedBosses = orderedBosses   -- <- store the right table
                        EposRT.SetupsManager.show = orderedBosses[1]

                        -- Refresh the dropdown and tab if they exist
                        if EposUI and EposUI.setup_tab then
                            local dd = EposUI.setup_tab.__bossDropdown
                            if dd then
                                dd:Refresh()
                                dd:Select(EposRT.SetupsManager.show)
                                EposUI.setup_tab:MasterRefresh()
                            end
                        end

                        popup:Hide()
                        EposUI.setup_tab:MasterRefresh()
                        setup_options_frame.scrollbox:MasterRefresh()
                    end

                end)
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Import Setup",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )

    importRosterData:SetPoint(
            "TOPLEFT",
            setup_options_frame,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY + 60
    )
    importRosterData:SetAlpha(1)
    importRosterData.tooltip = "Import Setups from google sheet"

    --- Local Helper: PrepareData
    --- Gathers all currently tracked AddOn folder names into a sorted table with info.
    -- @return table  Array of { id, name, description, iconFileID } entries.
    local function PrepareData()
        local data = {}

        local bossIcons = {
            ["Vexie Fullthrottle and The Geargrinders"] = 6392628,
            ["Cauldron of Carnage"] = 6253176,
            ["Rik Reverb"] = 6392625,
            ["Stix Bunkjunker"] = 6392627,
            ["The One-Armed Bandit"] = 6392624,
            ["One Armed Bandit"] = 6392624,
            ["Mug'Zee"] = 6392623, -- example: use a generic skull or mug icon
            ["Chrome King Gallywix"] = 6392621,
            ["Sprocketmonger Lockenstock"] = 6392626,
        }

        for _, t in ipairs(EposRT.SetupsManager.orderedBosses or {}) do
            table_insert(data, {
                name = t,
                icon = bossIcons[t]
            })
        end
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
        if next(EposRT.SetupsManager.setups or {}) then
            for i = 1, totalLines do
                local index = i + offset
                local entry = data[index]
                if entry then
                    local line = self:GetLine(i)


                    if entry and entry.icon then
                        line.iconTexture:SetTexture(entry.icon)  -- <- numeric icon ID
                        line.iconTexture:Show()
                    else
                        line.iconTexture:Hide()
                    end

                    -- Name (Title)
                    line.nameLabel:SetText(entry.name)
                end
            end
        end

    end

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


        -- Delete button (12x12) at far right
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    local id = line.nameLabel.text
                    if not id then
                        return
                    end
                    -- Remove id from fetch list
                    local list = EposRT.SetupsManager.orderedBosses
                    for i = #list, 1, -1 do
                        if list[i] == id then
                            table.remove(list, i)
                            break
                        end
                    end

                    EposRT.SetupsManager.setups[id] = nil



                    if EposRT.SetupsManager.show == id then
                        EposRT.SetupsManager.show = list[1] or nil
                    end

                    if not next(EposRT.SetupsManager.orderedBosses or {}) then
                        EposRT.SetupsManager.show = nil
                    end


                    -- Refresh the dropdown and tab if they exist
                    if EposUI and EposUI.setup_tab then
                        local dd = EposUI.setup_tab.__bossDropdown
                        if dd then
                            dd:Refresh()
                            dd:Select(EposRT.SetupsManager.show)
                            EposUI.setup_tab:MasterRefresh()
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

        -- Apply button (DF button, slightly left of delete button)
        line.applyButton = DF:CreateButton(
                line,
                function()
                    local id = line.nameLabel.text
                    if id then
                        Epos:ApplyGroups(EposRT.SetupsManager.setups[id].sort)
                    end
                end,
                50, -- width
                20, -- height
                "Apply", -- label
                nil, nil, nil,
                nil, nil, nil,
                C.templates.button
        )
        line.applyButton:SetPoint("RIGHT", line.deleteButton, "LEFT", -5, 0)

        return line
    end
    -- ScrollBox Setup
    local crests_scrollbox = DF:CreateScrollBox(
            setup_options_frame,
            "$parentEposSetupScrollBox",
            refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            createLineFunc
    )
    setup_options_frame.scrollbox = crests_scrollbox
    crests_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(crests_scrollbox)
    crests_scrollbox.ReajustNumFrames = true
    crests_scrollbox:SetPoint("TOPLEFT", importRosterData.button, "TOPLEFT", 0, -36)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        crests_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the panel is shown
    crests_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    setup_options_frame:Hide()
    return setup_options_frame
end