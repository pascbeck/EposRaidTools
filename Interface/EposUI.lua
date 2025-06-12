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
            type = "label",
            get = function()
                return "General Settings"
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Minimap Button",
            desc = "Enable this to hide the minimap button for the addon.",
            get = function()
                return EposRT.Settings["Minimap"].hide
            end,
            set = function(_, _, value)
                EposRT.Settings["Minimap"].hide = value
                if LDBIcon then
                    LDBIcon:Refresh("EposRT", EposRT.Settings["Minimap"])
                end
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Request Data on Player Login",
            desc = "Automatically sends a data request when a player logs in.",
            get = function()
                return EposRT.Settings["EnableDataRequestOnLoginEvent"]
            end,
            set = function(_, _, value)
                EposRT.Settings["EnableDataRequestOnLoginEvent"] = value
            end,
        },
        {
            type = "execute",
            name = "Clear All Settings",
            desc = "Resets all saved settings to their default values and reloads the UI.",
            icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
            func = function()
                wipe(EposRT.Settings)
                ReloadUI()
            end,
        },
        { type = "break" },
        {
            type = "label",
            get = function()
                return "Setup Options"
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Benched Players",
            desc = "Announces players who are benched in the current setup when applying the roster (via channel below).",
            get = function()
                return EposRT.Settings.AnnounceBenchedPlayers
            end,
            set = function(_, _, value)
                EposRT.Settings.AnnounceBenchedPlayers = value
            end,
        },
        {
            type = "select",
            get = function()
                return EposRT.Settings.AnnouncementChannel
            end,
            values = buildChannelMenu,
            name = "Announcement Channel",
            desc = "Choose the channel for announcing benched players (e.g., Whisper, Say, etc.).",
            set = function(_, _, value)
                EposRT.Settings.AnnouncementChannel = value
            end,
            nocombat = true, -- Ensure this can be changed outside of combat
        },
        {
            type = "execute",
            name = "Clear Setup",
            desc = "Resets all saved setup settings to their default values and reloads the UI.",
            icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
            func = function()
                wipe(EposRT.Setups.JSON)
                wipe(EposRT.Setups.Current)
                EposUI.SetupsTab:MasterRefresh()
                EposUI.SetupsTab.__bossDropdown:Refresh()
            end,
        },
        { type = "break" },
        {
            type = "label",
            get = function()
                return "Interface Options"
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            get = function()
                return EposRT.Settings.FrameStrata
            end,
            values = buildStrataMenu,
            name = "Frame Strata",
            desc = "Adjust the frame strata (z-order) for Epos Raid Tools. Higher strata will place the UI above other UI elements.",
            set = function(_, _, value)
                EposRT.Settings.FrameStrata = value
                EposUI:SetFrameStrata(value) -- Set the frame strata dynamically
            end,
            nocombat = true, -- Ensure this can be changed outside of combat
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Transparency",
            desc = "Enable or disable the transparency effect for the UI window.",
            get = function()
                return EposRT.Settings.Transparency
            end,
            set = function(_, _, value)
                EposRT.Settings.Transparency = value
                if value then
                    EposUI:SetBackdropColor(0, 0, 0, 0.9)
                else
                    EposUI:SetBackdropColor(0, 0, 0, 1)
                end
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Status Bar",
            desc = "Enable this to hide the status bar at the bottom of the UI.",
            get = function()
                return EposRT.Settings.HideStatusBar
            end,
            set = function(_, _, value)
                EposRT.Settings.HideStatusBar = value
                if value then
                    EposUI.StatusBar:Hide()
                else
                    EposUI.StatusBar:Show()
                end
            end,
        },
        { type = "breakline" },
        {
            type = "label",
            get = function()
                return "Logging Options"
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Log Data Requests in Chat",
            desc = "Prints a message to the chat when a data request is made.",
            get = function()
                return EposRT.Settings["EnableDataRequestLogging"]
            end,
            set = function(_, _, value)
                EposRT.Settings["EnableDataRequestLogging"] = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Log Data Receives in Chat",
            desc = "Prints a message to the chat when data is received.",
            get = function()
                return EposRT.Settings["EnableDataReceiveLogging"]
            end,
            set = function(_, _, value)
                EposRT.Settings["EnableDataReceiveLogging"] = value
            end,
        },
        { type = "break" },
        {
            type = "label",
            get = function()
                return "Developer Options"
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Debug Mode",
            desc = "Activate Debug Mode to log detailed information about the addon’s operation.",
            get = function()
                return EposRT.Settings.Debug
            end,
            set = function(_, _, value)
                EposRT.Settings.Debug = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Event Logging",
            desc = "Logs important raid events for later review or troubleshooting.",
            get = function()
                return EposRT.Settings.EnableEventLogging
            end,
            set = function(_, _, value)
                EposRT.Settings.EnableEventLogging = value
            end,
        },
        {
            type = "execute",
            name = "Clear Database",
            desc = "Resets Epos Raid Tools to their default values and reloads the UI.",
            icontexture = [[Interface\GLUES\LOGIN\Glues-CheckBox-Check]],
            func = function()
                wipe(EposRT)
                ReloadUI()
            end,
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