-- ui/WeakAuras/WeakAurasUI
local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildWeakAurasTab(parent)
    --- Shortcut to our constants table
    local C = Epos.Constants

    --- Buttons

    -- "Request Data" Button (far right)
    local requestDataButton = DF:CreateButton(
        parent,
        function() EposUI.weakauras_options:Show() end,  -- click handler shows options
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "Request Data",                              -- button text
        nil, nil, nil, nil, nil, nil,                -- unused padding/anchor arguments
        C.templates.button
    )
    requestDataButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", C.tabs.rightPadding, C.tabs.startY)
    requestDataButton:SetAlpha(1)
    requestDataButton.tooltip = "Request data from currently selected players"

    -- "WeakAuras Options" Button (far left)
    local weakaurasOption = DF:CreateButton(
        parent,
        function() EposUI.weakauras_options:Show() end,  -- click handler shows options
        C.tabs.buttonWidth,
        C.tabs.buttonHeight,
        "WeakAuras Options",                            -- button text
        nil, nil, nil, nil, nil, nil,                   -- unused padding/anchor arguments
        C.templates.button
    )
    weakaurasOption:SetPoint("TOPLEFT", parent, "TOPLEFT", C.tabs.leftPadding, C.tabs.startY)
    weakaurasOption:SetAlpha(1)
    weakaurasOption.tooltip = "Manually add players to the WA tracking blacklist"

    --- Dropdown to select which WA set to show
    local waMenuDropdown
    local function waMenuDropdownOptions()
        local t = {}
        for i, waSetID in ipairs(EposRT.WeakAurasOptions["fetch"]) do


            tinsert(t, {
                label = waSetID,
                value = waSetID,
                onclick = function(_, _, value)
                    EposRT.WeakAurasOptions["show"] = value
                    if (EposUI.weakauras_tab) then
                        EposUI.weakauras_tab:MasterRefresh()
                    end
                end
            })
        end
        return t
    end

    waMenuDropdown =
        DF:CreateDropDown(
            parent,
            waMenuDropdownOptions,
            EposRT.WeakAurasOptions["show"],
            200,
            30
        )
    waMenuDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    waMenuDropdown:SetPoint("LEFT", weakaurasOption, "RIGHT", 15, 0)

    --- Header Frame for column titles
    local header = CreateFrame("Frame", "$parentHeader", parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 30)
    header:SetSize(C.window_width - 40, C.tabs.lineHeight)
    DF:ApplyStandardBackdrop(header)

    -- Column: Name
    header.nameLabel = DF:CreateLabel(header, "Name")
    header.nameLabel:SetPoint("LEFT", header, "LEFT", 5, 0)
    header.nameLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: WeakAuras
    header.weakaurasLabel = DF:CreateLabel(header, "Installed")
    header.weakaurasLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.weakaurasLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: WeakAuras
    header.version = DF:CreateLabel(header, "Version")
    header.version:SetPoint("LEFT", header, "LEFT", 300, 0)
    header.version:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: WeakAuras
    header.loaded = DF:CreateLabel(header, "Loaded")
    header.loaded:SetPoint("LEFT", header, "LEFT", 400, 0)
    header.loaded:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    -- Column: WeakAuras
    header.updated = DF:CreateLabel(header, "Updated")
    header.updated:SetPoint("LEFT", header, "LEFT", 500, 0)
    header.updated:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

    --- Refresh function to populate each line with data
    -- @param self       The scrollbox object that holds all line frames
    -- @param data       Table containing player entries
    -- @param offset     Starting index offset into the data table
    -- @param totalLines Number of line frames to update
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index     = i + offset
            local dataEntry = data[index]

            if dataEntry then
                local line = self:GetLine(i)

                -- 1) Color the “name” by class (fallback to white if class missing)
                local classColor = RAID_CLASS_COLORS[dataEntry.class or "PRIEST"] or { r = 1, g = 1, b = 1 }
                line.name:SetText(dataEntry.name)
                line.name:SetTextColor(classColor.r, classColor.g, classColor.b)

                line.version:SetText(dataEntry.version)
                line.weakauras:SetText(dataEntry.installed)
                line.updated:SetText(dataEntry.ts)

                if dataEntry.installed == "True" then
                    line.weakauras:SetTextColor(0, 1, 0)  -- green
                else
                    line.weakauras:SetTextColor(1, 0, 0)  -- red
                end

                line.loaded:SetText(tostring(dataEntry.loaded))

                if dataEntry.loaded == "True" then
                    line.loaded:SetTextColor(0, 1, 0)  -- green
                else
                    line.loaded:SetTextColor(1, 0, 0)  -- red
                end
            end
        end
    end

    --- Prepares and returns filtered, formatted player WA data.
    -- Gathers information from the guild roster and player database,
    -- filters based on tracked roles and blacklist, and collects
    -- WA-related values for each valid player.
    --
    -- @return table A sorted list of player data tables, each containing:
    --   - name      (string): Player's name
    --   - class     (string): Player's class
    --   - weakauras (table):  List of WA tables { name, version }
    local function PrepareData()
        local data = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.GuildRoster) do
            local db = EposRT.PlayerDatabase[player.name]  -- database entry for this player
            if db then
                local weakaura                = db.weakaura[EposRT.WeakAurasOptions["show"]]
                print("123")
                DevTools_Dump(weakaura)
                print("123")
                local timestamp           = db.timestamp and
                date("%Y-%m-%d %H:%M", db.timestamp) or
                "-"

                if next(EposRT.WeakAurasOptions.fetch) then
                    if trackedRoles[player.rank] and not EposRT.Blacklist[player.name] then
                        table.insert(data, {
                            name = player.name,
                            class = player.class,
                            rank = player.rank,
                            id = weakaura and weakaura.id or "-",
                            version = weakaura and weakaura.semver or "-",
                            url = weakaura and weakaura.url or "-",
                            icon = weakaura and  weakaura.displayIcon or "-",
                            ts = timestamp,
                            loaded = weakaura and weakaura.isLoaded and "True" or "False",
                            installed = weakaura and weakaura.id and "True" or "False"
                        })
                    end
                end

            end
        end

        -- Sort players by rank ascending, then by name
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
    -- Each line is a frame with labels for player name and WA-related stats,
    -- positioned based on its index within the scrollable frame.
    --
    -- @param self  Frame  The parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with attached label elements:
    --   - name       (FontString): Player name
    --   - weakauras  (FontString): Multiline WA list
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

        -- WeakAuras label
        line.weakauras = DF:CreateLabel(line, "")
        line.weakauras:SetPoint("LEFT", line, "LEFT", 185, 0)
        line.weakauras:SetJustifyV("TOP")  -- align multiline text to top

        -- WeakAuras label
        line.version = DF:CreateLabel(line, "")
        line.version:SetPoint("LEFT", line, "LEFT", 300, 0)
        line.version:SetJustifyV("TOP")  -- align multiline text to top

        -- WeakAuras label
        line.loaded = DF:CreateLabel(line, "")
        line.loaded:SetPoint("LEFT", line, "LEFT", 400, 0)
        line.loaded:SetJustifyV("TOP")  -- align multiline text to top

        -- WeakAuras label
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 500, 0)
        line.updated:SetJustifyV("TOP")  -- align multiline text to top

        return line
    end

    --- ScrollBox Setup
    local weakauras_scrollbox = DF:CreateScrollBox(
        parent,
        "VersionCheckScrollBox",               -- unique scrollbox name
        refresh,                            -- refresh function
        {},                                 -- initial empty data
        C.window_width - 40,                -- scrollbox width
        C.tabs.totalHeight,                 -- scrollbox height
        C.tabs.visibleRows,                 -- number of visible rows
        C.tabs.lineHeight,             -- height of each row (extra for multiline)
        createLineFunc                      -- line creation function
    )

    parent.scrollbox               = weakauras_scrollbox
    weakauras_scrollbox.MasterRefresh = MasterRefresh
    weakauras_scrollbox.ReajustNumFrames = true
    weakauras_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, C.tabs.startY - 55)
    DF:ReskinSlider(weakauras_scrollbox)

    -- Create exactly as many line frames as will fit on screen
    for i = 1, C.tabs.visibleRows do
        weakauras_scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow handler: refresh data whenever tab is shown
    weakauras_scrollbox:SetScript("OnShow", function(self)
        EposUI.weakauras_tab:MasterRefresh()
    end)

    weakauras_scrollbox.__waDropdown = waMenuDropdown
    return weakauras_scrollbox
end
