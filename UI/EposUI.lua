-- ui/EposUI.lua
local _, Epos = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
local WA = _G["WeakAuras"]

-- Alias Constants as C
local C = Epos.Constants

local ui_panel_options = {
    UseStatusBar = true
}

local EposUI = DF:CreateSimplePanel(
    UIParent,
    C.window_width,
    C.window_height,
    "|cFF00FFFFEpos|r Raid Tools",
    "EposUI",
    ui_panel_options
)
EposUI:SetPoint("CENTER")
EposUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(EposUI.StatusBar, _, "x |cFF00FFFFbird|r")
EposUI.StatusBar.discordTextEntry:SetText("badbluu")

function EposUI:Init()
    DF:CreateScaleBar(EposUI, EposRT.EposUI)
    EposUI:SetScale(EposRT.EposUI.scale)

    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(
        EposUI,
        "Epos",
        "EposUI_Tab",
        {
            { name = "Database",  text = "Database"  },
            { name = "Crests",    text = "Crests"    },
            { name = "WeakAuras", text = "WeakAuras" },
            { name = "AddOns",    text = "AddOns"    },
            { name = "Settings",  text = "Settings"  },
            { name = "Setup",     text = "Setup"     },
        },
        {
            width                 = C.window_width,
            height                = C.window_height - 5,
            backdrop_color        = { 0, 0, 0, 0.2 },
            backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 },
        }
    )
    tabContainer:SetPoint("CENTER", EposUI, "CENTER", 0, 0)

    local roster_tab    = tabContainer:GetTabFrameByName("Database")
    local crests_tab    = tabContainer:GetTabFrameByName("Crests")
    local weakauras_tab = tabContainer:GetTabFrameByName("WeakAuras")
    local addons_tab    = tabContainer:GetTabFrameByName("AddOns")
    local settings_tab  = tabContainer:GetTabFrameByName("Settings")
    local setup_tab     = tabContainer:GetTabFrameByName("Setup")

    local settings_options_table = {
        {
            type          = "label",
            get           = function() return "General Options" end,
            text_template = C.templates.text,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Minimap Button",
            desc = "Hide the minimap button.",
            get = function() return EposRT.Settings["Minimap"].hide end,
            set = function(self, fixedParam, value)
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
            set = function(self, fixedParam, value)
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
            nocombat = true,
        },
        {
            type = "execute",
            name = "Clear EposRT Data",
            desc = "This will erase all EposRT saved settings and reload the UI.",
            confirm = true,
            confirmText = "Are you sure you want to clear all EposRT data? This cannot be undone.",
            func = function()
                -- Clear the saved settings
                -- Also clear runtime state if needed
                EposRT = {}
                -- Reload UI to apply changes
                ReloadUI()
            end,
        },
    }

    -- AddOns tab (empty menu)
    DF:BuildMenu(
        addons_tab,
        {},
        10, -100,
        C.window_height - 10,
        false,
        C.templates.text,
        C.templates.dropdown,
        C.templates.switch,
        true,
        C.templates.slider,
        C.templates.button,
        nil
    )

    -- Settings tab
    DF:BuildMenu(
        settings_tab,
        settings_options_table,
        10, -100,
        C.window_height - 10,
        false,
        C.templates.text,
        C.templates.dropdown,
        C.templates.switch,
        true,
        C.templates.slider,
        C.templates.button,
        nil
    )

    -- Setup tab (empty menu)
    DF:BuildMenu(
        setup_tab,
        {},
        10, -100,
        C.window_height - 10,
        false,
        C.templates.text,
        C.templates.dropdown,
        C.templates.switch,
        true,
        C.templates.slider,
        C.templates.button,
        nil
    )

    -- Build roster UI
    EposUI.roster_tab       = BuildRosterTab(roster_tab)
    EposUI.database_options = BuildTrackingOptions()
    EposUI.blacklist_frame  = BuildBlacklistUI()

    -- Build crest UI
    EposUI.crests_tab       = BuildCrestsTab(crests_tab)
    EposUI.crests_options   = BuildCrestsOptions()

    -- WeakAuras UI
    EposUI.weakauras_tab    = BuildWeakAurasTab(weakauras_tab)

    -- Version number in status bar
    local versionTitle = C_AddOns.GetAddOnMetadata("EposRaidTools", "Title")
    local versionNumber = C_AddOns.GetAddOnMetadata("EposRaidTools", "Version")
    local statusBarText = versionTitle .. " v" .. versionNumber
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