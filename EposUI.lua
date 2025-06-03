local _, Epos = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
local WA = _G["WeakAuras"]

local window_width = 800
local window_height = 600
local expressway = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]]

local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local ui_panel_options = {
    UseStatusBar = true
}
local EposUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFF00FFFFEpos|r Raid Tools", "EposUI",
    ui_panel_options)
EposUI:SetPoint("CENTER")
EposUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(EposUI.StatusBar, _, "x |cFF00FFFFbird|r")
EposUI.StatusBar.discordTextEntry:SetText("badbluu")

local function onEditRoles()
	local edit_roles_frame = DF:CreateSimplePanel(UIParent, 485, 420, "Roles Management", "RolesEditFrame", {
        DontRightClickClose = true
    })

	edit_roles_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	local ranks = {
		"Guildlead",
		"Officer",
		"Officer Alt",
		"Raider",
		"Raid Alt",
		"Trial",
	}

	local options = {
		{
			type = "label",
			get = function() return "Track guild ranks" end,
			text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
		},
	}

	for _, rank in ipairs(ranks) do
		table.insert(options, {
			type = "toggle",
			boxfirst = true,
			name = rank,
			desc = "Enable or disable tracking for " .. rank,
		get = function()
			return EposRT.Settings["TrackedRoles"][rank]
		end,
		set = function(_, _, value)
			EposRT.Settings["TrackedRoles"][rank] = value
			EposUI.roster_tab:MasterRefresh()

		end,
			nocombat = true
		})
	end

	table.insert(options, {
		type = "break"
	})

	table.insert(options, {
		type = "label",
		get = function() return "Automatic background update" end,
		text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
	})

	-- REPLACE WITH Epos
	local EposSaved = EposSaved or {}
	EposSaved.enableIntervalFetching = EposSaved.enableIntervalFetching or false
	EposSaved.fetchInterval = EposSaved.fetchInterval or 10

	-- Enable Interval Fetching checkbox
	table.insert(options, {
		type = "toggle",
		boxfirst = true,
		name = "Enable Interval Fetching",
		desc = "Enable periodic roster updates",
		get = function()
			return EposSaved.enableIntervalFetching
		end,
		set = function(self, fixedparam, value)
			EposSaved.enableIntervalFetching = value
		end,
		nocombat = true
	})

	-- Interval Slider (only enabled when checkbox is on)
	table.insert(options, {
		type = "slider",
		name = "Interval (Seconds)",
		desc = "How often to fetch updated roster info",
		min = 1,
		max = 60,
		step = 1,
		get = function()
			return EposSaved.fetchInterval
		end,
		set = function(self, fixedparam, value)
			EposSaved.fetchInterval = value
		end,
		disabled = function()
			return not EposSaved.enableIntervalFetching
		end,
		nocombat = true
	})

	DF:BuildMenu(
		edit_roles_frame,
		options,
		10, -30, -- x, y offset
		380, false,
		options_text_template,
		options_dropdown_template,
		options_switch_template,
		true,
		options_slider_template,
		options_button_template,
		nil
	)

	edit_roles_frame:Hide()
	return edit_roles_frame
end

local function BuildRosterTab(parent)
	local buttonWidth = 120
	local buttonHeight = 20
	local spacingX = 10
	local topPadding = -20
	local leftPadding = 10
	local rightPadding = -30
	local startY = -100

	-- Edit Roles Button (left-aligned)
	local editRolesButton = DF:CreateButton(
		parent,
		function() EposUI.edit_roles_frame:Show() end,
		buttonWidth,
		buttonHeight,
		"Edit Roles",
		nil, nil, nil, nil, nil, nil,
		options_button_template
	)
	editRolesButton:SetPoint("TOPLEFT", parent, "TOPLEFT", leftPadding, startY)
	editRolesButton:SetAlpha(1)
	editRolesButton.tooltip = "Configure role filters for automatic tracking"

	-- Edit Blacklist (rightmost)
	local blacklistButton = DF:CreateButton(
		parent,
		OnClick_EditBlacklist,
		buttonWidth,
		buttonHeight,
		"Edit Blacklist",
		nil, nil, nil, nil, nil, nil,
		options_button_template
	)
	blacklistButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", rightPadding, startY)
	blacklistButton:SetAlpha(1)
	blacklistButton.tooltip = "Manually add players to the tracking blacklist"

	-- Edit Whitelist (to the left of Blacklist)
	local whitelistButton = DF:CreateButton(
		parent,
		OnClick_EditWhitelist,
		buttonWidth,
		buttonHeight,
		"Edit Whitelist",
		nil, nil, nil, nil, nil, nil,
		options_button_template
	)
	whitelistButton:SetPoint("RIGHT", blacklistButton, "LEFT", -spacingX, 0)
	whitelistButton:SetAlpha(1)
	whitelistButton.tooltip = "Manually add players to the tracking whitelist"

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
            end
        end
    end


	local function PrepareData()
        local data = {}
        local trackedRoles = EposRT.Settings and EposRT.Settings.TrackedRoles or {}

        for _, player in ipairs(EposRT.Members) do
            if trackedRoles[player.rank] then
                table.insert(data, {
                    name  = player.name,
                    rank  = player.rank,
                    class = player.class,   -- make sure .class is the class token, e.g. "MAGE"
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
        local parent = self
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index-1) * (self.LineHeight)) - 1)
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        line.name = DF:CreateLabel(line, "")  -- default white text
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        line.rank = DF:CreateLabel(line, "")
        line.rank:SetPoint("LEFT", line, "LEFT", 185, 0)

        return line
    end


    -- figure out exactly how many rows fit in (window_height - 165)
    local lineHeight  = 20
    local totalHeight = window_height - 165
    local visibleRows = math.floor(totalHeight / lineHeight)

    local roster_scrollbox =
        DF:CreateScrollBox(
            parent,
            "VersionCheckScrollBox",
            refresh,
            {},
            window_width - 40,
            totalHeight,
            visibleRows,
            lineHeight,
            createLineFunc
        )
    parent.scrollbox        = roster_scrollbox
    roster_scrollbox.MasterRefresh = MasterRefresh

    DF:ReskinSlider(roster_scrollbox)
    roster_scrollbox.ReajustNumFrames = true
    roster_scrollbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -130)

	-- create exactly as many line frames as will fit on screen
    for i = 1, visibleRows do
        roster_scrollbox:CreateLine(createLineFunc)
    end

    roster_scrollbox:SetScript("OnShow", function(self)
		EposUI.roster_tab:MasterRefresh()
    end)

	return roster_scrollbox
end

function EposUI:Init()
    DF:CreateScaleBar(EposUI, EposRT.EposUI)
    EposUI:SetScale(EposRT.EposUI.scale)

    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(EposUI, "Epos", "EposUI_Tab", {
        {
			name 		= "Roster",
			text 		= "Roster"
		},
        {
			name 		= "Crests",
			text 		= "Crests"
		},
        {
			name 		= "WeakAuras",
			text 		= "WeakAuras"
		},
        {
			name 		= "AddOns",
			text 		= "AddOns"
		},
        {
			name 		= "Settings",
			text 		= "Settings"
		},
        {
			name 		= "Setup",
			text 		= "Setup"
		},
    }, {
        width = window_width,
        height = window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
    })

	tabContainer:SetPoint("CENTER", EposUI, "CENTER", 0, 0)

	local roster_tab 			= tabContainer:GetTabFrameByName("Roster")
    local crests_tab 			= tabContainer:GetTabFrameByName("Crests")
    local weakauras_tab 		= tabContainer:GetTabFrameByName("WeakAuras")
    local addons_tab 			= tabContainer:GetTabFrameByName("AddOns")
    local settings_tab 			= tabContainer:GetTabFrameByName("Settings")
    local setup_tab 			= tabContainer:GetTabFrameByName("Setup")

	-- crests
    DF:BuildMenu(crests_tab, {}, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
	-- weakauras
    DF:BuildMenu(weakauras_tab, {}, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
	-- addons
    DF:BuildMenu(addons_tab, {}, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
	-- settings
	DF:BuildMenu(settings_tab, {}, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
	-- setup
	DF:BuildMenu(setup_tab, {}, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)

	-- Build roster UI
    EposUI.roster_tab  		 = BuildRosterTab(roster_tab)
    EposUI.edit_roles_frame  = onEditRoles()

	-- Version Number in status bar
    local versionTitle = C_AddOns.GetAddOnMetadata("EposRaidTools", "Title")
    local verisonNumber = C_AddOns.GetAddOnMetadata("EposRaidTools", "Version")
    local statusBarText = versionTitle .. " v" .. verisonNumber
    EposUI.StatusBar.authorName:SetText(statusBarText)

end

function EposUI:ToggleMainFrame()
    if EposUI:IsShown() then
        EposUI:Hide()
    else
        EposUI:Show()
    end
end

Epos.EposUI = EposUI