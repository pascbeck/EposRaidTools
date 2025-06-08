-- ui/weakauras/WeakAurasUI.lua

local _, Epos = ...

-- Cached Globals
local DF                = _G.DetailsFramework              -- DetailsFramework library
local CreateFrame       = _G.CreateFrame                   -- Frame creation function
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS             -- Class color lookup
local date              = _G.date                          -- Lua date function
local table_insert      = table.insert                     -- Table insert function
local table_sort        = table.sort                       -- Table sort function
local C                 = Epos.Constants                   -- Constants table (templates, sizes, colors)

-- BuildWeakAurasTab()
-- @param parent Frame  The parent frame (tab content) to which the WA UI is added.
-- @return Frame  The created scrollbox instance, with a `MasterRefresh()` method and dropdown reference.
function BuildWeakAurasTab(parent)
    -- “Request Data” Button (far right)
    local requestDataButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.weakauras_options then
                    EposUI.weakauras_options:Show()
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

    -- “WeakAuras Options” Button (far left)
    local waOptionsButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.weakauras_options then
                    EposUI.weakauras_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "WeakAuras Options",
            nil, nil, nil, nil, nil, nil,
            C.templates.button
    )
    waOptionsButton:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY
    )
    waOptionsButton:SetAlpha(1)
    waOptionsButton.tooltip = "Open WeakAuras Options panel"

    -- WA Set Selection Dropdown
    local waMenuDropdown
    --- Collects dropdown entries for each WA set ID in fetch list.
    -- @return table Array of { label, value, onclick } entries for DF:CreateDropDown
    local function GetWADropdownOptions()
        local t = {}
        for _, waSetID in ipairs(EposRT.WeakAurasOptions.fetch) do
            table_insert(t, {
                label = waSetID,
                value = waSetID,
                onclick = function(_, _, value)
                    EposRT.WeakAurasOptions.show = value
                    if EposUI and EposUI.weakauras_tab then
                        EposUI.weakauras_tab:MasterRefresh()
                    end
                end,
            })
        end
        return t
    end

    waMenuDropdown = DF:CreateDropDown(
            parent,
            GetWADropdownOptions,
            EposRT.WeakAurasOptions.show,
            200,
            30
    )
    waMenuDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    waMenuDropdown:SetPoint("LEFT", waOptionsButton, "RIGHT", 15, 0)

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

    -- Column: Installed
    header.weakaurasLabel = DF:CreateLabel(header, "Installed")
    header.weakaurasLabel:SetPoint("LEFT", header, "LEFT", 185, 0)
    header.weakaurasLabel:SetTextColor(C.colors.headerColorR, C.colors.headerColorG, C.colors.headerColorB)

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

    --- Local Helper: PrepareData
    --- Gathers and returns each tracked player’s WA data for the selected set ID.
    -- Filters out players not tracked or blacklisted, then collects WA status fields.
    -- @return table  Array of { name, class, installed, version, loaded, ts, rank } entries.
    local function PrepareData()
        local data = {}
        local trackedRoles = (EposRT.Settings and EposRT.Settings.TrackedRoles) or {}

        for _, player in pairs(EposRT.GuildRoster or {}) do
            local dbEntry = (EposRT.PlayerDatabase or {})[player.name]
            if dbEntry and next(EposRT.WeakAurasOptions.fetch) then
                local waData = (dbEntry.weakaura or {})[EposRT.WeakAurasOptions.show]
                local timestamp = dbEntry.timestamp and date("%Y-%m-%d %H:%M", dbEntry.timestamp) or "-"

                if trackedRoles[player.rank] and not ((EposRT.Blacklist or {})[player.name]) then
                    table_insert(data, {
                        name      = player.name,
                        class     = player.class,
                        rank      = player.rank,
                        installed = waData and "True" or "False",
                        version   = waData and (waData.semver or "-") or "-",
                        loaded    = waData and (waData.isLoaded and "True" or "False") or "False",
                        ts        = timestamp,
                    })
                end
            end
        end

        -- Sort by rank ascending, then by name
        table_sort(data, function(a, b)
            if a.rank ~= b.rank then
                return a.rank < b.rank
            end
            return a.name < b.name
        end)

        return data
    end

    --- Local Helper: refresh
    --- Populates each visible line in the scrollbox with WA data for a player.
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

                -- Name (class-colored, fallback to white)
                local color = RAID_CLASS_COLORS[entry.class] or { r = 1, g = 1, b = 1 }
                line.name:SetText(entry.name)
                line.name:SetTextColor(color.r, color.g, color.b)

                -- Installed (green if “True”, red if “False”)
                line.weakauras:SetText(entry.installed)
                if entry.installed == "True" then
                    line.weakauras:SetTextColor(0, 1, 0)
                else
                    line.weakauras:SetTextColor(1, 0, 0)
                end

                -- Version
                line.version:SetText(entry.version)

                -- Loaded (green if “True”, red if “False”)
                line.loaded:SetText(entry.loaded)
                if entry.loaded == "True" then
                    line.loaded:SetTextColor(0, 1, 0)
                else
                    line.loaded:SetTextColor(1, 0, 0)
                end

                -- Updated timestamp
                line.updated:SetText(entry.ts)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the scrollbox, containing WA status labels.
    -- @param self  Frame  The parent scrollbox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with attached labels:
    --   - name       (FontString): Player name
    --   - weakauras  (FontString): Installed status
    --   - version    (FontString): WA version
    --   - loaded     (FontString): Loaded status
    --   - updated    (FontString): Last updated timestamp
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

        -- Installed label
        line.weakauras = DF:CreateLabel(line, "")
        line.weakauras:SetPoint("LEFT", line, "LEFT", 185, 0)

        -- Version label
        line.version = DF:CreateLabel(line, "")
        line.version:SetPoint("LEFT", line, "LEFT", 300, 0)

        -- Loaded label
        line.loaded = DF:CreateLabel(line, "")
        line.loaded:SetPoint("LEFT", line, "LEFT", 400, 0)

        -- Updated timestamp label
        line.updated = DF:CreateLabel(line, "")
        line.updated:SetPoint("LEFT", line, "LEFT", 500, 0)

        return line
    end

    --- Local Helper: MasterRefresh
    --- Clears existing scrollbox data and repopulates it with fresh WA data.
    -- @param self  ScrollBox  The scrollbox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    -- ScrollBox Setup
    local wa_scrollbox = DF:CreateScrollBox(
            parent,
            "EposWeakAurasScrollBox",
            refresh,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            createLineFunc
    )
    parent.scrollbox = wa_scrollbox
    wa_scrollbox.MasterRefresh = MasterRefresh
    wa_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(wa_scrollbox)
    wa_scrollbox:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 55
    )

    -- Pre-create exactly visibleRows line frames for performance
    for i = 1, C.tabs.visibleRows do
        wa_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the tab is shown
    wa_scrollbox:SetScript("OnShow", function(self)
        if self.MasterRefresh then
            self:MasterRefresh()
        end
    end)

    -- Store dropdown reference for external access if needed
    wa_scrollbox.__waDropdown = waMenuDropdown

    return wa_scrollbox
end
