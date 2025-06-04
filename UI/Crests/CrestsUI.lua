-- ui/Crests/CrestsUI
local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildCrestsTab(parent)
    --- Shortcut to our constants table
    local C = Epos.Constants

    --- Buttons

    -- "Request Data" Button (far right)
    local requestDataButton = DF:CreateButton(
        parent,
        function() EposUI.crests_options:Show() end,  -- click handler shows options
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "Request Data",                              -- button text
        nil, nil, nil, nil, nil, nil,                -- unused padding/anchor arguments
        C.templates.button
    )
    requestDataButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", C.tabs.rightPadding, C.tabs.startY)
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from current selected players"

    -- "Crests Options" Button (far left)
    local crestsOptions = DF:CreateButton(
        parent,
        function() EposUI.crests_options:Show() end,  -- click handler shows options
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "Crests Options",                            -- button text
        nil, nil, nil, nil, nil, nil,                -- unused padding/anchor arguments
        C.templates.button
    )
    crestsOptions:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    crestsOptions:SetAlpha(1)
    crestsOptions.tooltip = "Manually add players to the tracking blacklist"

    local crestMenuDropdown
    local function crestMenuDropdownOptions()
        local t = {}
        for i, crestID in ipairs(EposRT.CrestsOptions["fetch"]) do
            local info = C_CurrencyInfo.GetCurrencyInfo(crestID)
            local name = info and info.name or ("Unknown (" .. crestID .. ")")

            tinsert(t, {
                label = name,
                value = crestID,
                onclick = function(_, _, value)
                    EposRT.CrestsOptions["show"] = value
                    if (EposUI.crests_tab) then
                        EposUI.crests_tab:MasterRefresh()
                    end
                end
            })
        end
        return t
    end

    crestMenuDropdown =
        DF:CreateDropDown(
            parent,
            crestMenuDropdownOptions,
            EposRT.CrestsOptions["show"],
            200,
            30
        )

    crestMenuDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    crestMenuDropdown:SetPoint("LEFT", crestsOptions, "RIGHT", 15, 0)

    --- Header Frame for column titles
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
    header.updated = DF:CreateLabel(header, "Updated")
    header.updated:SetPoint("LEFT", header, "LEFT", 650, 0)
    header.updated:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    --- Refresh function to populate each line with data
    -- @param self       The scrollbox object that holds all line frames
    -- @param data       Table containing crest entries
    -- @param offset     Starting index offset into the data table
    -- @param totalLines Number of line frames to update
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index     = i + offset
            local dataEntry = data[index]

            if dataEntry then
                local line = self:GetLine(i)

                -- Determine class color for the name
                local classColor = RAID_CLASS_COLORS[dataEntry.class]

                -- Name column (colored by class)
                line.name:SetText(dataEntry.name)
                line.name:SetTextColor(classColor.r, classColor.g, classColor.b)

                -- Available column (number of crests currently available)
                line.crestsAvailable:SetText(dataEntry.crestsAvailable)

                -- Obtainable column (crests remaining this week or "Infinite")
                line.crestsObtainable:SetText(dataEntry.crestsObtainable)

                -- Used column (total crests spent)
                line.crestsUsed:SetText(dataEntry.crestsUsed)

                -- Total Earned column (total crests earned to date)
                line.crestsTotalEarned:SetText(dataEntry.crestsTotalEarned)

                -- Updated column (last updated timestamp)
                line.timetamp:SetText(dataEntry.timestamp)
            end
        end
    end

    --- Prepares and returns filtered, formatted player crest data.
    -- Gathers information from the guild roster and player database,
    -- filters based on tracked roles and blacklist, and calculates
    -- crest-related values for each valid player.
    --
    -- @return table A sorted list of player data tables, each containing:
    --   - name              (string): Player's name
    --   - crestsAvailable   (number): Current crest quantity
    --   - crestsObtainable  (number|string): Remaining crests obtainable this week or "Infinite"
    --   - crestsUsed        (number): Total crests spent
    --   - crestsTotalEarned (number): Total crests earned to date
    --   - rank              (number): Player's rank in the guild
    --   - class             (string): Player's class
    --   - timestamp         (string): Last updated timestamp (YYYY-MM-DD or "-")
    local function PrepareData()
        local data         = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster) do
            local db = EposRT.PlayerDatabase[player.name]  -- database entry for this player
            if db then
                local currency            = db.currency[EposRT.CrestsOptions["show"]]

                if currency then
                    local crestsAvailable     = currency.quantity
                    local crestsObtainable    = currency.canEarnPerWeek and
                                                (currency.maxQuantity - currency.totalEarned) or
                                                "Infinite"
                    local crestsUsed          = currency.totalEarned - currency.quantity
                    local crestsTotalEarned   = currency.totalEarned
                    local timestamp           = db.timestamp and
                                                date("%Y-%m-%d", db.timestamp) or
                                                "-"

                    -- Only include player if their rank is tracked and not blacklisted
                    if trackedRoles[player.rank] and not EposRT.Blacklist[player.name] then
                        table.insert(data, {
                            name                = player.name,
                            crestsAvailable     = crestsAvailable,
                            crestsObtainable    = crestsObtainable,
                            crestsUsed          = crestsUsed,
                            crestsTotalEarned   = crestsTotalEarned,
                            rank                = player.rank,
                            class               = player.class,
                            timestamp           = timestamp,
                        })
                    end
                end
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
    -- Each line is a frame with labels for player name and crest-related stats,
    -- positioned based on its index within the scrollable frame.
    --
    -- @param self  Frame  The parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with attached label elements:
    --   - name              (FontString): Player name
    --   - crestsAvailable   (FontString): Current crest quantity
    --   - crestsObtainable  (FontString): Remaining crests this week
    --   - crestsUsed        (FontString): Crests spent
    --   - crestsTotalEarned (FontString): Total crests earned
    --   - timetamp          (FontString): Last updated timestamp
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
            "TOPLEFT",
            self,
            "TOPLEFT",
            1,
            -((index - 1) * (C.tabs.lineHeight)) - 1
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

        -- Updated timestamp label (note: variable name typo replicates original)
        line.timetamp = DF:CreateLabel(line, "")
        line.timetamp:SetPoint("LEFT", line, "LEFT", 650, 0)

        return line
    end

    --- ScrollBox Setup
    local crests_scrollbox = DF:CreateScrollBox(
        parent,
        "VersionCheckScrollBox",            -- unique scrollbox name
        refresh,                            -- refresh function
        {},                                 -- initial empty data
        C.window_width - 40,                -- scrollbox width
        C.tabs.totalHeight,                 -- scrollbox height
        C.tabs.visibleRows,                 -- number of visible rows
        C.tabs.lineHeight,                  -- height of each row
        createLineFunc                      -- line creation function
    )

    parent.scrollbox               = crests_scrollbox
    crests_scrollbox.MasterRefresh = MasterRefresh
    crests_scrollbox.ReajustNumFrames = true
    crests_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 55)
    DF:ReskinSlider(crests_scrollbox)

    -- Create exactly as many line frames as will fit on screen
    for i = 1, C.tabs.visibleRows do
        crests_scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow handler: refresh data whenever tab is shown
    crests_scrollbox:SetScript("OnShow", function(self)
        EposUI.crests_tab:MasterRefresh()
    end)

    crests_scrollbox.__crestDropdown = crestMenuDropdown
    return crests_scrollbox
end
    