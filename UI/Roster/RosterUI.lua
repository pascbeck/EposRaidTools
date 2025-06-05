-- ui/roster/RosterUI.lua

local _, Epos = ...

-- Cached Globals
local DF                 = _G.DetailsFramework                -- DetailsFramework library
local CreateFrame        = _G.CreateFrame                     -- Frame creation
local RAID_CLASS_COLORS  = _G.RAID_CLASS_COLORS               -- Class color lookup
local date               = _G.date                            -- Lua date function
local table_insert       = table.insert                       -- Table insert
local table_sort         = table.sort                         -- Table sort

--- BuildRosterTab()
-- @param parent Frame  The parent frame (tab content) to which the roster UI is added.
-- @return Frame  The created scrollbox object, with a `MasterRefresh()` method.
function BuildRosterTab(parent)
    -- Shortcut to constants table for dimensions, templates, and colors
    local C = Epos.Constants

    -- “Request Data” Button (far right)
    local requestDataButton = DF:CreateButton(
            parent,
            OnClick_EditWhitelist,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Request Data",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )
    requestDataButton:SetPoint(
            "TOPRIGHT",
            parent,
            "TOPRIGHT",
            C.tabs.rightPadding,
            C.tabs.startY
    )
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from selected players"

    -- “Roster Options” Button (far left)
    local editRolesButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.database_options then
                    EposUI.database_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Roster Options",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )
    editRolesButton:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY
    )
    editRolesButton:SetAlpha(1)
    editRolesButton.tooltip = "Configure role filters for tracking"

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
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(hr, hg, hb)

    -- Column: Rank
    header.rankLabel = DF:CreateLabel(header, "Rank")
    header.rankLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.rankLabel:SetTextColor(hr, hg, hb)

    -- Column: Status
    header.statusLabel = DF:CreateLabel(header, "Status")
    header.statusLabel:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.statusLabel:SetTextColor(hr, hg, hb)

    -- Column: Updated
    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.updatedLabel:SetTextColor(hr, hg, hb)

    --- Local Helper: PrepareData
    --- Gathers, filters, and formats guild roster data for display.
    -- Filters out players based on tracked roles and blacklist, then sorts by rank.
    -- @return table  Array of player data tables containing: name, rank, class, updated (string).
    local function PrepareData()
        local data = {}
        local tracked = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster or {}) do
            local inDatabase = EposRT.PlayerDatabase and EposRT.PlayerDatabase[player.name]
            local blacklisted = EposRT.Blacklist and EposRT.Blacklist[player.name]

            if tracked[player.rank] and not blacklisted then
                local timestampText = "-"
                if inDatabase and inDatabase.timestamp then
                    timestampText = date("%Y-%m-%d %H:%M:%S", inDatabase.timestamp)
                end

                table_insert(data, {
                    name    = player.name,
                    rank    = player.rank,
                    class   = player.class,
                    updated = timestampText,
                })
            end
        end

        -- Sort by rank ascending
        table_sort(data, function(a, b)
            return a.rank < b.rank
        end)

        return data
    end

    --- Local Helper: Refresh Callback
    --- Populates each visible line in the scrollbox with player data.
    -- @param self       ScrollBox  The scrollbox instance
    -- @param data       table      The array of player data
    -- @param offset     number     Index offset into `data`
    -- @param totalLines number     Number of line frames to update
    local function RefreshLines(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]

            if entry then
                local line = self:GetLine(i)

                -- Class color (fallback to white)
                local color = RAID_CLASS_COLORS[entry.class] or { r = 1, g = 1, b = 1 }

                -- Name column (class-colored)
                line.name:SetText(entry.name)
                line.name:SetTextColor(color.r, color.g, color.b)

                -- Rank column (white)
                line.rank:SetText(entry.rank)
                line.rank:SetTextColor(1, 1, 1)

                -- Status column: default “not in Database” (red)
                line.trackingStatus:SetText("not in Database")
                line.trackingStatus:SetTextColor(1, 0, 0)

                -- If in database, update to “in Database” (green)
                if EposRT.PlayerDatabase and EposRT.PlayerDatabase[entry.name] then
                    line.trackingStatus:SetText("in Database")
                    line.trackingStatus:SetTextColor(0, 1, 0)
                end

                -- Updated column (white)
                line.updated:SetText(entry.updated)
                line.updated:SetTextColor(1, 1, 1)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single line frame for the scrollbox at the given index.
    -- @param self  Frame  The scrollbox frame
    -- @param index number Line index (1-based), used for vertical positioning
    -- @return Frame A new line frame containing four labels: name, rank, trackingStatus, updated
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
                "TOPLEFT",
                self,
                "TOPLEFT",
                1,
                -((index - 1) * self.LineHeight) - 1
        )
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Name label
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Rank label
        line.rank = DF:CreateLabel(line, "")
        line.rank:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Tracking Status label
        line.trackingStatus = DF:CreateLabel(line, "")
        line.trackingStatus:SetPoint("LEFT", line, "LEFT", 300, 0)

        -- Updated timestamp label
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 425, 0)

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
    local rosterScrollBox = DF:CreateScrollBox(
            parent,
            "EposRosterScrollBox",
            RefreshLines,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            createLineFunc
    )

    -- Store reference on parent for external access
    parent.scrollbox = rosterScrollBox
    rosterScrollBox.MasterRefresh = MasterRefresh
    rosterScrollBox.ReajustNumFrames = true

    -- Apply skin to the scroll bar
    DF:ReskinSlider(rosterScrollBox)

    -- Position scrollbox within parent
    rosterScrollBox:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 55
    )

    -- Pre-create exactly VISIBLE_ROWS line frames
    for i = 1, C.tabs.visibleRows do
        rosterScrollBox:CreateLine(createLineFunc)
    end

    -- Refresh when the tab is shown
    rosterScrollBox:SetScript("OnShow", function(self)
        if rosterScrollBox.MasterRefresh then
            rosterScrollBox:MasterRefresh()
        end
    end)

    return rosterScrollBox
end