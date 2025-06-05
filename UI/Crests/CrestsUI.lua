-- ui/crests/CrestsUI.lua

local _, Epos = ...

-- Cached Globals
local DF                = _G.DetailsFramework              -- DetailsFramework library
local CreateFrame       = _G.CreateFrame                   -- Frame creation
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS             -- Class color table
local date              = _G.date                          -- Lua date function
local table_insert      = table.insert                     -- Table insert
local table_sort        = table.sort                       -- Table sort
local C                 = Epos.Constants                   -- Constants table (templates, sizes, colors)
local C_CurrencyInfo    = _G.C_CurrencyInfo                -- Blizzard API for currency info

--- BuildCrestsTab()
-- @param parent Frame  The parent frame (tab content) to which the crests UI is added.
-- @return Frame  The created scrollbox object, with a `MasterRefresh()` method and dropdown reference.
function BuildCrestsTab(parent)
    -- “Request Data” Button (far right)
    local requestDataButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.crests_options then
                    EposUI.crests_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Request Data",
            nil, nil, nil, nil, nil, nil,
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
    requestDataButton.tooltip = "Request data for current selected players"

    -- “Crests Options” Button (far left)
    local crestsOptionsButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.crests_options then
                    EposUI.crests_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "Crests Options",
            nil, nil, nil, nil, nil, nil,
            C.templates.button
    )
    crestsOptionsButton:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY
    )
    crestsOptionsButton:SetAlpha(1)
    crestsOptionsButton.tooltip = "Open Crests Options panel"

    -- Crest Selection Dropdown
    local crestMenuDropdown
    --- Returns a list of dropdown entries: { label, value, onclick }
    local function GetCrestDropdownOptions()
        local t = {}
        for _, crestID in ipairs(EposRT.CrestsOptions.fetch) do
            local info = C_CurrencyInfo.GetCurrencyInfo(crestID)
            local name = (info and info.name) or ("Unknown (" .. crestID .. ")")
            table_insert(t, {
                label   = name,
                value   = crestID,
                onclick = function(_, _, value)
                    EposRT.CrestsOptions.show = value
                    if EposUI and EposUI.crests_tab then
                        EposUI.crests_tab:MasterRefresh()
                    end
                end,
            })
        end
        return t
    end

    crestMenuDropdown = DF:CreateDropDown(
            parent,
            GetCrestDropdownOptions,
            EposRT.CrestsOptions.show,
            200,
            30
    )
    crestMenuDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    crestMenuDropdown:SetPoint("LEFT", crestsOptionsButton, "RIGHT", 15, 0)

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

    --- Local Helper: PrepareData
    --- Gathers and returns crest data for each tracked, non‐blacklisted player.
    -- Filters out players not tracked or blacklisted, then computes crest stats.
    -- @return table  Array of player entries { name, crestsAvailable, crestsObtainable, crestsUsed, crestsTotalEarned, rank, class, timestamp }.
    local function PrepareData()
        local data = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster or {}) do
            local dbEntry = EposRT.PlayerDatabase and EposRT.PlayerDatabase[player.name]
            if dbEntry and next(EposRT.CrestsOptions.fetch) then
                local currency = dbEntry.currency and dbEntry.currency[EposRT.CrestsOptions.show]
                if currency then
                    local available   = currency.quantity or 0
                    local obtainable  = currency.canEarnPerWeek and (currency.maxQuantity - currency.totalEarned) or "Infinite"
                    local used        = (currency.totalEarned or 0) - available
                    local totalEarned = currency.totalEarned or 0
                    local tsText      = dbEntry.timestamp and date("%Y-%m-%d", dbEntry.timestamp) or "-"

                    if trackedRoles[player.rank] and not (EposRT.Blacklist or {})[player.name] then
                        table_insert(data, {
                            name              = player.name,
                            crestsAvailable   = available,
                            crestsObtainable  = obtainable,
                            crestsUsed        = used,
                            crestsTotalEarned = totalEarned,
                            rank              = player.rank,
                            class             = player.class,
                            timestamp         = tsText,
                        })
                    end
                end
            end
        end

        -- Sort by rank ascending
        table_sort(data, function(a, b)
            return a.rank < b.rank
        end)

        return data
    end

    --- Local Helper: refresh
    --- Populates each visible line in the scrollbox with crest data.
    -- @param self       ScrollBox  The scrollbox instance.
    -- @param data       table      Array returned by PrepareData().
    -- @param offset     number     Starting index offset into data.
    -- @param totalLines number     Number of line frames to update.
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]
            if entry then
                local line = self:GetLine(i)

                -- Class color (fallback to white)
                local color = RAID_CLASS_COLORS[entry.class] or { r = 1, g = 1, b = 1 }

                -- Name (class-colored)
                line.name:SetText(entry.name)
                line.name:SetTextColor(color.r, color.g, color.b)

                -- Available
                line.crestsAvailable:SetText(entry.crestsAvailable)

                -- Obtainable
                line.crestsObtainable:SetText(entry.crestsObtainable)

                -- Used
                line.crestsUsed:SetText(entry.crestsUsed)

                -- Total Earned
                line.crestsTotalEarned:SetText(entry.crestsTotalEarned)

                -- Updated timestamp
                line.updated:SetText(entry.timestamp)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the scrollbox, containing labels for crest stats.
    -- @param self  Frame  The parent scrollbox frame.
    -- @param index number  Line index (1‐based), used for vertical positioning.
    -- @return Frame A configured line frame with attached labels:
    --   - name              (FontString): Player name
    --   - crestsAvailable   (FontString): Current crest quantity
    --   - crestsObtainable  (FontString): Remaining crests this week
    --   - crestsUsed        (FontString): Crests spent
    --   - crestsTotalEarned (FontString): Total crests earned
    --   - updated           (FontString): Last updated date
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
                "TOPLEFT",
                self,
                "TOPLEFT",
                1,
                -((index - 1) * C.tabs.lineHeight) - 1
        )
        line:SetSize(self:GetWidth() - 2, C.tabs.lineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Name label
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Available label
        line.crestsAvailable = DF:CreateLabel(line, "")
        line.crestsAvailable:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Obtainable label
        line.crestsObtainable = DF:CreateLabel(line, "")
        line.crestsObtainable:SetPoint("LEFT", line, "LEFT", 300, 0)

        -- Used label
        line.crestsUsed = DF:CreateLabel(line, "")
        line.crestsUsed:SetPoint("LEFT", line, "LEFT", 425, 0)

        -- Total Earned label
        line.crestsTotalEarned = DF:CreateLabel(line, "")
        line.crestsTotalEarned:SetPoint("LEFT", line, "LEFT", 525, 0)

        -- Updated timestamp label
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 650, 0)

        return line
    end

    --- Local Helper: MasterRefresh
    --- Clears existing scrollbox data and repopulates it with fresh crest data.
    -- @param self  ScrollBox  The scrollbox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    -- ScrollBox Setup
    local crestsScrollBox = DF:CreateScrollBox(
            parent,
            "EposCrestsScrollBox",
            refresh,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            createLineFunc
    )
    parent.scrollbox = crestsScrollBox
    crestsScrollBox.MasterRefresh = MasterRefresh
    crestsScrollBox.ReajustNumFrames = true
    DF:ReskinSlider(crestsScrollBox)
    crestsScrollBox:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 55
    )

    -- Pre-create exactly visibleRows line frames for performance
    for i = 1, C.tabs.visibleRows do
        crestsScrollBox:CreateLine(createLineFunc)
    end

    -- Refresh when the tab is shown
    crestsScrollBox:SetScript("OnShow", function(self)
        if self.MasterRefresh then
            self:MasterRefresh()
        end
    end)

    -- Store dropdown reference for external access if needed
    crestsScrollBox.__crestDropdown = crestMenuDropdown

    return crestsScrollBox
end