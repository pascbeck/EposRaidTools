-- interface/EposUI.lua

local _, Epos = ...

local C = Epos.Constants
local DF = _G.DetailsFramework
local UIParent = _G.UIParent
local LibStub = _G.LibStub
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local WA = _G.WeakAuras
local C_AddOns = _G.C_AddOns

-- Options passed to CreateSimplePanel; here we enable the status bar
local PANEL_OPTIONS = {
    UseStatusBar = true,
}

local EposUI = DF:CreateSimplePanel(
        UIParent,
        C.window_width,
        C.window_height,
        "Epos Raid Tools",
        "EposUI",
        PANEL_OPTIONS
)
EposUI:SetPoint("CENTER")
EposUI:SetFrameStrata("HIGH")

DF:BuildStatusbarAuthorInfo(EposUI.StatusBar, _, "Bluu")

EposUI.StatusBar.discordTextEntry:SetText("badbluu")

-- Initializes the UI: creates a scale bar, builds tab container, constructs menus for each tab, and sets version text on the status bar.
function EposUI:Init()
    -- Create and apply a scale slider for the main panel
    DF:CreateScaleBar(self, EposRT.EposUI)
    self:SetScale(EposRT.EposUI.scale)

    -- Container
    local TAB_LAYOUT = {
        { name = "Database", text = "Database" },
        { name = "Crests", text = "Crests" },
        { name = "WeakAuras", text = "WeakAuras" },
        { name = "AddOns", text = "AddOns" },
        { name = "Setup", text = "Setup" },
        { name = "Settings", text = "Settings" },
    }

    local CONTAINER_OPTIONS = {
        width = C.window_width,
        height = C.window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 },
    }

    local tabContainer = DF:CreateTabContainer(
            self,
            "Epos",
            "EposUI_Tab",
            TAB_LAYOUT,
            CONTAINER_OPTIONS
    )

    tabContainer:SetPoint("CENTER", self, "CENTER", 0, 0)

    -- Retrieve each tab frame for later content building
    local databaseTab = tabContainer:GetTabFrameByName("Database")
    local crestsTab = tabContainer:GetTabFrameByName("Crests")
    local weakaurasTab = tabContainer:GetTabFrameByName("WeakAuras")
    local addonsTab = tabContainer:GetTabFrameByName("AddOns")
    local setupTab = tabContainer:GetTabFrameByName("Setup")
    local settingsTab = tabContainer:GetTabFrameByName("Settings")

    -- Table of option descriptors passed to BuildMenu on the Settings tab
    local settingsOptions = {
        --{
        --    type = "label",
        --    get = function()
        --        return "General Options"
        --    end,
        --    text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        --},
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Disable Minimap Button",
        --    desc = "Hide the minimap button.",
        --    get = function()
        --        EposRT.Settings = EposRT.Settings or {}
        --        EposRT.Settings.Minimap = EposRT.Settings.Minimap or { hide = false }
        --        return EposRT.Settings.Minimap.hide
        --    end,
        --    set = function(_, _, value)
        --        EposRT.Settings.Minimap.hide = value
        --        if LDBIcon then
        --            LDBIcon:Refresh("EposRT", EposRT.Settings.Minimap)
        --        end
        --    end,
        --},
        --
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Disable all prints",
        --    desc = "Disables all Epos Raid Tools prints",
        --    get = function()
        --        EposRT.Settings = EposRT.Settings or {}
        --        EposRT.Settings.Minimap = EposRT.Settings.Minimap or { hide = false }
        --        return EposRT.Settings.Minimap.hide
        --    end,
        --    set = function(_, _, value)
        --        EposRT.Settings.Minimap.hide = value
        --        if LDBIcon then
        --            LDBIcon:Refresh("EposRT", EposRT.Settings.Minimap)
        --        end
        --    end,
        --},
        --
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Enable Debug Mode",
        --    desc = "Bypass encounter/combat/raid restrictions for testing.",
        --    get = function()
        --        EposRT.Settings = EposRT.Settings or {}
        --        return EposRT.Settings.Debug or false
        --    end,
        --    set = function(_, _, value)
        --        EposRT.Settings.Debug = value
        --    end,
        --},
        ----{ type = "break" },
        ----{
        ----    type    = "select",
        ----    get     = function() return "MEDIUM" end,
        ----    values  = function() return {} end,
        ----    name    = "Frame Strata",
        ----    desc    = "Choose Frame Strata for Epos Raid Tools.",
        ----    nocombat = true,
        ----},
        --{ type = "break" },
        --{
        --    type = "label",
        --    get = function()
        --        return "Automatic Background Update"
        --    end,
        --    text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        --},
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Log sender name on data receive",
        --    desc = "Prints sender on data receive",
        --    get = function()
        --        return EposRT.enableIntervalFetching
        --    end,
        --    set = function(_, _, value)
        --        EposRT.enableIntervalFetching = value
        --    end,
        --    nocombat = true,
        --},
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Enable data request on player login",
        --    desc = "Sends data request to the player who recently logged in",
        --    get = function()
        --        return EposRT.enableIntervalFetching
        --    end,
        --    set = function(_, _, value)
        --        EposRT.enableIntervalFetching = value
        --    end,
        --    nocombat = true,
        --},
        --{
        --    type = "toggle",
        --    boxfirst = true,
        --    name = "Enable interval fetching",
        --    desc = "Enable periodic roster updates",
        --    get = function()
        --        return EposRT.enableIntervalFetching
        --    end,
        --    set = function(_, _, value)
        --        EposRT.enableIntervalFetching = value
        --    end,
        --    nocombat = true,
        --},
        --{
        --    type = "slider",
        --    name = "Interval (Seconds)",
        --    desc = "How often to fetch updated roster info",
        --    min = 1,
        --    max = 60,
        --    step = 1,
        --    get = function()
        --        return EposRT.fetchInterval
        --    end,
        --    set = function(_, _, value)
        --        EposRT.fetchInterval = value
        --    end,
        --    disabled = function()
        --        return not EposRT.enableIntervalFetching
        --    end,
        --    nocombat = true,
        --},
        --{ type = "break" },
        --{
        --    type = "label",
        --    get = function()
        --        return "Developer"
        --    end,
        --    text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        --},
        --{
        --    type = "execute",
        --    name = "Clear Database",
        --    desc = "Erase all saved settings and reload the UI.",
        --    func = function()
        --        wipe(EposRT)
        --        ReloadUI()
        --    end,
        --},
    }

    -- Build Empty/AddOn & Setup Menus
    local menuX = 10
    local menuY = -100
    local menuHeight = C.window_height - 10

    -- Settings tab with actual settings options
    DF:BuildMenu(
            settingsTab,
            settingsOptions,
            menuX, menuY,
            menuHeight,
            false,
            C.templates.text,
            C.templates.dropdown,
            C.templates.switch,
            true,
            C.templates.slider,
            C.templates.button,
            nil
    )

    self.DatabaseTab = BuildDatabaseInterface(databaseTab)
    self.DatabaseTabOptions = BuildDatabaseInterfaceOptions(databaseTab)
    self.DatabaseTabOptionsBlacklist = BuildDatabaseInterfaceOptionsBlacklist()

    self.CrestsTab = BuildCrestsInterface(crestsTab)
    self.CrestsTabOptions = BuildCrestsInterfaceOptions()

    self.WeakAurasTab = BuildWeakAurasInterface(weakaurasTab)
    self.WeakAurasTabOptions = BuildWeakAurasInterfaceOptions()

    self.AddOnsTab = BuildAddOnsInterface(addonsTab)
    self.AddOnsTabOptions = BuildAddOnsInterfaceOptions()

    self.SetupsTab = BuildSetupsInterface(setupTab)
    self.SetupsTabOptions = BuildSetupsInterfaceOptions()

    -- Display Version in Status Bar
    local title = C_AddOns.GetAddOnMetadata("EposRaidTools", "Title") or "Epos Raid Tools"
    local version = C_AddOns.GetAddOnMetadata("EposRaidTools", "Version") or "?.?.?"
    local statusText = title .. " v" .. version
    if self.StatusBar and self.StatusBar.authorName then
        self.StatusBar.authorName:SetText(statusText)
    end
end

-- Toggles visibility of the main UI panel.
function EposUI:ToggleMainFrame()
    if self:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Assign EposUI to the AddOn namespace for external access
Epos.EposUI = EposUI