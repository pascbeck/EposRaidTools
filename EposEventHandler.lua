-- EposEventHandler.lua

local _, Epos = ...

-- Cached Blizzard API / Library Functions
local CreateFrame = _G.CreateFrame
local LibStub = _G.LibStub

-- Create a hidden frame to listen for events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

-- Set the script handler to route all events through Epos:HandleEvent
eventFrame:SetScript("OnEvent", function(self, eventName, ...)
    -- “true” indicates this is a Blizzard‐fired event; “false” will be passed for internal events
    Epos:HandleEvent(eventName, true, false, ...)
end)

Epos.EventFrame = eventFrame

--- Event Handler
--- Handles both Blizzard‐fired events and internal custom events.
-- @param eventName  (string)   The event identifier (e.g., “ADDON_LOADED”, “EPOSDATABASE”)
-- @param isWoWEvent (boolean)  True if this was fired by WoW’s Event API
-- @param isInternal (boolean)  True if this is a custom/internal event (e.g., “EPOSDATABASE”)
-- @param ...        (various)  Additional payload passed by the event
function Epos:HandleEvent(eventName, isWoWEvent, isInternal, ...)
    if eventName == "ADDON_LOADED" and isWoWEvent then
        local loadedAddon = ...
        if loadedAddon == "EposRaidTools" then
            EposRT = EposRT or {}
            EposRT.EposUI = EposRT.EposUI or { scale = 1 }

            EposRT.GuildRoster = EposRT.GuildRoster or {}
            EposRT.Crests = EposRT.Crests or {}
            EposRT.WeakAuras = EposRT.WeakAuras or {}
            EposRT.AddOns = EposRT.AddOns or {}
            EposRT.Setups = EposRT.Setups or {}
            EposRT.Settings = EposRT.Settings or {}

            -- GuildRoster
            EposRT.GuildRoster.Database = EposRT.GuildRoster.Database or {}
            EposRT.GuildRoster.Players = EposRT.GuildRoster.Players or {}
            EposRT.GuildRoster.Blacklist = EposRT.GuildRoster.Blacklist or {}
            EposRT.GuildRoster.Tracked = EposRT.GuildRoster.Tracked or {
                Guildlead = true,
                Officer = true,
                ["Officer Alt"] = false,
                Raider = true,
                ["Raid Alt"] = false,
                Trial = false,
            }

            -- Crests
            EposRT.Crests.Fetch = EposRT.Crests.Fetch or {
                3107,
                3108,
                3109,
                3110
            }
            EposRT.Crests.Current = EposRT.Crests.Current or 3110

            -- WeakAuras
            EposRT.WeakAuras.Fetch = EposRT.WeakAuras.Fetch or {
                "Epos Database",
                "Interrupt Anchor",
                "Kaze MRT Timers",
                "Liberation of Undermine",
                "Northern Sky Liberation of Undermine",
                "RaidBuff Reminders",
                "WeakAura Anchors (don't rename these)"
            }
            EposRT.WeakAuras.Current = EposRT.WeakAuras.Current or "Epos Database"

            -- AddOns
            EposRT.AddOns.Fetch = EposRT.AddOns.Fetch or {
                "MRT",
                "EposRaidTools"
            }
            EposRT.AddOns.Current = EposRT.AddOns.Current or "MRT"

            -- Setups
            EposRT.Setups.JSON = EposRT.Setups.JSON or {}
            EposRT.Setups.Current = EposRT.Setups.Current or {}
            EposRT.Setups.Current.Setup = EposRT.Setups.Current.Setup or {}
            EposRT.Setups.Current.Boss = EposRT.Setups.Current.Boss or {}

            -- Reset assignments each time
            EposRT.Setups.AssignmentHandler = EposRT.Setups.AssignmentHandler or {}
            EposRT.Setups.AssignmentHandler.needGroup = {}
            EposRT.Setups.AssignmentHandler.needPosInGroup = {}
            EposRT.Setups.AssignmentHandler.lockedUnit = {}
            EposRT.Setups.AssignmentHandler.groupsReady = false
            EposRT.Setups.AssignmentHandler.groupWithRL = nil

            -- RegisterComm
            Epos:RegisterComm()
        end


    elseif eventName == "PLAYER_LOGIN" and isWoWEvent then
        if Epos.EposUI then
            Epos.EposUI:Init()
        end
        Epos:InitLDB()


    elseif eventName == "GUILD_ROSTER_UPDATE" and isWoWEvent then
        Epos:FetchGuild()


    elseif eventName == "GROUP_ROSTER_UPDATE" and isWoWEvent then

    elseif eventName == "EPOSDATABASE" and isInternal then
        local payload, sender = ...
        if sender == "Bluupriest" or sender == "Bluutotem" then
            -- store db entry
            EposRT.GuildRoster.Database[payload.name] = payload

            -- refresh tabs
            EposUI.DatabaseTab:MasterRefresh()
            EposUI.CrestsTab:MasterRefresh()
            EposUI.WeakAurasTab:MasterRefresh()
            EposUI.AddOnsTab:MasterRefresh()
        end

    end
end

function Epos:RegisterComm()
    local AceComm = LibStub("AceComm-3.0", true)
    if AceComm then
        AceComm:RegisterComm("EPOSDATABASE", function(prefix, encoded, distribution, sender)
            local LibDeflate = LibStub("LibDeflate", true)
            local LibSerialize = LibStub("LibSerialize", true)
            if not (LibDeflate and LibSerialize) then
                return
            end

            local decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
            if not decoded then
                return
            end

            local decompressed = LibDeflate:DecompressDeflate(decoded)
            if not decompressed then
                return
            end

            local success, payload = LibSerialize:Deserialize(decompressed)
            if not success then
                return
            end

            -- route the payload into your existing handler
            Epos:HandleEvent("EPOSDATABASE", false, true, payload, sender)
        end)
    end
end