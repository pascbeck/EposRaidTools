-- EposEvents.lua
local _, Epos = ...
local f = CreateFrame("Frame")

f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("GROUP_FORMED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, e, ...)
  Epos:EventHandler(e, true, false, ...)
end)

function Epos:EventHandler(e, wowevent, internal, ...)
  print(e)

  if e == "ADDON_LOADED" and wowevent then
    local name = ...

    if name == "EposRaidTools" then
      if not EposRT                then EposRT              = {} end
      if not EposRT.EposUI         then EposRT.EposUI       = { scale = 1 } end
      if not EposRT.Settings       then EposRT.Settings     = {} end
      if not EposRT.GuildRoster    then EposRT.GuildRoster  = {} end
      if not EposRT.PlayerDatabase then EposRT.PlayerDatabase = {} end
      if not EposRT.Blacklist      then EposRT.Blacklist    = {} end
      if not EposRT.CrestsOptions  then EposRT.CrestsOptions = {} end

      local AceComm = LibStub("AceComm-3.0", true)
      if AceComm then
        AceComm:RegisterComm("EPOSDATABASE", function(prefix, encoded, distribution, sender)
          local LD = LibStub("LibDeflate", true)
          local LS = LibStub("LibSerialize", true)

          if not LD or not LS then return end
          local decoded = LD:DecodeForWoWAddonChannel(encoded)
          if not decoded then return end
          local decompressed = LD:DecompressDeflate(decoded)
          if not decompressed then return end
          local ok, payload = LS:Deserialize(decompressed)
          if not ok then return end

          Epos:EventHandler("EPOSDATABASE", false, true, payload, sender)
        end)
      end

      EposRT.Settings["Minimap"]                    = EposRT.Settings["Minimap"] or { hide = false }
      EposRT.Settings["VersionCheckRemoveResponse"] = EposRT.Settings["VersionCheckRemoveResponse"] or false

      EposRT.Settings["TrackedRoles"] =
        EposRT.Settings["TrackedRoles"] or {
          ["Guildlead"]   = true,
          ["Officer"]     = true,
          ["Officer Alt"] = false,
          ["Raider"]      = true,
          ["Raid Alt"]    = false,
          ["Trial"]       = false,
        }

      EposRT.CrestsOptions["fetch"] = EposRT.CrestsOptions["fetch"] or { 3114 }
    end

  elseif e == "PLAYER_LOGIN" and wowevent then
    Epos.EposUI:Init()
    Epos:InitLDB()

  elseif e == "GUILD_ROSTER_UPDATE" and wowevent then
    Epos:fetchGuild()

  elseif e == "EPOSDATABASE" and internal then
    local payload, sender = ...

    if sender == "Bluupriest" or sender == "Bluutotem" then
      EposRT.PlayerDatabase[payload.name] = payload
      EposUI.roster_tab:MasterRefresh()
    end
  end
end