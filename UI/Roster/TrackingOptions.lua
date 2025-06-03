local _, Epos = ...
local DF  = _G["DetailsFramework"]

function BuildTrackingOptions()
    local tracking_options_frame = DF:CreateSimplePanel(
        UIParent, 485, 420,
        "Roles Management", "RolesEditFrame",
        { DontRightClickClose = true }
    )
    tracking_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local ranks = {
        "Guildlead", "Officer", "Officer Alt",
        "Raider", "Raid Alt", "Trial",
    }

    local options = {
        {
            type          = "label",
            get           = function() return "Track guild ranks" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
    }

    for _, rank in ipairs(ranks) do
        table.insert(options, {
            type     = "toggle",
            boxfirst = true,
            name     = rank,
            desc     = "Enable or disable tracking for " .. rank,
            get      = function()
                return EposRT.Settings.TrackedRoles[rank]
            end,
            set = function(_, _, value)
                EposRT.Settings.TrackedRoles[rank] = value
                if EposUI.roster_tab then
                    EposUI.roster_tab:MasterRefresh()
                end
            end,
            nocombat = true,
        })
    end

    table.insert(options, { type = "break" })
    table.insert(options, {
        type          = "label",
        get           = function() return "Automatic background update" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    })

    -- Sample saved-vars for interval fetching:
    EposSaved = EposSaved or {}
    EposSaved.enableIntervalFetching = EposSaved.enableIntervalFetching or false
    EposSaved.fetchInterval = EposSaved.fetchInterval or 10

    table.insert(options, {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Interval Fetching",
        desc     = "Enable periodic roster updates",
        get      = function() return EposSaved.enableIntervalFetching end,
        set      = function(_, _, value) EposSaved.enableIntervalFetching = value end,
        nocombat = true,
    })
    table.insert(options, {
        type     = "slider",
        name     = "Interval (Seconds)",
        desc     = "How often to fetch updated roster info",
        min      = 1,
        max      = 60,
        step     = 1,
        get      = function() return EposSaved.fetchInterval end,
        set      = function(_, _, value) EposSaved.fetchInterval = value end,
        disabled = function() return not EposSaved.enableIntervalFetching end,
        nocombat = true,
    })

    table.insert(options, { type = "break" })
    table.insert(options, {
        type          = "label",
        get           = function() return "Blacklist & Whitelist" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    })

    -- Insert “Edit Blacklist” as a menu‐button:
    table.insert(options, {
        type = "execute",
        name = "Edit Blacklist",
        desc = "Manually add players to the tracking blacklist",
        func = function()
            if EposUI and EposUI.blacklist_frame then
                EposUI.database_options:Hide()
                EposUI.blacklist_frame:Show()
            end
        end,
    })

    DF:BuildMenu(
        tracking_options_frame,
        options,
        10, -30,  -- x, y offset
        380, false,
        DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"),
        DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
        DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"),
        true,
        DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE"),
        DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"),
        nil
    )

    tracking_options_frame:Hide()
    return tracking_options_frame
end