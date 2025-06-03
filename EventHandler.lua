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
    if e == "ADDON_LOADED" and wowevent then
        local name = ...
        if name == "EposRaidTools" 	then
			if not EposRT 			then EposRT = {} end
			if not EposRT.EposUI 	then EposRT.EposUI = {scale = 1} end
			if not EposRT.Settings 	then EposRT.Settings = {} end
			if not EposRT.Members 	then EposRT.Members = {} end
			
			
			EposRT.Settings["Minimap"] = EposRT.Settings["Minimap"] or { hide = false }
			EposRT.Settings["VersionCheckRemoveResponse"] = EposRT.Settings["VersionCheckRemoveResponse"] or false
			
			EposRT.Settings["TrackedRoles"] = EposRT.Settings["TrackedRoles"] or {
				["Guildlead"] = true,
				["Officer"] = true,
				["Officer Alt"] = false,
				["Raider"] = true,
				["Raid Alt"] = false,
				["Trial"] = false,
			}

        end
    elseif e == "PLAYER_LOGIN" and wowevent then
        Epos.EposUI:Init()
        Epos:InitLDB()
	elseif e == "GUILD_ROSTER_UPDATE" and wowevent then
		print("fetch guild")
        Epos:fetchGuild()
	end
end