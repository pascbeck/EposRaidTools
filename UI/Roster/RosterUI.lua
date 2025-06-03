local _, Epos = ...
local DF  = _G["DetailsFramework"]

function BuildRosterTab(parent)
    local buttonWidth = 120
    local buttonHeight = 20
    local spacingX = 10
    local topPadding = -20
    local leftPadding = 10
    local rightPadding = -30
    local startY = -100

    -- “Request Data” goes to far‐left
    local requestDataButton = DF:CreateButton(
        parent,
        OnClick_EditWhitelist,
        buttonWidth,
        buttonHeight,
        "Request Data",
        nil, nil, nil, nil, nil, nil,
        Epos.Constants.templates.button
    )
    requestDataButton:SetPoint("TOPLEFT", parent, "TOPLEFT", leftPadding, startY)
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from current selected players"

    -- “Edit Blacklist” stays at far‐right
    local blacklistButton = DF:CreateButton(
        parent,
        function() EposUI.blacklist_frame:Show() end,
        buttonWidth,
        buttonHeight,
        "Edit Blacklist",
        nil, nil, nil, nil, nil, nil,
        Epos.Constants.templates.button
    )
    blacklistButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", rightPadding, startY)
    blacklistButton:SetAlpha(1)
    blacklistButton.tooltip = "Manually add players to the tracking blacklist"

    -- “Options” (EditRoles) now sits immediately to the left of “Edit Blacklist”
    local editRolesButton = DF:CreateButton(
        parent,
        function() EposUI.edit_roles_frame:Show() end,
        buttonWidth,
        buttonHeight,
        "Options",
        nil, nil, nil, nil, nil, nil,
        Epos.Constants.templates.button
    )
    editRolesButton:SetPoint("RIGHT", blacklistButton, "LEFT", -spacingX, 0)
    editRolesButton:SetAlpha(1)
    editRolesButton.tooltip = "Configure role filters for automatic tracking"

    -- Create header frame for column titles
    local headerHeight = 20
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, startY - 30)
    header:SetSize(Epos.Constants.window_width - 40, headerHeight)
    DF:ApplyStandardBackdrop(header)

    -- Use the same blue as "EposRaidTools" title: RGB (0, 1, 1)
    local headerColorR, headerColorG, headerColorB = 0, 1, 1

    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.rankLabel = DF:CreateLabel(header, "Rank")
    header.rankLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.rankLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.statusLabel = DF:CreateLabel(header, "Status")
    header.statusLabel:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.statusLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.updatedLabel:SetTextColor(headerColorR, headerColorG, headerColorB)

    -- Refresh function for each data line
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local nickData = data[index]
            if nickData then
                local line = self:GetLine(i)

                -- get class color (fallback to white)
                local classColor = RAID_CLASS_COLORS[nickData.class] or { r = 1, g = 1, b = 1 }

                line.name:SetText(nickData.name)
                line.name:SetTextColor(classColor.r, classColor.g, classColor.b)

                line.rank:SetText(nickData.rank)
                line.rank:SetTextColor(1, 1, 1)

                line.trackingStatus:SetText("not in Database")
                line.trackingStatus:SetTextColor(1, 0, 0)

                if EposRT.PlayerDatabase[nickData.name] then
                    line.trackingStatus:SetText("in Database")
                    line.trackingStatus:SetTextColor(0, 1, 0)
                end

                line.updated:SetText(nickData.updated)
                line.updated:SetTextColor(1, 1, 1)
            end
        end
    end

    -- Prepare data for scrollbox
    local function PrepareData()
        local data = {}
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

        table.sort(data, function(a, b)
            return a.rank < b.rank
        end)

        return data
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        line.rank = DF:CreateLabel(line, "")
        line.rank:SetPoint("LEFT", line, "LEFT", 185, 0)

        line.trackingStatus = DF:CreateLabel(line, "")
        line.trackingStatus:SetPoint("LEFT", line, "LEFT", 300, 0)

        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 425, 0)

        return line
    end

    -- figure out exactly how many rows fit in (Epos.Constants.window_height - 165)
    local lineHeight  = 20
    local totalHeight = Epos.Constants.window_height - 180
    local visibleRows = math.floor(totalHeight / lineHeight)

    local roster_scrollbox =
        DF:CreateScrollBox(
            parent,
            "VersionCheckScrollBox",
            refresh,
            {},
            Epos.Constants.window_width - 40,
            totalHeight,
            visibleRows,
            lineHeight,
            createLineFunc
        )
    parent.scrollbox        	   = roster_scrollbox
    roster_scrollbox.MasterRefresh = MasterRefresh

    DF:ReskinSlider(roster_scrollbox)
    roster_scrollbox.ReajustNumFrames = true
    -- moved scrollbox up by 5 pixels as well (startY - 55 instead of startY - 60)
    roster_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, startY - 55)

    -- create exactly as many line frames as will fit on screen
    for i = 1, visibleRows do
        roster_scrollbox:CreateLine(createLineFunc)
    end

    roster_scrollbox:SetScript("OnShow", function(self)
        EposUI.roster_tab:MasterRefresh()
    end)

    return roster_scrollbox
end