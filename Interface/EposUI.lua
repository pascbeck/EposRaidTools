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
            "|cFF78A8FFEpos|r",
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

    local strataTable = {
        { value = "BACKGROUND", label = "Background", onclick = function()
            EposUI:SetFrameStrata("BACKGROUND")
            EposRT.Settings.FrameStrata = "BACKGROUND"
        end, icon = [[Interface\Buttons\UI-MicroStream-Green]], iconcolor = { 0, .5, 0, .8 }, texcoord = nil }, --Interface\Buttons\UI-MicroStream-Green UI-MicroStream-Red UI-MicroStream-Yellow
        { value = "LOW", label = "Low", onclick = function()
            EposUI:SetFrameStrata("LOW")
            EposRT.Settings.FrameStrata = "LOW"
        end, icon = [[Interface\Buttons\UI-MicroStream-Green]], texcoord = nil }, --Interface\Buttons\UI-MicroStream-Green UI-MicroStream-Red UI-MicroStream-Yellow
        { value = "MEDIUM", label = "Medium", onclick = function()
            EposUI:SetFrameStrata("MEDIUM")
            EposRT.Settings.FrameStrata = "MEDIUM"
        end, icon = [[Interface\Buttons\UI-MicroStream-Yellow]], texcoord = nil }, --Interface\Buttons\UI-MicroStream-Green UI-MicroStream-Red UI-MicroStream-Yellow
        { value = "HIGH", label = "High", onclick = function()
            EposUI:SetFrameStrata("HIGH")
            EposRT.Settings.FrameStrata = "HIGH"
        end, icon = [[Interface\Buttons\UI-MicroStream-Yellow]], iconcolor = { 1, .7, 0, 1 }, texcoord = nil }, --Interface\Buttons\UI-MicroStream-Green UI-MicroStream-Red UI-MicroStream-Yellow
        { value = "DIALOG", label = "Dialog", onclick = function()
            EposUI:SetFrameStrata("DIALOG")
            EposRT.Settings.FrameStrata = "DIALOG"
        end, icon = [[Interface\Buttons\UI-MicroStream-Red]], iconcolor = { 1, 0, 0, 1 }, texcoord = nil }, --Interface\Buttons\UI-MicroStream-Green UI-MicroStream-Red UI-MicroStream-Yellow
    }
    local buildStrataMenu = function()
        return strataTable
    end

    local channel_list = {
        { value = "SAY", icon = [[Interface\FriendsFrame\UI-Toast-ToastIcons]], iconsize = { 14, 14 }, texcoord = { 0.0390625, 0.203125, 0.09375, 0.375 }, label = "Say", onclick = function()
            EposRT.Settings.AnnouncementChannel = "SAY"
        end },
        { value = "YELL", icon = [[Interface\FriendsFrame\UI-Toast-ToastIcons]], iconsize = { 14, 14 }, texcoord = { 0.0390625, 0.203125, 0.09375, 0.375 }, iconcolor = { 1, 0.3, 0, 1 }, label = "Yell", onclick = function()
            EposRT.Settings.AnnouncementChannel = "YELL"
        end },
        { value = "RAID", icon = [[Interface\FriendsFrame\UI-Toast-ToastIcons]], iconcolor = { 1, 0.49, 0 }, iconsize = { 14, 14 }, texcoord = { 0.53125, 0.7265625, 0.078125, 0.40625 }, label = "Raid", onclick = function()
            EposRT.Settings.AnnouncementChannel = "RAID"
        end },
        { value = "WHISPER", icon = [[Interface\FriendsFrame\UI-Toast-ToastIcons]], iconcolor = { 1, 0.49, 1 }, iconsize = { 14, 14 }, texcoord = { 0.0546875, 0.1953125, 0.625, 0.890625 }, label = "Whisper", onclick = function()
            EposRT.Settings.AnnouncementChannel = "WHISPER"
        end },
    }
    local buildChannelMenu = function()
        return channel_list
    end

    -- Table of option descriptors passed to BuildMenu on the Settings tab
    -- Table of option descriptors passed to BuildMenu on the Settings tab
    local settingsOptions = {
    {
        type = "label", get = function() return "General Settings" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    },
    {
        type = "toggle", boxfirst = true, name = "Auto Request on Player Login",
        desc = "Automatically send data request when a player logs in.",
        get = function() return EposRT.Settings.EnableDataRequestOnLoginEvent end,
        set = function(_, _, val) EposRT.Settings.EnableDataRequestOnLoginEvent = val end,
    },
    {
        type = "toggle", boxfirst = true, name = "Compare MRT Notes on Ready Check",
        desc = "Compares raid notes when a ready check is initiated.",
        get = function() return EposRT.Settings.CompareNotes end,
        set = function(_, _, val) EposRT.Settings.CompareNotes = val end
    },

    { type = "break" },

    {
        type = "label", get = function() return "UI Appearance" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    },
    {
        type = "select", name = "Frame Strata", desc = "Adjust UI layering (z-index).",
        get = function() return EposRT.Settings.FrameStrata end,
        values = buildStrataMenu,
        set = function(_, _, val)
            EposRT.Settings.FrameStrata = val
            EposUI:SetFrameStrata(val)
        end, nocombat = true
    },
    {
        type = "toggle", boxfirst = true, name = "Hide Minimap Button",
        desc = "Hide the minimap icon for this addon.",
        get = function() return EposRT.Settings.Minimap.hide end,
        set = function(_, _, val)
            EposRT.Settings.Minimap.hide = val
            if LDBIcon then
                LDBIcon:Refresh("EposRT", EposRT.Settings.Minimap)
            end
        end
    },
    {
        type = "toggle", boxfirst = true, name = "Window Transparency",
        desc = "Enable transparency for the addon window.",
        get = function() return EposRT.Settings.Transparency end,
        set = function(_, _, val)
            EposRT.Settings.Transparency = val
            EposUI:SetBackdropColor(0, 0, 0, val and 0.9 or 1)
        end
    },
    {
        type = "toggle", boxfirst = true, name = "Hide UI Status Bar",
        desc = "Hide the status bar at the bottom of the main frame.",
        get = function() return EposRT.Settings.HideStatusBar end,
        set = function(_, _, val)
            EposRT.Settings.HideStatusBar = val
            if val then EposUI.StatusBar:Hide() else EposUI.StatusBar:Show() end
        end
    },

    { type = "break" },

    {
        type = "label", get = function() return "Roster Setup" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    },
    {
        type = "toggle", boxfirst = true, name = "Announce Benched Players",
        desc = "Announces benched players in chosen channel.",
        get = function() return EposRT.Settings.AnnounceBenchedPlayers end,
        set = function(_, _, val) EposRT.Settings.AnnounceBenchedPlayers = val end,
    },
    {
        type = "toggle", boxfirst = true, name = "Announce Unbenched Players",
        desc = "Announces players brought back into the setup.",
        get = function() return EposRT.Settings.AnnounceUnBenchedPlayers end,
        set = function(_, _, val) EposRT.Settings.AnnounceUnBenchedPlayers = val end,
    },
    {
        type = "select", name = "Announcement Channel",
        desc = "Select how player announcements are broadcast.",
        get = function() return EposRT.Settings.AnnouncementChannel end,
        values = buildChannelMenu,
        set = function(_, _, val) EposRT.Settings.AnnouncementChannel = val end,
        nocombat = true
    },
    {
        type = "execute", name = "Clear Setup",
        desc = "Reset current raid setup and reload UI.",
        icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
        func = function()
            wipe(EposRT.Setups.JSON)
            wipe(EposRT.Setups.Current)
            wipe(EposRT.Setups.Old)
            EposUI.SetupsTab:MasterRefresh()
            EposUI.SetupsTab.__bossDropdown:Refresh()
            ReloadUI()
        end
    },

    { type = "breakline" },

    {
        type = "label", get = function() return "Logging" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    },
    {
        type = "toggle", boxfirst = true, name = "Log Data Requests",
        desc = "Logs when a data request is sent.",
        get = function() return EposRT.Settings.EnableDataRequestLogging end,
        set = function(_, _, val) EposRT.Settings.EnableDataRequestLogging = val end,
    },
    {
        type = "toggle", boxfirst = true, name = "Log Data Receives",
        desc = "Logs when data is received.",
        get = function() return EposRT.Settings.EnableDataReceiveLogging end,
        set = function(_, _, val) EposRT.Settings.EnableDataReceiveLogging = val end,
    },
        {
        type = "toggle", boxfirst = true, name = "Logs Notes Mismatch",
        desc = "Prints logs to chat when mismatched notes are detected.",
        get = function() return EposRT.Settings.ShowMismatchLogs end,
        set = function(_, _, val) EposRT.Settings.ShowMismatchLogs = val end
    },
    {
        type = "toggle", boxfirst = true, name = "Log EposRT Events",
        desc = "Enable logging of important raid events.",
        get = function() return EposRT.Settings.EnableEventLogging end,
        set = function(_, _, val) EposRT.Settings.EnableEventLogging = val end,
    },

    { type = "break" },

    {
        type = "label", get = function() return "Developer Tools" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    },
    {
        type = "toggle", boxfirst = true, name = "Enable Debug Mode",
        desc = "Log extra information for troubleshooting.",
        get = function() return EposRT.Settings.Debug end,
        set = function(_, _, val) EposRT.Settings.Debug = val end,
    },
    {
        type = "execute", name = "Clear All Settings",
        desc = "Resets all settings and reloads the UI.",
        icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
        func = function()
            wipe(EposRT.Settings)
            ReloadUI()
        end
    },
    {
        type = "execute", name = "Clear Database",
        desc = "Wipe all stored addon data and reload UI.",
        icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
        func = function()
            wipe(EposRT)
            ReloadUI()
        end
    },
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
    -- self.SetupsTabOptions = BuildSetupsInterfaceOptions()

    -- Display Version in Status Bar
    local title = "Epos Raid Tools"
    local version = C_AddOns.GetAddOnMetadata("EposRaidTools", "Version") or "?.?.?"
    local statusText = title .. " v" .. version
    if self.StatusBar and self.StatusBar.authorName then
        self.StatusBar.authorName:SetText(statusText)
    end

    if EposRT.Settings.Transparency then
        EposUI:SetBackdropColor(0, 0, 0, 0.9)
    else
        EposUI:SetBackdropColor(0, 0, 0, 1)
    end

    -- Ensure status bar visibility is correct on load
    if EposRT.Settings.HideStatusBar then
        EposUI.StatusBar:Hide()
    else
        EposUI.StatusBar:Show()
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