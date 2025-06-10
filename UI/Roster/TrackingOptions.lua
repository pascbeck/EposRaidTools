-- ui/roster/BuildTrackingOptions.lua

local _, Epos   = ...                                     -- AddOn namespace
local DF        = _G.DetailsFramework                     -- DetailsFramework library
local UIParent  = _G.UIParent                             -- Blizzard UI parent frame
local C         = Epos.Constants                          -- Constants (window sizes, templates, etc.)

-- Guild ranks that can be toggled for tracking
local RANKS = {
    "Guildlead",
    "Officer",
    "Officer Alt",
    "Raider",
    "Raid Alt",
    "Trial",
}

--- BuildTrackingOptions()
-- @return Frame tracking_options_frame
function BuildTrackingOptions()
    -- Create the Main Options Panel
    local tracking_options_frame = DF:CreateSimplePanel(
            UIParent,
            485,
            420,
            "Roles Management",
            "RolesEditFrame",
            { DontRightClickClose = true }
    )
    tracking_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    -- Build the Options Table
    local options = {}

    -- Section: Track Guild Ranks Label
    options[#options + 1] = {
        type          = "label",
        get           = function() return "Track Guild Ranks" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }

    -- Toggles for each rank
    for _, rankName in ipairs(RANKS) do
        options[#options + 1] = {
            type     = "toggle",
            boxfirst = true,
            name     = rankName,
            desc     = "Enable or disable tracking for " .. rankName,
            get      = function()
                -- Default to true if not set
                if EposRT.Settings.TrackedRoles[rankName] == nil then
                    EposRT.Settings.TrackedRoles[rankName] = true
                end
                return EposRT.Settings.TrackedRoles[rankName]
            end,
            set      = function(_, _, value)
                EposRT.Settings.TrackedRoles[rankName] = value
                if EposUI and EposUI.roster_tab then
                    EposUI.roster_tab:MasterRefresh()
                end
            end,
            nocombat = true,
        }
    end

    -- Spacer
    options[#options + 1] = { type = "break" }

    -- Section: Blacklist & Whitelist Label
    options[#options + 1] = {
        type          = "label",
        get           = function() return "Blacklist & Whitelist" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }

    -- Button: Edit Blacklist
    options[#options + 1] = {
        type = "execute",
        name = "Edit Blacklist",
        desc = "Manually add players to the tracking blacklist",
        func = function()
            if EposUI and EposUI.blacklist_frame then
                -- Hide the tracking options panel and show the blacklist UI
                tracking_options_frame:Hide()
                EposUI.blacklist_frame:Show()
            end
        end,
    }

    -- Build the Menu Using Constants for Templates
    DF:BuildMenu(
            tracking_options_frame,
            options,
            10,
            -30,
            380,
            false,
            C.templates.text,
            C.templates.dropdown,
            C.templates.switch,
            true,
            C.templates.slider,
            C.templates.button,
            nil
    )

    -- Initially hide the frame; shown when user clicks “Roles Management”
    tracking_options_frame:Hide()

    return tracking_options_frame
end
