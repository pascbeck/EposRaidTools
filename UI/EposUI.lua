-- ui/EposUI.lua

local _, Epos  = ...

local C        = Epos.Constants                         -- Constants for dimensions, templates, colors
local DF       = _G.DetailsFramework                    -- Cached DetailsFramework
local UIParent = _G.UIParent                            -- Parent frame for UI panels
local LibStub  = _G.LibStub                             -- LibStub for library access
local LDB      = LibStub("LibDataBroker-1.1", true)     -- LibStub LDB
local LDBIcon  = LDB and LibStub("LibDBIcon-1.0", true) -- LibStub LDBIcon
local WA       = _G.WeakAuras                           -- WeakAuras global (if loaded)
local C_AddOns = _G.C_AddOns                            -- Blizzard API for AddOn metadata

--- Panel Options
-- Options passed to CreateSimplePanel; here we enable the status bar
local PANEL_OPTIONS = {
    UseStatusBar = true,
}
--- Returns a new frame with a decorative title bar and status bar.
local EposUI = DF:CreateSimplePanel(
        UIParent,
        C.window_width,
        C.window_height,
        "|cFF00FFFFEpos|r Raid Tools",
        "EposUI",
        PANEL_OPTIONS
)
EposUI:SetPoint("CENTER")
EposUI:SetFrameStrata("HIGH")

-- Build author info on the status bar (replace “bird” with actual author)
DF:BuildStatusbarAuthorInfo(EposUI.StatusBar, _, "x |cFF00FFFFbird|r")

-- Set a placeholder for Discord or other text entry
EposUI.StatusBar.discordTextEntry:SetText("badbluu")

--- EposUI:Init
--- Initializes the UI: creates a scale bar, builds tab container,
--  constructs menus for each tab, and sets version text on the status bar.
function EposUI:Init()
    -- Ensure SavedVariables for UI scale exist
    EposRT.EposUI = EposRT.EposUI or { scale = 1 }

    -- Create and apply a scale slider for the main panel
    DF:CreateScaleBar(self, EposRT.EposUI)
    self:SetScale(EposRT.EposUI.scale)

    -- ------------------------------------------------------------------------
    -- Create Tab Container
    -- ------------------------------------------------------------------------
    local TAB_LAYOUT = {
        { name = "Database",  text = "Database"  },
        { name = "Crests",    text = "Crests"    },
        { name = "WeakAuras", text = "WeakAuras" },
        { name = "AddOns",    text = "AddOns"    },
        { name = "Setup",     text = "Setup"     },
        { name = "Settings",  text = "Settings"  },
    }
    local CONTAINER_OPTIONS = {
        width               = C.window_width,
        height              = C.window_height - 5,
        backdrop_color      = { 0, 0, 0, 0.2 },
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
    local rosterTab     = tabContainer:GetTabFrameByName("Database")
    local crestsTab     = tabContainer:GetTabFrameByName("Crests")
    local weakaurasTab  = tabContainer:GetTabFrameByName("WeakAuras")
    local addonsTab     = tabContainer:GetTabFrameByName("AddOns")
    local settingsTab   = tabContainer:GetTabFrameByName("Settings")
    local setupTab      = tabContainer:GetTabFrameByName("Setup")

    --- Settings Menu Construction
    -- Table of option descriptors passed to BuildMenu on the Settings tab
    local settingsOptions = {
        {
            type          = "label",
            get           = function() return "General Options" end,
            text_template = C.templates.text,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = "Disable Minimap Button",
            desc     = "Hide the minimap button.",
            get      = function()
                EposRT.Settings = EposRT.Settings or {}
                EposRT.Settings.Minimap = EposRT.Settings.Minimap or { hide = false }
                return EposRT.Settings.Minimap.hide
            end,
            set      = function(_, _, value)
                EposRT.Settings.Minimap.hide = value
                if LDBIcon then
                    LDBIcon:Refresh("EposRT", EposRT.Settings.Minimap)
                end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = "Enable Debug Mode",
            desc     = "Bypass encounter/combat/raid restrictions for testing.",
            get      = function()
                EposRT.Settings = EposRT.Settings or {}
                return EposRT.Settings.Debug or false
            end,
            set      = function(_, _, value)
                EposRT.Settings.Debug = value
            end,
        },
        { type = "break" },
        {
            type    = "select",
            get     = function() return "MEDIUM" end,
            values  = function() return {} end,
            name    = "Frame Strata",
            desc    = "Choose Frame Strata for Epos Raid Tools.",
            nocombat = true,
        },
        {
            type = "execute",
            name = "Clear EposRT Data",
            desc = "Erase all saved settings and reload the UI.",
            func = function()
                wipe(EposRT)
                ReloadUI()
            end,
        },
    }

    -- Build Empty/AddOn & Setup Menus
    local menuX      = 10
    local menuY      = -100
    local menuHeight = C.window_height - 10

    -- AddOns tab uses an empty/options placeholder
    DF:BuildMenu(
            addonsTab,
            {},
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

    -- Build Database (Roster) UI
    if BuildRosterTab then
        self.roster_tab = BuildRosterTab(rosterTab)
    end
    if BuildTrackingOptions then
        self.database_options = BuildTrackingOptions()
    end
    if BuildBlacklistUI then
        self.blacklist_frame = BuildBlacklistUI()
    end

    -- Build Crests UI
    if BuildCrestsTab then
        self.crests_tab = BuildCrestsTab(crestsTab)
    end
    if BuildCrestsOptions then
        self.crests_options = BuildCrestsOptions()
    end

    -- Build WeakAuras UI
    if BuildWeakAurasTab then
        self.weakauras_tab = BuildWeakAurasTab(weakaurasTab)
    end
    if BuildWeakAurasOptions then
        self.weakauras_options = BuildWeakAurasOptions()
    end

    -- Build AddOns UI
    if BuildAddOnsTab then
        self.addons_tab = BuildAddOnsTab(addonsTab)
    end
    if BuildAddOnsOptions then
        self.addons_options = BuildAddOnsOptions()
    end

    -- Setup UI
    if BuildSetupsManagerUI then
        self.setup_tab = BuildSetupsManagerUI(setupTab)
    end
    if BuildSetupsManagerOptions then
        self.setup_manager_options = BuildSetupsManagerOptions()
    end

    -- Display Version in Status Bar
    local title       = C_AddOns.GetAddOnMetadata("EposRaidTools", "Title") or "Epos Raid Tools"
    local version     = C_AddOns.GetAddOnMetadata("EposRaidTools", "Version") or "?.?.?"
    local statusText  = title .. " v" .. version
    if self.StatusBar and self.StatusBar.authorName then
        self.StatusBar.authorName:SetText(statusText)
    end
end

--- EposUI:ToggleMainFrame
--- Toggles visibility of the main UI panel.
function EposUI:ToggleMainFrame()
    if self:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Assign EposUI to the AddOn namespace for external access
Epos.EposUI = EposUI