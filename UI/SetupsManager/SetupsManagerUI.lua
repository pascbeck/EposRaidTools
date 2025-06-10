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
    local setupOptions = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.setup_manager_options then
                    EposUI.setup_manager_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Setup Options",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )

    setupOptions:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY
    )

    local function GetBossDropdownOptions()
        local opts = {}
        for _, boss in ipairs(EposRT.SetupsManager.orderedBosses or {}) do
            table_insert(opts, {
                label   = boss,
                value   = boss,
                onclick = function(_, _, val)
                    EposRT.SetupsManager.show = val
                    -- remember selection
                    if parent.scrollbox then               -- refresh list
                        parent.scrollbox:MasterRefresh()
                    end
                end,
            })
        end
        return opts
    end

    local bossDropdown
    bossDropdown = DF:CreateDropDown(
            parent,
            GetBossDropdownOptions,
            EposRT.SetupsManager.show,     -- initial value or nil
            220, 30)

    bossDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    bossDropdown:SetPoint("LEFT", setupOptions, "RIGHT", 15, 0)
    bossDropdown.tooltip = "Choose which boss roster to display"

    local applyRosterBtn = DF:CreateButton(
            parent,
            function()
                local boss = EposRT.SetupsManager.show
                if not boss then
                    DF:Msg("Select a boss first.")
                    return
                end
                Epos:ApplyGroups(EposRT.SetupsManager.setups[EposRT.SetupsManager.show].sort)
            end,
            C.tabs.buttonWidth, C.tabs.buttonHeight,
            "Apply Roster",
            nil,nil,nil,nil,nil,nil,
            C.templates.button)

    applyRosterBtn:SetPoint("LEFT", bossDropdown, "RIGHT", 15, 0)
    applyRosterBtn.tooltip = "Apply the currently selected roster"

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

    header.tank    = DF:CreateLabel(header, "Tanks")
    header.tank:SetPoint("LEFT", header, "LEFT", 10, 0)
    header.tank:SetWidth(100)
    header.tank:SetTextColor(hr, hg, hb)

    header.healer  = DF:CreateLabel(header, "Healers")
    header.healer:SetPoint("LEFT", header.tank.widget, "RIGHT", 0, 0)
    header.healer:SetWidth(100)
    header.healer:SetTextColor(hr, hg, hb)


    header.melee   = DF:CreateLabel(header, "Melee")
    header.melee:SetPoint("LEFT", header.healer.widget, "RIGHT", 0, 0)
    header.melee:SetWidth(100)
    header.melee:SetTextColor(hr, hg, hb)

    header.ranged  = DF:CreateLabel(header, "Ranged")
    header.ranged:SetPoint("LEFT", header.melee.widget, "RIGHT", 0, 0)
    header.ranged:SetWidth(100)
    header.ranged:SetTextColor(hr, hg, hb)

    header.benched  = DF:CreateLabel(header, "Benched")
    header.benched:SetPoint("LEFT", header.ranged.widget, "RIGHT", 0, 0)
    header.benched:SetWidth(100)
    header.benched:SetTextColor(hr, hg, hb)


    local function stripRealm(name)
        return name and name:match("^[^-]+") or ""
    end

    local function getClassColor(name)
        local class = EposRT.GuildRoster and EposRT.GuildRoster[name] and EposRT.GuildRoster[name].class
        return RAID_CLASS_COLORS[class or ""] or { r = 1, g = 1, b = 1 }
    end

    --- Local Helper: PrepareData
    --- Gathers, filters, and formats guild roster data for display.
    -- Filters out players based on tracked roles and blacklist, then sorts by rank.
    -- @return table  Array of player data tables containing: name, rank, class, updated (string).
    local function PrepareData()
        local data = {}
        local boss = EposRT.SetupsManager.show
        local set = (EposRT.SetupsManager.setups or {})[boss] or {}

        local roles = { "tanks", "healers", "melee", "ranged", "benched" }
        local roleData = {}

        -- Build lists for each role
        for _, role in ipairs(roles) do
            roleData[role] = set[role] or {}
        end

        -- Determine max number of rows needed
        local maxLen = 0
        for _, list in pairs(roleData) do
            maxLen = math.max(maxLen, #list)
        end

        -- Compose rows
        for i = 1, maxLen do
            table.insert(data, {
                tanks   = roleData.tanks[i],
                healers = roleData.healers[i],
                melee   = roleData.melee[i],
                ranged  = roleData.ranged[i],
                benched = roleData.benched[i]
            })
        end

        return data
    end


    --- Local Helper: Refresh Callback
    --- Populates each visible line in the scrollbox with player data.
    -- @param self       ScrollBox  The scrollbox instance
    -- @param data       table      The array of player data
    -- @param offset     number     Index offset into `data`
    -- @param totalLines number     Number of line frames to update
    local function RefreshLines(self, data, offset, totalLines)
        if next(EposRT.SetupsManager.setups or {}) then
            for i = 1, totalLines do
                local entry = data[i + offset]
                local line = self:GetLine(i)

                local function setRole(label, name)
                    if name and name ~= "" then
                        local displayName = stripRealm(name)
                        local color = getClassColor(name)
                        label:SetText(displayName)
                        label:SetTextColor(color.r, color.g, color.b)
                    else
                        label:SetText("")
                        label:SetTextColor(1, 1, 1)
                    end
                end

                if line then
                    if entry then
                        setRole(line.tank, entry.tanks)
                        setRole(line.healer, entry.healers)
                        setRole(line.melee, entry.melee)
                        setRole(line.ranged, entry.ranged)
                        setRole(line.benched, entry.benched)
                    else
                        setRole(line.tank, nil)
                        setRole(line.healer, nil)
                        setRole(line.melee, nil)
                        setRole(line.ranged, nil)
                        setRole(line.benched, nil)
                    end
                end
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

        line.tank    = DF:CreateLabel(line, "")
        line.tank:SetPoint("LEFT", line, "LEFT", 10, 0)
        line.tank:SetWidth(100)

        line.healer  = DF:CreateLabel(line, "")
        line.healer:SetPoint("LEFT", line.tank.widget, "RIGHT", 0, 0)
        line.healer:SetWidth(100)

        line.melee   = DF:CreateLabel(line, "")
        line.melee:SetPoint("LEFT", line.healer.widget, "RIGHT", 0, 0)
        line.melee:SetWidth(100)

        line.ranged  = DF:CreateLabel(line, "")
        line.ranged:SetPoint("LEFT", line.melee.widget, "RIGHT", 0, 0)
        line.ranged:SetWidth(100)

        line.benched  = DF:CreateLabel(line, "")
        line.benched:SetPoint("LEFT", line.ranged.widget, "RIGHT", 0, 0)
        line.benched:SetWidth(100)

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
            "EposSetupScrollBox",
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

    -- Refresh when the tab is shown
    setupsScrollBox:SetScript("OnShow", function(self)
        if self.MasterRefresh then
            self:MasterRefresh()
        end
    end)
    -- Store dropdown reference for external access if needed
    setupsScrollBox.__bossDropdown = bossDropdown

    return setupsScrollBox
end