-- ui/database/Database.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local CreateFrame = _G.CreateFrame
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local date = _G.date
local table_insert = table.insert
local table_sort = table.sort
local C = Epos.Constants

-- @param parent frame (database tab)
function BuildDatabaseInterface(parent)
    -- Request Data Button
    local requestDataButton = DF:CreateButton(
            parent,
            function()
                Epos:RequestData("EPOS_REQUEST", "GUILD", nil)
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

    -- Database Options Button
    local databaseOptionsButton = DF:CreateButton(
            parent,
            function()
                EposUI.DatabaseTabOptions:Show()
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Database Options",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )

    -- Anchor left
    databaseOptionsButton:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    databaseOptionsButton.tooltip = "Displays options panel for database"

    -- Header (Column Titles)
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 30)
    header:SetSize(C.window_width - 40, C.tabs.lineHeight)
    DF:ApplyStandardBackdrop(header)

    -- Column: Name
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Rank
    header.rankLabel = DF:CreateLabel(header, "Rank")
    header.rankLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.rankLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Status
    header.statusLabel = DF:CreateLabel(header, "Status")
    header.statusLabel:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.statusLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Updated
    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 425, 0)
    header.updatedLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    local function PrepareData()
        local data = {}

        for _, player in pairs(EposRT.GuildRoster.Players) do
            if EposRT.GuildRoster.Tracked[player.rank] and not EposRT.GuildRoster.Blacklist[player.name] then
                table_insert(data, {
                    name = player.name,
                    rank = player.rank,
                    class = player.class,
                    updated = "-",
                })
            end
        end

        -- Sort by rank ascending
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


                -- Rank
                line.rank:SetText(player.rank)

                -- Status
                line.trackingStatus:SetText("not in Database")
                line.trackingStatus:SetTextColor(1, 0, 0)

                -- Updated
                line.updated:SetText(player.updated)

                -- Status for existing db entry
                if EposRT.GuildRoster.Database[player.name] then
                    line.trackingStatus:SetText("in Database")
                    line.trackingStatus:SetTextColor(0, 1, 0)
                    line.updated:SetText(date("%Y-%m-%d %H:%M:%S", EposRT.GuildRoster.Database[player.name].timestamp))

                end
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

        -- Rank
        line.rank = DF:CreateLabel(line, "")
        line.rank:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Tracking Status
        line.trackingStatus = DF:CreateLabel(line, "")
        line.trackingStatus:SetPoint("LEFT", line, "LEFT", 300, 0)

        -- Updated timestamp
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 425, 0)

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
            "database_data_scroll_box",
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

    return scrollBox
end
