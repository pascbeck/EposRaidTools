local _, Epos = ...
local DF  = _G["DetailsFramework"]

function BuildCrestsTab(parent)
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
    requestDataButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", rightPadding, startY)
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from current selected players"

    -- “Edit Blacklist” stays at far‐right
    local blacklistButton = DF:CreateButton(
        parent,
        function() EposUI.crests_options:Show() end,
        buttonWidth,
        buttonHeight,
        "Crests Options",
        nil, nil, nil, nil, nil, nil,
        Epos.Constants.templates.button
    )
    blacklistButton:SetPoint("TOPLEFT", parent, "TOPLEFT", leftPadding, startY)
    blacklistButton:SetAlpha(1)
    blacklistButton.tooltip = "Manually add players to the tracking blacklist"

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

    header.crestsAvailable = DF:CreateLabel(header, "Available")
    header.crestsAvailable:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.crestsAvailable:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.crestsObtainable = DF:CreateLabel(header, "Obtainable")
    header.crestsObtainable:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.crestsObtainable:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.crestsUsed = DF:CreateLabel(header, "Used")
    header.crestsUsed:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.crestsUsed:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.crestsTotalEarned = DF:CreateLabel(header, "Total Earned")
    header.crestsTotalEarned:SetPoint("LEFT", header, "LEFT", 525, 0)
    header.crestsTotalEarned:SetTextColor(headerColorR, headerColorG, headerColorB)

    header.updated = DF:CreateLabel(header, "Updated")
    header.updated:SetPoint("LEFT", header, "LEFT", 650, 0)
    header.updated:SetTextColor(headerColorR, headerColorG, headerColorB)

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

                line.crestsAvailable:SetText(nickData.crestsAvailable)
                line.crestsObtainable:SetText(nickData.crestsObtainable)
                line.crestsUsed:SetText(nickData.crestsUsed)
                line.crestsTotalEarned:SetText(nickData.crestsTotalEarned)
                line.updated:SetText("321")
            end
        end
    end

    -- Prepare data for scrollbox
    local function PrepareData()
        local data = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster) do
            local db = EposRT.PlayerDatabase[player.name]

            if db then
                local currency = db.currency

                local useTotalEarnedForMaxQty = currency.useTotalEarnedForMaxQty

                local crestsAvailable   = currency.quantity
                local crestsObtainable  = currency.canEarnPerWeek and (currency.maxQuantity - currency.totalEarned) or "Infinite"
                local crestsUsed        = currency.totalEarned - currency.quantity
                local crestsTotalEarned = currency.totalEarned


                if trackedRoles[player.rank] and not EposRT.Blacklist[player.name] then
                    table.insert(data, {
                        name                = player.name,
                        crestsAvailable     = crestsAvailable,
                        crestsObtainable    = crestsObtainable,
                        crestsUsed          = crestsUsed,
                        crestsTotalEarned   = crestsTotalEarned,
                    })
                end
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

        line.crestsAvailable = DF:CreateLabel(line, "")
        line.crestsAvailable:SetPoint("LEFT", line, "LEFT", 185, 0)

        line.crestsObtainable = DF:CreateLabel(line, "")
        line.crestsObtainable:SetPoint("LEFT", line, "LEFT", 300, 0)

        line.crestsUsed = DF:CreateLabel(line, "")
        line.crestsUsed:SetPoint("LEFT", line, "LEFT", 425, 0)

        line.crestsTotalEarned = DF:CreateLabel(line, "")
        line.crestsTotalEarned:SetPoint("LEFT", line, "LEFT", 525, 0)

        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 650, 0)

        return line
    end

    -- figure out exactly how many rows fit in (Epos.Constants.window_height - 165)
    local lineHeight  = 20
    local totalHeight = Epos.Constants.window_height - 180
    local visibleRows = math.floor(totalHeight / lineHeight)

    local crests_scrollbox =
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
    parent.scrollbox        	   = crests_scrollbox
    crests_scrollbox.MasterRefresh = MasterRefresh

    DF:ReskinSlider(crests_scrollbox)
    crests_scrollbox.ReajustNumFrames = true
    -- moved scrollbox up by 5 pixels as well (startY - 55 instead of startY - 60)
    crests_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, startY - 55)

    -- create exactly as many line frames as will fit on screen
    for i = 1, visibleRows do
        crests_scrollbox:CreateLine(createLineFunc)
    end

    crests_scrollbox:SetScript("OnShow", function(self)
        EposUI.crests_tab:MasterRefresh()
    end)

    return crests_scrollbox
end