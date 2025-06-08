-- ui/setups-manager/SetupsManagerUI.lua

local  _, Epos           = ...

-- Cached Globals
local DF                 = _G.DetailsFramework                -- DetailsFramework library
local CreateFrame        = _G.CreateFrame                     -- Frame creation
local RAID_CLASS_COLORS  = _G.RAID_CLASS_COLORS               -- Class color lookup
local date               = _G.date                            -- Lua date function
local table_insert       = table.insert                       -- Table insert
local table_sort         = table.sort                         -- Table sort
local C                  = Epos.Constants                     -- Constants

--- BuildRosterTab()
-- @param parent Frame  The parent frame (tab content) to which the setups manager UI is added.
-- @return Frame  The created scrollbox object, with a `MasterRefresh()` method.
function BuildSetupsManagerUI(parent)
    local importRosterData = DF:CreateButton(
            parent,
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
                        -- keep keys in the order they appear in the pasted JSON
                        local orderedBosses = {}
                        for boss in cleaned:gmatch('"([^"]+)"%s*:%s*{') do
                            table_insert(orderedBosses, boss)
                        end

                        EposRT.SetupsManager.setups = data
                        EposRT.SetupsManager.orderedBosses = orderedBosses   -- <- store the right table

                        popup:Hide()
                        EposUI.setup_tab:MasterRefresh()
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
            "TOPRIGHT",
            parent,
            "TOPRIGHT",
            C.tabs.rightPadding,
            C.tabs.startY
    )
    importRosterData:SetAlpha(1)
    importRosterData.tooltip = "Import Setups from google sheet"

    local function GetBossDropdownOptions()
        local opts = {}
        for _, boss in ipairs(EposRT.SetupsManager.orderedBosses or {}) do
            table_insert(opts, {
                label   = boss,
                value   = boss,
                onclick = function(_, _, val)
                    EposRT.SetupsManager.show = val        -- remember selection
                    if parent.scrollbox then               -- refresh list
                        parent.scrollbox:MasterRefresh()
                    end
                end,
            })
        end
        return opts
    end

    local bossDropdown = DF:CreateDropDown(
            parent,
            GetBossDropdownOptions,
            EposRT.SetupsManager.show,     -- initial value or nil
            220, 30)

    bossDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    bossDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY + 5)
    bossDropdown.tooltip = "Choose which boss roster to display"

    local applyRosterBtn = DF:CreateButton(
            parent,
            function()
                local boss = EposRT.SetupsManager.show
                if not boss then
                    DF:Msg("Select a boss first.")
                    return
                end
                -- TODO: replace with your real apply logic
                Epos:ApplyGroups({
                    "Bluupriest",
                    "Rifala",
                    "Xolz-Blackrock",
                    "Olowakandi-Blackrock",
                    "Rifpriest-Teldrassil",
                    "Rifala-Arygos",
                    "Rifdh",
                    "Dafvoker",
                    "Rifalâ",
                    "Ðafuqq-Eredar",
                    "Rifdruid",
                    "Pâran-Blackrock",
                    "Mishyeru",
                    "Rifala-Aegwynn",
                    "Matsuzaka",
                    "Cutesypoo-Eredar",
                    "Greenmagus",
                    "Herumi-Eredar",
                    "Dafuqq-Aegwynn",
                    "Mitcheru-Eredar",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    --"Rifpriest",
                    --"Rifmage",
                    --"Araiguma",
                    --"Pasikari",
                    --"Riflock-Rajaxx",
                    --"Péek-Eredar",
                })
            end,
            C.tabs.buttonWidth, C.tabs.buttonHeight + 8,
            "Apply Roster",
            nil,nil,nil,nil,nil,nil,
            C.templates.button)

    applyRosterBtn:SetPoint("LEFT", bossDropdown, "RIGHT", 15, 0)
    applyRosterBtn.tooltip = "Apply the currently selected roster"

    local clearRoster = DF:CreateButton(
            parent,
            function()
                Epos:Msg("Select a boss first.")
            end,
            C.tabs.buttonWidth, C.tabs.buttonHeight + 8,
            "Clear Setups Table",
            nil,nil,nil,nil,nil,nil,
            C.templates.button)

    clearRoster:SetPoint("LEFT", applyRosterBtn, "RIGHT", 15, 0)
    clearRoster.tooltip = "Clear setups"

    -- Header Frame (Column Titles)
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 30
    )
    header:SetSize(
            C.window_width - 40,
            C.tabs.lineHeight
    )
    DF:ApplyStandardBackdrop(header)

    -- Header text color
    local hr, hg, hb = C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB

    -- Column: Name
    header.label = DF:CreateLabel(header, "Roster")
    header.label:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.label:SetTextColor(hr, hg, hb)

    --- Local Helper: PrepareData
    --- Gathers, filters, and formats guild roster data for display.
    -- Filters out players based on tracked roles and blacklist, then sorts by rank.
    -- @return table  Array of player data tables containing: name, rank, class, updated (string).
    local function PrepareData()
        local out   = {}
        local boss  = EposRT.SetupsManager.show
        local set   = (EposRT.SetupsManager.setups or {})[boss] or {}

        -- fixed order
        local keys   = { "tanks", "healers", "melee", "ranged" }
        local titles = { tanks="Tanks", healers="Healers", melee="Melee", ranged="Ranged" }

        for _, key in ipairs(keys) do
            local players = set[key]
            if players and #players > 0 then
                table_insert(out, { kind="role", text=titles[key], class="" })
                for _, name in ipairs(players) do
                    table_insert(out, { kind="player", text="  "..name, class = EposRT.GuildRoster[name].class })
                end
                table_insert(out, { kind="spacer", text="", class="" })
            end
        end
        return out
    end

    --- Local Helper: Refresh Callback
    --- Populates each visible line in the scrollbox with player data.
    -- @param self       ScrollBox  The scrollbox instance
    -- @param data       table      The array of player data
    -- @param offset     number     Index offset into `data`
    -- @param totalLines number     Number of line frames to update
    local function RefreshLines(self, data, offset, totalLines)
        for i = 1, totalLines do
            local entry = data[i + offset]
            local line = self:GetLine(i)

            if entry then
                line.label:SetText(entry.text)

                -- Default to white unless a class color or role header is provided
                local color = { r = 1, g = 1, b = 1 }

                if entry.kind == "player" and entry.class then
                    local classColor = RAID_CLASS_COLORS[entry.class]
                    if classColor then
                        color = classColor
                    end
                elseif entry.kind == "role" then
                    color = { r = 1, g = 0, b = 1 } -- white for role headers
                end

                line.label:SetTextColor(color.r, color.g, color.b)
                line:Show()
            end
        end
    end


    --- Local Helper: createLineFunc
    --- Creates a single line frame for the scrollbox at the given index.
    -- @param self  Frame  The scrollbox frame
    -- @param index number Line index (1-based), used for vertical positioning
    -- @return Frame A new line frame containing four labels: name, rank, trackingStatus, updated
    local function createLineFunc(self, i)
        local line = CreateFrame("Frame", "$parentLine"..i, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((i-1)*self.LineHeight)-1)
        line:SetSize(self:GetWidth()-2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.label = DF:CreateLabel(line, "")
        line.label:SetPoint("LEFT", line, "LEFT", 5, 0)
        return line
    end

    --- Local Helper: MasterRefresh
    --- Clears existing scrollbox data and repopulates it with fresh roster data.
    -- @param self ScrollBox  The scrollbox instance
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    --- ScrollBox Setup
    local setupsScrollBox = DF:CreateScrollBox(
            parent,
            "EposSetupsScrollBox",
            RefreshLines,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            createLineFunc
    )
    -- Store reference on parent for external access
    parent.scrollbox = setupsScrollBox
    setupsScrollBox.MasterRefresh = MasterRefresh
    setupsScrollBox.ReajustNumFrames = true

    -- Apply skin to the scroll bar
    DF:ReskinSlider(setupsScrollBox)

    -- Position scrollbox within parent
    setupsScrollBox:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 55
    )

    -- Pre-create exactly VISIBLE_ROWS line frames
    for i = 1, C.tabs.visibleRows do
        setupsScrollBox:CreateLine(createLineFunc)
    end

    return setupsScrollBox
end