-- ui/addons/AddOnsUI.lua

local _, Epos = ...

-- Cached Globals
local DF                = _G.DetailsFramework              -- DetailsFramework library
local CreateFrame       = _G.CreateFrame                   -- Frame creation function
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS             -- Class color lookup
local date              = _G.date                          -- Lua date function
local table_insert      = table.insert                     -- Table insert function
local table_sort        = table.sort                       -- Table sort function
local C                 = Epos.Constants                   -- Constants table (templates, sizes, colors)
local C_AddOns          = _G.C_AddOns                       -- AddOns namespace

-- BuildAddOnsTab()
-- @param parent Frame  The parent frame (tab content) to which the AddOns UI is added.
-- @return Frame  The created scrollbox instance, with a `MasterRefresh()` method and dropdown reference.
function BuildAddOnsTab(parent)
    -- “Request Data” Button (far right)
    local requestDataButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.addons_options then
                    EposUI.addons_options:Show()
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
    requestDataButton.tooltip = "Request data for currently tracked AddOns"

    -- “AddOns Options” Button (far left)
    local aoOptionsButton = DF:CreateButton(
            parent,
            function()
                if EposUI and EposUI.addons_options then
                    EposUI.addons_options:Show()
                end
            end,
            C.tabs.buttonWidth,
            C.tabs.buttonHeight,
            "AddOns Options",
            nil, nil, nil, nil, nil, nil,
            C.templates.button
    )
    aoOptionsButton:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            C.tabs.leftPadding,
            C.tabs.startY
    )
    aoOptionsButton:SetAlpha(1)
    aoOptionsButton.tooltip = "Open AddOns Options panel"

    -- AddOn Selection Dropdown
    local addonDropdown
    --- Collects dropdown entries for each tracked AddOn folder in fetch list.
    -- @return table Array of { label, value, onclick } entries for DF:CreateDropDown
    local function GetAddOnDropdownOptions()
        local t = {}
        for _, folderName in ipairs(EposRT.AddOnsOptions.fetch) do
            -- Try to fetch the “Title” field from the TOC; if missing, use the folder name
            local title = C_AddOns.GetAddOnMetadata(folderName, "Title") or folderName

            table_insert(t, {
                label = title,            -- show human‐friendly title in the dropdown
                value = folderName,       -- still use folderName as the stored value
                onclick = function(_, _, value)
                    EposRT.AddOnsOptions.show = value
                    if EposUI and EposUI.addons_tab then
                        EposUI.addons_tab:MasterRefresh()
                    end
                end,
            })
        end
        return t
    end

    addonDropdown = DF:CreateDropDown(
            parent,
            GetAddOnDropdownOptions,
            EposRT.AddOnsOptions.show,
            200,
            30
    )
    addonDropdown:SetTemplate("OPTIONS_DROPDOWN_TEMPLATE")
    addonDropdown:SetPoint("LEFT", aoOptionsButton, "RIGHT", 15, 0)

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

    -- Column: Player Name
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

    --- Local Helper: PrepareData
    --- Gathers and returns each tracked player’s AddOn data for the selected folder.
    -- Filters out players not tracked or blacklisted, then collects AddOn status fields.
    -- @return table  Array of { name, class, installed, version, loaded, ts } entries.
    local function PrepareData()
        local data = {}
        local trackedRoles = (EposRT.Settings and EposRT.Settings.TrackedRoles) or {}

        for _, player in ipairs(EposRT.GuildRoster or {}) do
            local dbEntry = (EposRT.PlayerDatabase or {})[player.name]
            if dbEntry and next(EposRT.AddOnsOptions.fetch) then
                local addonName = EposRT.AddOnsOptions.show
                local adData = (dbEntry.addons or {})[addonName]
                local timestamp = dbEntry.timestamp and date("%Y-%m-%d %H:%M", dbEntry.timestamp) or "-"

                if trackedRoles[player.rank] and not ((EposRT.Blacklist or {})[player.name]) then
                    table_insert(data, {
                        name      = player.name,
                        class     = player.class,
                        installed = adData and "True" or "False",
                        version   = adData and (adData.version or "-") or "-",
                        loaded    = adData and (adData.isLoaded and "True" or "False") or "False",
                        ts        = timestamp,
                    })
                end
            end
        end

        -- Sort by name (or any other desired ordering)
        table_sort(data, function(a, b)
            return a.name < b.name
        end)

        return data
    end

    --- Local Helper: refresh
    --- Populates each visible line in the scrollbox with AddOn data for a player.
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
                line.installed:SetText(entry.installed)
                if entry.installed == "True" then
                    line.installed:SetTextColor(0, 1, 0)
                else
                    line.installed:SetTextColor(1, 0, 0)
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
    --- Creates a single row frame for the scrollbox, containing AddOn status labels.
    -- @param self  Frame  The parent scrollbox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with attached labels:
    --   - name       (FontString): Player name
    --   - installed  (FontString): Installed status
    --   - version    (FontString): AddOn version
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
        line.installed = DF:CreateLabel(line, "")
        line.installed:SetPoint("LEFT", line, "LEFT", 185, 0)

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
    --- Clears existing scrollbox data and repopulates it with fresh AddOn data.
    -- @param self  ScrollBox  The scrollbox instance.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    -- ScrollBox Setup
    local ao_scrollbox = DF:CreateScrollBox(
            parent,
            "EposAddOnsScrollBox",
            refresh,
            {},
            C.window_width - 40,
            C.tabs.totalHeight,
            C.tabs.visibleRows,
            C.tabs.lineHeight,
            createLineFunc
    )
    parent.scrollbox = ao_scrollbox
    ao_scrollbox.MasterRefresh = MasterRefresh
    ao_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(ao_scrollbox)
    ao_scrollbox:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            10,
            C.tabs.startY - 55
    )

    -- Pre-create exactly visibleRows line frames for performance
    for i = 1, C.tabs.visibleRows do
        ao_scrollbox:CreateLine(createLineFunc)
    end

    -- Refresh when the tab is shown
    ao_scrollbox:SetScript("OnShow", function(self)
        if self.MasterRefresh then
            self:MasterRefresh()
        end
    end)

    -- Store dropdown reference for external access if needed
    ao_scrollbox.__addonDropdown = addonDropdown

    return ao_scrollbox
end
