-- EposRaidTools.lua

local _, Epos = ...

-- Cached WoW API functions (for performance)
local GetNumGuildMembers = _G.GetNumGuildMembers
local GetGuildRosterInfo = _G.GetGuildRosterInfo
local GetMaxLevelForLatestExpansion = _G.GetMaxLevelForLatestExpansion
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS

-- LibDataBroker / LibDBIcon Integration
local LibStub = _G.LibStub
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub:GetLibrary("LibDBIcon-1.0", true)

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
        type = "launcher",
        label = "Epos Raid Tools",
        icon = "Interface\\AddOns\\EposRaidTools\\Media\\EposLogo",
        showInCompartment = true,

        -- Left-click toggles the main options UI
        OnClick = function(_, button)
            if button == "LeftButton" and Epos.EposUI then
                Epos.EposUI:ToggleMainFrame()
            end
        end,

        -- Tooltip displayed when hovering over the icon
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Epos Raid Tools", 120 / 255, 170 / 255, 255 / 255)
            tooltip:AddLine("|cFFFFA500Left click|r: |cFF00FF00Toggle Main Window|r")
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
-- Populates EposRT.GuildRoster.Players with a list of tables, each containing:
--   • name  = full character name (string)
--   • rank  = guild rank name (string)
--   • level = character level (number, should equal max level)
--   • class = class file name (e.g., "MAGE", "WARRIOR")
function Epos:FetchGuild()
    -- Clear any existing entries in the roster table
    table.wipe(EposRT.GuildRoster.Players)

    local maxLevel = GetMaxLevelForLatestExpansion()
    if not maxLevel then
        return
    end

    local totalMembers = GetNumGuildMembers()
    if totalMembers <= 0 then
        return
    end

    local allowedRanks = {
        ["Guildlead"] = true,
        ["Officer"] = true,
        ["Officer Alt"] = true,
        ["Raider"] = true,
        ["Raid Alt"] = true,
        ["Trial"] = true,
		["Alt"] = true,
		
    }

    for index = 1, totalMembers do
        local fullName, rankName, _, level, _, _, _, _, _, _, class = GetGuildRosterInfo(index)
		local name=Epos:CleanFullPlayerName(fullName)
		        if name and level == maxLevel and allowedRanks[rankName] then
				            -- Only include characters at max level and with allowed ranks
            EposRT.GuildRoster.Players[name] = {
                name = name,
                rank = rankName,
                level = level,
                class = class,
            }
        end
    end
end

function Epos:CleanFullPlayerName(fullName)
    if not fullName then return nil end

    local parts = { strsplit("-", fullName) }
    local name = parts[1]
    local realm = parts[2]

    -- Only use second element as realm if all realms are duplicates
    if #parts > 2 then
        local isDuplicate = true
        for i = 3, #parts do
            if parts[i] ~= realm then
                isDuplicate = false
                break
            end
        end
        if isDuplicate then
            return name .. "-" .. realm
        end
    end

    return fullName -- fallback: return as-is
end

function Epos:RequestData(event, channel, sender, skip)
    skip = skip or false
    Epos:Broadcast(event, {
        event = event,
        data = {
            currencies = EposRT.Crests.Fetch,
            weakauras = EposRT.WeakAuras.Fetch,
            addons = EposRT.AddOns.Fetch
        }
    }, "ALERT", channel, sender)

    if not skip and EposRT.Settings.EnableDataRequestLogging then
        Epos:Msg("Sending Request to GUILD", "Data")
    end
end

function Epos:Msg(msg, prefix)
    prefix = prefix or "General"
    local coloredPrefix = "|cFFFFFF00[" .. prefix .. "]|r"
    print("|cFF78A8FFEpos Raid Tools|r " .. coloredPrefix .. ": " .. msg)
end
function Epos:DBGMsg(msg)
    if EposRT.Settings.Debug then
        print("|cFFFF0000Epos Raid Tools [Debug]|r: " .. msg)
    end
end

function Epos:GetClassColorForPlayer(name)
    local class = EposRT.GuildRoster and EposRT.GuildRoster.Players[name] and EposRT.GuildRoster.Players[name].class
    return RAID_CLASS_COLORS[class or ""] or { r = 1, g = 1, b = 1 }
end

SLASH_EPOS1 = "/epos"
SlashCmdList.EPOS = function(cmd)
    cmd = (cmd or "")
    if cmd:match("^delete%s+(.+)$") then
        local playerName = cmd:match("^delete%s+(.+)$"):trim()
        if playerName and EposRT.GuildRoster.Players[playerName] then
            EposRT.GuildRoster.Players[playerName] = nil
            EposRT.GuildRoster.Database[playerName] = nil
            Epos:Msg(playerName .. " has been removed from the database.")
        else
            Epos:Msg(playerName .. " not found.")
        end
    elseif cmd:match("^dump%s+(.+)$") then
        local playerName = cmd:match("^dump%s+(.+)$"):trim()
        DevTools_Dump(EposRT.GuildRoster.Database[playerName])
        elseif cmd == "show" then
        Epos.EposUI:ToggleMainFrame()

    else
        Epos:Msg("|cff78A8FFusage:|r")
        Epos:Msg("   |cff78A8FF/epos delete <player-realm>|r - Remove a player from the database.")
        Epos:Msg("   |cff78A8FF/epos dump <player-realm>|r - Dump player data from the database.")
        Epos:Msg("   |cff78A8FF/epos show|r - Show the main UI")
    end
end

return Epos
