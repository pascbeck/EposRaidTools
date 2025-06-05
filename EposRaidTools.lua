-- EposRaidTools.lua

local _, Epos = ...

-- Cached WoW API functions (for performance)
local GetNumGuildMembers        = _G.GetNumGuildMembers
local GetGuildRosterInfo        = _G.GetGuildRosterInfo
local GetMaxLevelForLatestExpansion = _G.GetMaxLevelForLatestExpansion

-- LibDataBroker / LibDBIcon Integration
local LibStub     = _G.LibStub
local LDB         = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon     = LDB and LibStub:GetLibrary("LibDBIcon-1.0", true)

--- Initializes the LibDataBroker launcher object and minimap icon.
-- Creates a data object if LibDataBroker is available, registers it with LibDBIcon,
-- and stores the reference on the Epos namespace for later use.
function Epos:InitLDB()
    if not LDB or not LDBIcon then
        -- LibDataBroker or LibDBIcon is unavailable: skip initialization
        return
    end

    -- Create a new data object for our AddOn
    local dataObject = LDB:NewDataObject("EposRT", {
        type              = "launcher",
        label             = "Epos Raid Tools",
        icon              = "Interface\\AddOns\\EposRaidTools\\Media\\EposLogo",
        showInCompartment = true,

        -- Left-click toggles the main options UI
        OnClick = function(_, button)
            if button == "LeftButton" and Epos.EposUI then
                Epos.EposUI:ToggleMainFrame()
            end
        end,

        -- Tooltip displayed when hovering over the icon
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Epos Raid Tools", 0, 1, 1)
            tooltip:AddLine("|cFFCFCFCFLeft click|r: Show/Hide Options Window")
        end,
    })

    -- Register the data object with LibDBIcon if not already registered
    if dataObject and not LDBIcon:IsRegistered("EposRT") then
        LDBIcon:Register("EposRT", dataObject, EposRT.Settings.Minimap)
        LDBIcon:AddButtonToCompartment("EposRT")
    end

    -- Store reference on the Epos namespace for potential future use
    Epos.databroker = dataObject
end

--- Guild Roster Fetching
--- Fetches the current guild roster, filtering for characters at max level.
-- Populates EposRT.GuildRoster with a list of tables, each containing:
--   • name  = full character name (string)
--   • rank  = guild rank name (string)
--   • level = character level (number, should equal max level)
--   • class = class file name (e.g., "MAGE", "WARRIOR")
function Epos:FetchGuild()
    -- Clear any existing entries in the roster table
    table.wipe(EposRT.GuildRoster)

    -- Determine the max level for the latest expansion once, to avoid repeated calls
    local maxLevel = GetMaxLevelForLatestExpansion()
    if not maxLevel then
        -- API call failed or returned nil: abort
        return
    end

    local totalMembers = GetNumGuildMembers()
    if totalMembers <= 0 then
        -- No guild members to process
        return
    end

    -- Iterate through all guild members
    for index = 1, totalMembers do
        local fullName, rankName, _, level, _, _, _, _, _, _, classFile = GetGuildRosterInfo(index)
        if fullName and level == maxLevel then
            -- Only include characters at max level
            EposRT.GuildRoster[#EposRT.GuildRoster + 1] = {
                name  = fullName,
                rank  = rankName,
                level = level,
                class = classFile,
            }
        end
    end
end

return Epos
