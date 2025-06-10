-- interface/setups/Setups+Options.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local UIParent = _G.UIParent
local CreateFrame = _G.CreateFrame
local table_insert = table.insert
local table_sort = table.sort

local C = Epos.Constants

-- Local Constants
local PANEL_WIDTH = 485
local PANEL_HEIGHT = 400
local SCROLL_WIDTH = PANEL_WIDTH - 40
local SCROLL_HEIGHT = 300
local ROW_HEIGHT = 37
local VISIBLE_ROWS = 15

function BuildSetupsInterfaceOptions()
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
                Epos:ImportSetups(setup_options_frame)
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

    local function PrepareData()
        local data = {}

        local bossIcons = {
            ["1 Vexie Fullthrottle and The Geargrinders"] = 6392628,
            ["2 Cauldron of Carnage"] = 6253176,
            ["3 Rik Reverb"] = 6392625,
            ["4 Stix Bunkjunker"] = 6392627,
            ["5 Sprocketmonger Lockenstock"] = 6392626,
            ["6 The One-Armed Bandit"] = 6392624,
            ["7 Mug'Zee"] = 6392623,
            ["8 Chrome King Gallywix"] = 6392621,
        }

        for boss, setup in pairs(EposRT.Setups.JSON) do
            table_insert(data, {
                name = boss,
                icon = bossIcons[boss]
            })
        end

        table_sort(data, function(a, b)
            return a.name < b.name
        end)

        return data
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    local function refresh(self, data, offset, totalLines)
        if next(EposRT.Setups.JSON) then
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
        line.nameLabel:SetWidth(300)


        -- Delete button (12x12) at far right
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    local id = line.nameLabel.text
                    if not id then return end

                    Epos:DeleteSetup(id, setup_options_frame)
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
                    --
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

    local scrollBox = DF:CreateScrollBox(
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
    setup_options_frame.scrollbox = scrollBox
    scrollBox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(scrollBox)
    scrollBox.ReajustNumFrames = true
    scrollBox:SetPoint("TOPLEFT", importRosterData.button, "TOPLEFT", 0, -36)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        scrollBox:CreateLine(createLineFunc)
    end

    -- Refresh when the panel is shown
    scrollBox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    setup_options_frame:Hide()
    return setup_options_frame
end

function Epos:ImportSetups(parent)
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
            -- Clear the previous data
            wipe(EposRT.Setups.JSON)
            local orderedBosses = {}

            for boss in cleaned:gmatch('"([^"]+)"%s*:%s*{') do
                table.insert(orderedBosses, boss)
            end

            EposRT.Setups.JSON = data
            EposRT.Setups.Current = { Boss = orderedBosses[1], Setup = data[orderedBosses[1]] }

            local dropdown = EposUI.SetupsTab.__bossDropdown
            dropdown:Refresh()
            dropdown:Select(EposRT.Setups.Current.Boss)
            EposUI.SetupsTab:MasterRefresh()
            parent.scrollbox:MasterRefresh()
            popup:Hide()
        end
    end)
end

function Epos:DeleteSetup (boss, parent)
    EposRT.Setups.JSON[boss] = nil

    if EposRT.Setups.Current.Boss == boss then
        local _boss, _setup = next(EposRT.Setups.JSON)
        EposRT.Setups.Current = { Boss = _boss, Setup = _setup }

        local dropdown = EposUI.SetupsTab.__bossDropdown
        dropdown:Refresh()
        dropdown:Select(_boss)
    end


    EposUI.SetupsTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end