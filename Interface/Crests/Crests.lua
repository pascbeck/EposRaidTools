-- interface/crests/Crests.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local CreateFrame = _G.CreateFrame
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local date = _G.date
local table_insert = table.insert
local table_sort = table.sort
local C = Epos.Constants
local C_CurrencyInfo = _G.C_CurrencyInfo

-- @param parent frame (crests tab)
function BuildCrestsInterface(parent)
    -- Request Data Button
    local requestDataButton = DF:CreateButton(
            parent,
            function()
                --
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Request Data",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )
    -- Anchor right
    requestDataButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", C.tabs.rightPadding, C.tabs.startY)
    requestDataButton.tooltip = "Sends data request to current selected players"

    -- Crests Options Button
    local crestsOptionsButton = DF:CreateButton(
            parent,
            function()
                EposUI.CrestsTabOptions:Show()
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Crests Options",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )

    -- Anchor left
    crestsOptionsButton:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    crestsOptionsButton.tooltip = "Displays options panel for crests"

    -- Crest Dropdown Menu
    local crestsDropdown

    local function GetCrestDropdownOptions()
        local t = {}
        for _, id in pairs(EposRT.Crests.Fetch) do
            local currency = C_CurrencyInfo.GetCurrencyInfo(id)
            local name = currency and currency.name or id
            table_insert(t, {
                label   = name,
                value   = id,
                onclick = function(_, _, value)
                    EposRT.Crests.Current = value
                    EposUI.CrestsTab:MasterRefresh()
                end,
            })
        end
        return t
    end

    crestsDropdown = DF:CreateDropDown(parent, GetCrestDropdownOptions, EposRT.Crests.Current, 200, 30)
    crestsDropdown:SetTemplate(C.templates.dropdown)

    -- Anchor left next to 'crestsOptionsButton'
    crestsDropdown:SetPoint("LEFT", crestsOptionsButton, "RIGHT", 15, 0)

    -- Header (Column Titles)
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 30)
    header:SetSize(C.window_width - 40, C.tabs.lineHeight)
    DF:ApplyStandardBackdrop(header)

    -- Column: Name
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Available
    header.crestsAvailable = DF:CreateLabel(header, "Available")
    header.crestsAvailable:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.crestsAvailable:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Obtainable
    header.crestsObtainable = DF:CreateLabel(header, "Obtainable")
    header.crestsObtainable:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.crestsObtainable:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Used
    header.crestsUsed = DF:CreateLabel(header, "Used")
    header.crestsUsed:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.crestsUsed:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Total Earned
    header.crestsTotalEarned = DF:CreateLabel(header, "Total Earned")
    header.crestsTotalEarned:SetPoint("LEFT", header, "LEFT", 525, 0)
    header.crestsTotalEarned:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Updated
    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 650, 0)
    header.updatedLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    local function PrepareData()
        local data = {}

        for _, player in pairs(EposRT.GuildRoster.Players) do
            local playerDatabaseEntry = EposRT.GuildRoster.Database[player.name]
            if playerDatabaseEntry and next(EposRT.Crests.Fetch) then
                local currencies = playerDatabaseEntry.currency
                local current = EposRT.Crests.Current
                local currency = currencies[current]


                if currency then
                    local available = currency.quantity or 0
                    local obtainable = currency.canEarnPerWeek and (currency.maxQuantity - currency.totalEarned) or "Infinite"
                    local used = (currency.totalEarned or 0) - available
                    local totalEarned = currency.totalEarned or 0
                    local tsText = playerDatabaseEntry.timestamp and date("%Y-%m-%d", playerDatabaseEntry.timestamp) or "-"

                    -- only returns tracked players and non blacklisted players
                    if EposRT.GuildRoster.Tracked[player.rank] and not EposRT.GuildRoster.Blacklist[player.name] then
                        table_insert(data, {
                            name = player.name,
                            crestsAvailable = available,
                            crestsObtainable = obtainable,
                            crestsUsed = used,
                            crestsTotalEarned = totalEarned,
                            rank = player.rank,
                            class = player.class,
                            timestamp = tsText,
                        })
                    end
                end
            end
        end

        table_sort(data, function(a, b)
            return a.rank < b.rank
        end)

        return data
    end

    local function Refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local player = data[index]

            if player then
                local line = self:GetLine(i)

                -- Name
                line.name:SetText(player.name)
                line.name:SetTextColor(Epos:GetClassColorForPlayer(player.name))

                -- Available
                line.crestsAvailable:SetText(player.crestsAvailable)

                -- Obtainable
                line.crestsObtainable:SetText(player.crestsObtainable)

                -- Used
                line.crestsUsed:SetText(player.crestsUsed)

                -- Total Earned
                line.crestsTotalEarned:SetText(player.crestsTotalEarned)

                -- Updated timestamp
                line.updated:SetText(player.timestamp)
            end
        end
    end

    local function CreateLine(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * C.tabs.lineHeight) - 1)
        line:SetSize(self:GetWidth() - 2, C.tabs.lineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Name
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Available
        line.crestsAvailable = DF:CreateLabel(line, "")
        line.crestsAvailable:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Obtainable
        line.crestsObtainable = DF:CreateLabel(line, "")
        line.crestsObtainable:SetPoint("LEFT", line, "LEFT", 300, 0)

        -- Used
        line.crestsUsed = DF:CreateLabel(line, "")
        line.crestsUsed:SetPoint("LEFT", line, "LEFT", 425, 0)

        -- Total Earned
        line.crestsTotalEarned = DF:CreateLabel(line, "")
        line.crestsTotalEarned:SetPoint("LEFT", line, "LEFT", 525, 0)

        -- Updated timestamp
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 650, 0)

        return line
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    -- Scroll Box
    local scrollBox = DF:CreateScrollBox(
            parent,
            "crests_data_scroll_box",
            Refresh,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            CreateLine
    )

    scrollBox.MasterRefresh = MasterRefresh
    scrollBox.ReajustNumFrames = true
    DF:ReskinSlider(scrollBox)
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 55)

    -- Pre-create exactly visibleRows line frames for performance
    for i = 1, C.tabs.visibleRows do
        scrollBox:CreateLine(CreateLine)
    end

    -- Refresh when the tab is shown
    scrollBox:SetScript("OnShow", function(self)
        if self.MasterRefresh then
            self:MasterRefresh()
        end
    end)

    -- Append dropdown to parent
    scrollBox.__dropdown = crestsDropdown
    return scrollBox
end