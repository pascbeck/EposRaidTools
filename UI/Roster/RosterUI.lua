-- ui/Roster/RosterUI
local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildRosterTab(parent)
    --- Shortcut to our constants table
    local C = Epos.Constants

    --- Buttons

    -- "Request Data" Button (far right)
    local requestDataButton = DF:CreateButton(
        parent,
        OnClick_EditWhitelist,             -- click handler
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "Request Data",                     -- button text
        nil, nil, nil,                      -- unused padding/anchor arguments
        nil, nil, nil,                      -- unused padding/anchor arguments
        C.templates.button
    )
    requestDataButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", C.tabs.rightPadding, C.tabs.startY)
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from current selected players"

    -- "Roster Options" Button (far left)
    local editRolesButton = DF:CreateButton(
        parent,
        function() EposUI.database_options:Show() end,  -- click handler to show options
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "Roster Options",                    -- button text
        nil, nil, nil,                       -- unused padding/anchor arguments
        nil, nil, nil,                       -- unused padding/anchor arguments
        C.templates.button
    )
    editRolesButton:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    editRolesButton:SetAlpha(1)
    editRolesButton.tooltip = "Configure role filters for automatic tracking"

    --- Header Frame for column titles
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 30)
    header:SetSize(C.window_width - 40, C.tabs.lineHeight)
    DF:ApplyStandardBackdrop(header)

    -- Header text color (same as "EposRaidTools" title: RGB from C.colors)
    local headerColorR, headerColorG, headerColorB = C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB

    -- Column: Name
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    -- Column: Rank
    header.rankLabel = DF:CreateLabel(header, "Rank")
    header.rankLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.rankLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    -- Column: Status
    header.statusLabel = DF:CreateLabel(header, "Status")
    header.statusLabel:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.statusLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    -- Column: Updated
    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.updatedLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    --- Refresh function to populate each line with data
    -- @param self       The scrollbox object that holds all line frames
    -- @param data       Table containing player entries
    -- @param offset     Starting index offset into the data table
    -- @param totalLines Number of line frames to update
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index    = i + offset
            local nickData = data[index]

            if nickData then
                local line = self:GetLine(i)

                -- Determine class color (fallback to white if missing)
                local classColor = RAID_CLASS_COLORS[nickData.class] or { r = 1, g = 1, b = 1 }

                -- Name column (colored by class)
                line.name:SetText(nickData.name)
                line.name:SetTextColor(classColor.r, classColor.g, classColor.b)

                -- Rank column (white text)
                line.rank:SetText(nickData.rank)
                line.rank:SetTextColor(1, 1, 1)

                -- Status column: default to "not in Database" (red)
                line.trackingStatus:SetText("not in Database")
                line.trackingStatus:SetTextColor(1, 0, 0)

                -- If player exists in database, update status to "in Database" (green)
                if EposRT.PlayerDatabase[nickData.name] then
                    line.trackingStatus:SetText("in Database")
                    line.trackingStatus:SetTextColor(0, 1, 0)
                end

                -- Updated column (white text)
                line.updated:SetText(nickData.updated)
                line.updated:SetTextColor(1, 1, 1)
            end
        end
    end

    --- Prepares and returns filtered, formatted roster data.
    -- Gathers guild roster entries, filters by tracked roles and blacklist,
    -- and formats the timestamp if available.
    --
    -- @return table Sorted list of player data tables, each containing:
    --   - name    (string): Player's name
    --   - rank    (number): Player's guild rank
    --   - class   (string): Player's class
    --   - updated (string): Last updated timestamp (YYYY-MM-DD HH:MM:SS or "-")
    local function PrepareData()
        local data         = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster) do
            local databasePlayer = EposRT.PlayerDatabase[player.name]
            if trackedRoles[player.rank] and not EposRT.Blacklist[player.name] then
                table.insert(data, {
                    name    = player.name,
                    rank    = player.rank,
                    class   = player.class,
                    updated = databasePlayer and date("%Y-%m-%d %H:%M:%S", databasePlayer.timestamp) or "-"
                })
            end
        end

        -- Sort players by rank ascending
        table.sort(data, function(a, b)
            return a.rank < b.rank
        end)

        return data
    end

    --- MasterRefresh: clears existing data and repopulates the scrollbox
    -- @param self The scrollbox object
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    --- Creates and returns a single row line for the scrollbox.
    -- Each line is a frame with labels for name, rank, status, and updated timestamp,
    -- positioned based on its index within the scrollable area.
    --
    -- @param self  Frame  The parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with attached label elements:
    --   - name           (FontString): Player name
    --   - rank           (FontString): Player rank
    --   - trackingStatus (FontString): Whether player is in database
    --   - updated        (FontString): Last update timestamp
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
            "TOPLEFT",
            self,
            "TOPLEFT",
            1,
            -((index - 1) * (self.LineHeight)) - 1
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

    --- ScrollBox Setup
    local roster_scrollbox = DF:CreateScrollBox(
        parent,
        "VersionCheckScrollBox",             -- unique scrollbox name
        refresh,                             -- refresh function
        {},                                  -- initial empty data
        C.window_width - 40,                 -- scrollbox width
        C.tabs.totalHeight,                  -- scrollbox height
        C.tabs.visibleRows,                  -- number of visible rows
        C.tabs.lineHeight,                   -- height of each row
        createLineFunc                       -- line creation function
    )

    parent.scrollbox                = roster_scrollbox
    roster_scrollbox.MasterRefresh  = MasterRefresh
    roster_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(roster_scrollbox)

    -- Position scrollbox slightly higher (startY - 55 instead of startY - 60)
    roster_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 55)

    -- Create exactly as many line frames as will fit on screen
    for i = 1, C.tabs.visibleRows do
        roster_scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow handler: refresh data whenever tab is shown
    roster_scrollbox:SetScript("OnShow", function(self)
        EposUI.roster_tab:MasterRefresh()
    end)

    return roster_scrollbox
end