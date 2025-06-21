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
eventFrame:RegisterEvent("GROUP_FORMED")
eventFrame:RegisterEvent("READY_CHECK")

-- Set the script handler to route all events through Epos:HandleEvent
eventFrame:SetScript("OnEvent", function(self, eventName, ...)
    -- “true” indicates this is a Blizzard‐fired event; “false” will be passed for internal events
    Epos:HandleEvent(eventName, true, false, ...)
    if EposRT.Settings.EnableEventLogging then
        Epos:Msg(eventName)
    end
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

            -- Settings
            EposRT.Settings.Minimap = EposRT.Settings.Minimap or { hide = false }
            EposRT.Settings.FrameStrata = EposRT.Settings.FrameStrata or "HIGH"
            EposRT.Settings.Transparency = EposRT.Settings.Transparency or false
            EposRT.Settings.HideStatusBar = EposRT.Settings.HideStatusBar or false
            EposRT.Settings.AnnouncementChannel = EposRT.Settings.AnnouncementChannel or "RAID"
            EposRT.Settings.AnnounceBenchedPlayers = EposRT.Settings.AnnounceBenchedPlayers == nil and true or EposRT.Settings.AnnounceBenchedPlayers
            EposRT.Settings.AnnounceUnBenchedPlayers = EposRT.Settings.AnnounceUnBenchedPlayers == nil and true or EposRT.Settings.AnnounceUnBenchedPlayers

            EposRT.Settings.EnableEventLogging = EposRT.Settings.EnableEventLogging or false
            EposRT.Settings.EnableDataRequestOnLoginEvent = EposRT.Settings.EnableDataRequestOnLoginEvent == nil and true or EposRT.Settings.EnableDataRequestOnLoginEvent
            EposRT.Settings.EnableDataReceiveLogging = EposRT.Settings.EnableDataReceiveLogging == nil and true or EposRT.Settings.EnableDataReceiveLogging
            EposRT.Settings.EnableDataRequestLogging = EposRT.Settings.EnableDataRequestLogging == nil and true or EposRT.Settings.EnableDataRequestLogging
            EposRT.Settings.Debug = EposRT.Settings.Debug or false

            EposRT.Settings.ShowMismatchLogs = EposRT.Settings.ShowMismatchLogs == nil and true or EposRT.Settings.ShowMismatchLogs
            EposRT.Settings.CompareNotes = EposRT.Settings.CompareNotes == nil and true or EposRT.Settings.CompareNotes


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
                Trial = true,
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
                "NorthernSkyRaidTools",
                "Details",
                "EposRaidTools",
            }
            EposRT.AddOns.Current = EposRT.AddOns.Current or "MRT"

            -- Setups
            EposRT.Setups.JSON = EposRT.Setups.JSON or {}

            EposRT.Setups.Current = EposRT.Setups.Current or {}
            EposRT.Setups.Current.Setup = EposRT.Setups.Current.Setup or {}
            EposRT.Setups.Current.Boss = EposRT.Setups.Current.Boss or {}

            EposRT.Setups.Old = EposRT.Setups.Old or {}
            EposRT.Setups.Old.Setup = EposRT.Setups.Old.Setup or {}
            EposRT.Setups.Old.Boss = EposRT.Setups.Old.Boss or {}

            -- Reset assignments each time
            EposRT.Setups.AssignmentHandler = EposRT.Setups.AssignmentHandler or {}
            EposRT.Setups.AssignmentHandler.needGroup = {}
            EposRT.Setups.AssignmentHandler.needPosInGroup = {}
            EposRT.Setups.AssignmentHandler.lockedUnit = {}
            EposRT.Setups.AssignmentHandler.groupsReady = false
            EposRT.Setups.AssignmentHandler.groupWithRL = nil

            EposRT.readyCheckNotes = {}
            EposRT.readyCheckStarted = false
            EposRT.readyCheckExpected = {}
            EposRT.readyCheckEvaluated = false
        end


    elseif eventName == "PLAYER_LOGIN" and isWoWEvent then
        if Epos.EposUI then
            Epos.EposUI:Init()
        end
        Epos:InitLDB()


    elseif eventName == "GUILD_ROSTER_UPDATE" and isWoWEvent then
        Epos:FetchGuild()


    elseif eventName == "GROUP_ROSTER_UPDATE" and isWoWEvent then
        if self.timer then
            self.timer:Cancel()
        end
        self.timer = C_Timer.NewTimer(0.5,function()
            self.timer = nil
            Epos:ProcessRoster()
        end)

    elseif eventName == "GROUP_FORMED" and isWoWEvent then
        EposRT.Setups.Old.Setup = {}

    elseif eventName == "READY_CHECK" and isWoWEvent then
        if not EposRT.Settings.CompareNotes then return end

        EposRT.readyCheckEvaluated = false

        local sender, duration = ...

        local difficulty = GetRaidDifficultyID()
        local maxSubgroup = (difficulty == 16) and 4 or 8

        EposRT.readyCheckNotes = {}
        EposRT.readyCheckStarted = true
        EposRT.readyCheckExpected = {}

        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if subgroup and subgroup <= maxSubgroup then
                local fullName = name:find("-") and name or name .. "-" .. GetRealmName()
                if EposRT.GuildRoster.Database[fullName] then
                    EposRT.readyCheckExpected[fullName] = true
                    Epos:Broadcast("EPOS_NOTE_CHECK", payload, "ALERT", "WHISPER", fullName)
                else
                    if EposRT.Settings.Debug then
                        Epos:DBGMsg("Skipping note request for " .. fullName .. " — no Database installed.")
                    end
                end
            end
        end

        if EposRT.readyCheckTimer then
            EposRT.readyCheckTimer:Cancel()
        end

        EposRT.readyCheckTimer = C_Timer.NewTimer(10, function()
            Epos:EvaluateNotes()
        end)

    elseif eventName == "EPOS_MSG" and isInternal then
        local payload, sender = ...

        -- ask data on player login
        if payload.event == "PLAYER_ENTERING_WORLD" then
            if not EposRT.GuildRoster.Players[payload.data.name] then
                return
            end
            if EposRT.Settings.EnableDataRequestOnLoginEvent then
                local playerName = payload.data.name
                local classColor = Epos:GetClassColorForPlayer(playerName)
                Epos:RequestData("EPOS_REQUEST", "WHISPER", sender, true)

                if EposRT.Settings.EnableDataRequestLogging then
                    Epos:Msg(string.format("Sending Request to |cff%02x%02x%02x%s|r",
                            classColor.r * 255, classColor.g * 255, classColor.b * 255, playerName), "Data")
                end
            end

        -- received data
        elseif payload.event == "EPOS_DATA" then
            if EposRT.Settings.EnableDataReceiveLogging then
                local playerName = payload.data.name
                local classColor = Epos:GetClassColorForPlayer(playerName)

                if not EposRT.GuildRoster.Players[playerName] then
                    return
                end

                Epos:Msg(string.format("Received from |cff%02x%02x%02x%s|r",
                        classColor.r * 255, classColor.g * 255, classColor.b * 255, playerName), "Data")
            end
            EposRT.GuildRoster.Database[payload.data.name] = payload.data

            EposUI.DatabaseTab:MasterRefresh()
            EposUI.CrestsTab:MasterRefresh()
            EposUI.WeakAurasTab:MasterRefresh()
            EposUI.AddOnsTab:MasterRefresh()

        elseif payload.event == "EPOS_SEND_NOTE" then
            if not EposRT.Settings.CompareNotes then return end

            local name = payload.data.name
            EposRT.readyCheckNotes[name] = payload.data.note

            -- Count how many players we expect
            local expected = 0
            local difficulty = GetRaidDifficultyID()
            local maxSubgroup = (difficulty == 16) and 4 or 8
            for i = 1, GetNumGroupMembers() do
                local _, _, subgroup = GetRaidRosterInfo(i)
                if subgroup and subgroup <= maxSubgroup then
                    expected = expected + 1
                end
            end

            local current = 0
            for _ in pairs(EposRT.readyCheckNotes) do
                current = current + 1
            end

            -- Check if we’ve received all the notes we were expecting
            local received = 0
            for name in pairs(EposRT.readyCheckNotes) do
                if EposRT.readyCheckExpected[name] then
                    received = received + 1
                end
            end

            local expected = 0
            for _ in pairs(EposRT.readyCheckExpected) do
                expected = expected + 1
            end

            if received >= expected then
                Epos:EvaluateNotes()
                EposRT.readyCheckNotes = {}
            end
        end
    end

end



function Epos:EvaluateNotes()
    if EposRT.readyCheckEvaluated then
        return
    end

    EposRT.readyCheckEvaluated = true

    local notes = EposRT.readyCheckNotes or {}
    local timestampCounts = {}

    -- Count frequency of each lastUpdateTime
    for _, note in pairs(notes) do
        local ts = note.lastUpdateTime or 0
        timestampCounts[ts] = (timestampCounts[ts] or 0) + 1
    end

    -- Find the most common timestamp
    local mostCommonTs, maxCount = nil, 0
    for ts, count in pairs(timestampCounts) do
        if count > maxCount then
            mostCommonTs = ts
            maxCount = count
        end
    end

    if not mostCommonTs then
        return
    end

    local TIME_TOLERANCE = 60  -- seconds

    -- Find matching note text based on timestamps within tolerance
    local correctText
    for _, note in pairs(notes) do
        if math.abs(note.lastUpdateTime - mostCommonTs) <= TIME_TOLERANCE then
            correctText = note.text
            break
        end
    end

    -- Mismatch detection
    local mismatchedPlayers = {}
    local receivedCount = 0

    for playerName, note in pairs(notes) do
        receivedCount = receivedCount + 1

        local tsMatch = math.abs(note.lastUpdateTime - mostCommonTs) <= TIME_TOLERANCE
        local textMatch = note.text == correctText

        if not (tsMatch and textMatch) then
            table.insert(mismatchedPlayers, playerName)
        end
    end

    local totalRaidMembers = 0
    local difficulty = GetRaidDifficultyID()
    local maxSubgroup = (difficulty == 16) and 4 or 8

    for i = 1, GetNumGroupMembers() do
        local _, _, subgroup = GetRaidRosterInfo(i)
        if subgroup and subgroup <= maxSubgroup then
            totalRaidMembers = totalRaidMembers + 1
        end
    end

    if EposRT.Settings.ShowMismatchLogs then
        Epos:Msg(string.format("Received Notes: %d/%d", receivedCount, totalRaidMembers), "Notes")
    end

    if #mismatchedPlayers > 0 then
        Epos:ShowNoteResultText(false, mismatchedPlayers)
    else
        Epos:ShowNoteResultText(true)
    end

    -- Optional: reset notes here if not waiting for READY_CHECK_FINISHED
end

local EXPRESSWAY_FONT_PATH = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]]

function Epos:ShowNoteResultText(success, mismatches)
    local frame = RaidWarningFrame
    local icon = "|TInterface\\AddOns\\EposRaidTools\\Media\\EposLogo:16|t"
    local prefix = "|cFF78A8FFEpos Raid Tools|r"
    local message

    if success then
        return
    else
        message = icon .. " " .. prefix .. " |cffff4444Note Mismatch|r"
        RaidNotice_AddMessage(frame, message, ChatTypeInfo["RAID_WARNING"])
        PlaySound(SOUNDKIT.RAID_WARNING)

        if EposRT.Settings.ShowMismatchLogs then
        -- Print mismatched players in class colors in chat frame, each on own line with dash prefix
            Epos:Msg("|cffff4444Outdated Notes:|r", "Notes")
            for _, playerName in ipairs(mismatches) do
                local classColor = Epos:GetClassColorForPlayer(playerName) or {r=1,g=1,b=1}
                local colorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
                print("     - " .. colorCode .. playerName .. "|r")
            end
        end
    end

    -- Override the font with Expressway
    local fontSize = 20
    local fontFlags = "OUTLINE"

    frame.slot1:SetFont(EXPRESSWAY_FONT_PATH, fontSize, fontFlags)
    frame.slot2:SetFont(EXPRESSWAY_FONT_PATH, fontSize, fontFlags)
end

