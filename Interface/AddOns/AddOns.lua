-- ui/addons/AddOns.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local CreateFrame = _G.CreateFrame
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local date = _G.date
local table_insert = table.insert
local table_sort = table.sort
local C = Epos.Constants

-- @param parent frame (addons tab)
function BuildAddOnsInterface(parent)
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

    -- AddOns Options Button
    local addonsOptionsButton = DF:CreateButton(
            parent,
            function()
                EposUI.AddOnsTabOptions:Show()
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "AddOns Options",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )

    -- Anchor left
    addonsOptionsButton:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    addonsOptionsButton.tooltip = "Displays options panel for AddOns"

    -- AddOns Dropdown Menu
    local addonsDropdown

    local function GetAddOnDropdownOptions()
        local t = {}
        for _, addon in pairs(EposRT.AddOns.Fetch) do
            local name = C_AddOns.GetAddOnMetadata(addon, "Title") or addon

            table_insert(t, {
                label = name,
                value = addon,
                onclick = function(_, _, value)
                    EposRT.AddOns.Current = value
                    EposUI.AddOnsTab:MasterRefresh()
                end,
            })
        end
        return t
    end

    addonsDropdown = DF:CreateDropDown(parent, GetAddOnDropdownOptions, EposRT.AddOns.Current, 200, 30)
    addonsDropdown:SetTemplate(C.templates.dropdown)

    -- Anchor left next to 'addonsOptionsButton'
    addonsDropdown:SetPoint("LEFT", addonsOptionsButton, "RIGHT", 15, 0)

    -- Header (Column Titles)
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 30)
    header:SetSize(C.window_width - 40, C.tabs.lineHeight)
    DF:ApplyStandardBackdrop(header)

    -- Column: Name
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Installed
    header.installedLabel = DF:CreateLabel(header, "Installed")
    header.installedLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.installedLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Version
    header.versionLabel = DF:CreateLabel(header, "Version")
    header.versionLabel:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.versionLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Loaded
    header.loadedLabel = DF:CreateLabel(header, "Loaded")
    header.loadedLabel:SetPoint("LEFT", header, "LEFT", 400, 0)
    header.loadedLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: Updated
    header.updatedLabel = DF:CreateLabel(header, "Updated")
    header.updatedLabel:SetPoint("LEFT", header, "LEFT", 500, 0)
    header.updatedLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    local function PrepareData()
        local data = {}
        for _, player in pairs(EposRT.GuildRoster.Players) do
            local playerDatabaseEntry = EposRT.GuildRoster.Database[player.name]
            if playerDatabaseEntry and next(EposRT.AddOns.Fetch) then
                local timestamp = playerDatabaseEntry.timestamp and date("%d.%m - %H:%M Uhr", playerDatabaseEntry.timestamp) or "-"
                local addons = playerDatabaseEntry.addons
                local current = EposRT.AddOns and EposRT.AddOns.Current
                local addon = addons[current]

                if EposRT.GuildRoster.Tracked[player.rank] and not EposRT.GuildRoster.Blacklist[player.name] then
                    table_insert(data, {
                        name = player.name,
                        class = player.class,
                        rank = player.rank,
                        installed = addon and addon.installed or false,
                        version = addon and addon.version or "-",
                        loaded = addon and addon.loaded or false,
                        ts = timestamp,
                    })
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

                -- Installed
                if player.installed == true then
                    line.installed:SetText("Installed")
                    line.installed:SetTextColor(0, 1, 0)
                else
                    line.installed:SetText("Not Installed")
                    line.installed:SetTextColor(1, 0, 0)
                end

                -- Version
                line.version:SetText(player.version)

                -- Loaded
                if player.loaded == true then
                    line.loaded:SetText("Loaded")
                    line.loaded:SetTextColor(0, 1, 0)
                else
                    line.loaded:SetText("Not Loaded")
                    line.loaded:SetTextColor(1, 0, 0)
                end

                -- Updated
                line.updated:SetText(player.ts)
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

        -- Installed
        line.installed = DF:CreateLabel(line, "")
        line.installed:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Version
        line.version = DF:CreateLabel(line, "")
        line.version:SetPoint("LEFT", line, "LEFT", 300, 0)
        line.version:SetWidth(90)

        -- Loaded
        line.loaded = DF:CreateLabel(line, "")
        line.loaded:SetPoint("LEFT", line, "LEFT", 400, 0)

        -- Updated
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 500, 0)

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
            "addons_data_scroll_box",
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
    scrollBox.__dropdown = addonsDropdown
    return scrollBox
end