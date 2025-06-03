-- ui/EposUI
local _, Epos = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
local WA = _G["WeakAuras"]

local ui_panel_options = {
    UseStatusBar = true
}
local EposUI = DF:CreateSimplePanel(UIParent, Epos.Constants.window_width, Epos.Constants.window_height, "|cFF00FFFFEpos|r Raid Tools", "EposUI",
    ui_panel_options)
EposUI:SetPoint("CENTER")
EposUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(EposUI.StatusBar, _, "x |cFF00FFFFbird|r")
EposUI.StatusBar.discordTextEntry:SetText("badbluu")

function EposUI:Init()
    DF:CreateScaleBar(EposUI, EposRT.EposUI)
    EposUI:SetScale(EposRT.EposUI.scale)

    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(EposUI, "Epos", "EposUI_Tab", {
        {
			name 		= "Database",
			text 		= "Database"
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
        width = Epos.Constants.window_width,
        height = Epos.Constants.window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
    })

	tabContainer:SetPoint("CENTER", EposUI, "CENTER", 0, 0)

	local roster_tab 			= tabContainer:GetTabFrameByName("Database")
    local crests_tab 			= tabContainer:GetTabFrameByName("Crests")
    local weakauras_tab 		= tabContainer:GetTabFrameByName("WeakAuras")
    local addons_tab 			= tabContainer:GetTabFrameByName("AddOns")
    local settings_tab 			= tabContainer:GetTabFrameByName("Settings")
    local setup_tab 			= tabContainer:GetTabFrameByName("Setup")

    local settings_options_table = {
		{ type = "label", get = function() return "General Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Minimap Button",
            desc = "Hide the minimap button.",
            get = function() return EposRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                EposRT.Settings["Minimap"].hide = value
                LDBIcon:Refresh("EposRT", EposRT.Settings["Minimap"])
            end,
        },
		{
            type = "toggle",
            boxfirst = true,
            name = "Enable Debug Mode",
            desc = "Enables Debug Mode, which bypasses certain restrictions like checking for active encounter / combat / being in a raid",
            get = function() return EposRT.Settings["Debug"] end,
            set = function(self, fixedparam, value)
                EposRT.Settings["Debug"] = value
            end,
        },
		{ type = "break" },
		{
            type = "select",
            get = function() return "MEDIUM" end,
            values = function() return {} end,
            name = "Frame Strata",
            desc = "Choose Frame Strata for Epos Raid Tools.",
            nocombat = true
        }
    }

	-- weakauras
    DF:BuildMenu(weakauras_tab, {}, 10, -100, Epos.Constants.window_height - 10, false, Epos.Constants.templates.text,
        Epos.Constants.templates.dropdown, Epos.Constants.templates.switch, true, Epos.Constants.templates.slider, Epos.Constants.templates.button,
        nil)
	-- addons
    DF:BuildMenu(addons_tab, {}, 10, -100, Epos.Constants.window_height - 10, false, Epos.Constants.templates.text,
        Epos.Constants.templates.dropdown, Epos.Constants.templates.switch, true, Epos.Constants.templates.slider, Epos.Constants.templates.button,
        nil)
	-- settings
    DF:BuildMenu(settings_tab, settings_options_table, 10, -100, Epos.Constants.window_height - 10, false, Epos.Constants.templates.text,
        Epos.Constants.templates.dropdown, Epos.Constants.templates.switch, true, Epos.Constants.templates.slider, Epos.Constants.templates.button,
        nil)
	-- setup
    DF:BuildMenu(setup_tab, {}, 10, -100, Epos.Constants.window_height - 10, false, Epos.Constants.templates.text,
        Epos.Constants.templates.dropdown, Epos.Constants.templates.switch, true, Epos.Constants.templates.slider, Epos.Constants.templates.button,
        nil)

	-- Build roster UI
    EposUI.roster_tab  		 = BuildRosterTab(roster_tab)
    EposUI.database_options  = BuildTrackingOptions()
	EposUI.blacklist_frame 	 = BuildBlacklistUI()

	-- Build crest UI
    EposUI.crests_tab  		 = BuildCrestsTab(crests_tab)
    EposUI.crests_options    = BuildCrestsOptions()

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