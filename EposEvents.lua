-- EposEvents.lua

local _, Epos = ...

-- Cached Blizzard API / Library Functions
local CreateFrame   = _G.CreateFrame
local LibStub       = _G.LibStub

--- Event Frame Setup
-- Create a hidden frame to listen for events
local eventFrame = CreateFrame("Frame")


-- Register all relevant WoW events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("GROUP_FORMED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

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
  -- ADDON_LOADED: Initialize SavedVariables and register AceComm
  if eventName == "ADDON_LOADED" and isWoWEvent then
    local loadedAddon = ...
    if loadedAddon == "EposRaidTools" then
      -- Ensure all SavedVariables tables exist
      EposRT = EposRT or {}
      EposRT.EposUI           = EposRT.EposUI           or { scale = 1 }
      EposRT.Settings         = EposRT.Settings         or {}
      EposRT.GuildRoster      = EposRT.GuildRoster      or {}
      EposRT.PlayerDatabase   = EposRT.PlayerDatabase   or {}
      EposRT.Blacklist        = EposRT.Blacklist        or {}
      EposRT.CrestsOptions    = EposRT.CrestsOptions    or {}
      EposRT.WeakAurasOptions = EposRT.WeakAurasOptions or {}
      EposRT.AddOnsOptions    = EposRT.AddOnsOptions    or {}
      EposRT.SetupsManager    = EposRT.SetupsManager    or {}
      EposRT.enableIntervalFetching = EposRT.enableIntervalFetching or false
      EposRT.fetchInterval = fetchInterval or 0


      -- Register “EPOSDATABASE” communication channel via AceComm (if available)
      local AceComm = LibStub("AceComm-3.0", true)
      if AceComm then
        AceComm:RegisterComm("EPOSDATABASE", function(prefix, encoded, distribution, sender)
          -- We only decode if LibDeflate and LibSerialize are both present
          local LibDeflate   = LibStub("LibDeflate", true)
          local LibSerialize = LibStub("LibSerialize", true)
          if not LibDeflate or not LibSerialize then
            return  -- Cannot decode/deserialize without these libraries
          end

          -- Step 1: Decode from WoW AddOn channel
          local decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
          if not decoded then
            return
          end

          -- Step 2: Decompress the deflated data
          local decompressed = LibDeflate:DecompressDeflate(decoded)
          if not decompressed then
            return
          end

          -- Step 3: Deserialize the Lua table
          local success, payload = LibSerialize:Deserialize(decompressed)
          if not success then
            return
          end

          -- Fire an internal event so we handle it below
          Epos:HandleEvent("EPOSDATABASE", false, true, payload, sender)
        end)
      end

      -- Set default settings if not already present
      EposRT.Settings.Minimap                  = EposRT.Settings.Minimap                  or { hide = false }
      EposRT.Settings.VersionCheckRemoveResponse = EposRT.Settings.VersionCheckRemoveResponse or false
      EposRT.Settings.TrackedRoles             = EposRT.Settings.TrackedRoles             or {
        Guildlead    = true,
        Officer      = true,
        ["Officer Alt"] = false,
        Raider       = true,
        ["Raid Alt"]    = false,
        Trial        = false,
      }

      -- Default crest options
      EposRT.CrestsOptions.fetch = EposRT.CrestsOptions.fetch or { 3107, 3108, 3109, 3110 }
      EposRT.CrestsOptions.show  = EposRT.CrestsOptions.show  or 3110

      -- Default WeakAura options
      EposRT.WeakAurasOptions.fetch = EposRT.WeakAurasOptions.fetch or {
        "Epos Database",
        "Interrupt Anchor",
        "Kaze MRT Timers",
        "Liberation of Undermine",
        "Northern Sky Liberation of Undermine",
        "RaidBuff Reminders",
        "WeakAura Anchors (don't rename these)"
      }
      EposRT.WeakAurasOptions.show  = EposRT.WeakAurasOptions.show  or "Liberation of Undermine"

      -- Default AddOns options
      EposRT.AddOnsOptions.fetch = EposRT.AddOnsOptions.fetch or {
        "MRT",
        "EposRaidTools"
      }
      EposRT.AddOnsOptions.show  = EposRT.AddOnsOptions.show  or "MRT"

      EposRT.SetupsManager.show = EposRT.SetupsManager.show or nil
    end

    -- PLAYER_LOGIN: Initialize UI and DataBroker after the player logs in
  elseif eventName == "PLAYER_LOGIN" and isWoWEvent then
    if Epos.EposUI then
      Epos.EposUI:Init()
    end
    Epos:InitLDB()

    -- GUILD_ROSTER_UPDATE: Refresh the guild roster table
  elseif eventName == "GUILD_ROSTER_UPDATE" and isWoWEvent then
    Epos:FetchGuild()

    -- EPOSDATABASE: Handle incoming player‐database payloads
  elseif eventName == "EPOSDATABASE" and isInternal then
    local payload, sender = ...
    -- Only accept updates from trusted senders
    if sender == "Bluupriest" or sender == "Bluutotem" then
      EposRT.PlayerDatabase[payload.name] = payload
      if EposUI and EposUI.roster_tab then
        EposUI.roster_tab:MasterRefresh()
      end
    end
    elseif eventName == "GROUP_ROSTER_UPDATE" and isWoWEvent then
    print(eventName)
    if self.timer then
      self.timer:Cancel()
    end
    self.timer = C_Timer.NewTimer(0.5,function()
      self.timer = nil
      Epos:ProcessRoster()
    end)
    -- Other events (e.g., ENCOUNTER_START, READY_CHECK, GROUP_FORMED, etc.)
  end
end

return Epos
