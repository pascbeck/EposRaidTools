-- interface/setups/Setups+Handler.lua

local _, Epos = ...

function Epos:ResetSetupSavedVariables ()
    EposRT.Setups.AssignmentHandler.needGroup = {}
    EposRT.Setups.AssignmentHandler.needPosInGroup = {}
    EposRT.Setups.AssignmentHandler.lockedUnit = {}
    EposRT.Setups.AssignmentHandler.groupsReady = false
    EposRT.Setups.AssignmentHandler.groupWithRL = nil
end

function Epos:ApplyGroups (list)
    Epos:ResetSetupSavedVariables()
    Epos.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    if not IsInRaid() then
        Epos:Msg("Cannot be used outside raid environment")
        return
    end

    local inCombatUnits
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitAffectingCombat(unit) then
            inCombatUnits = (inCombatUnits and (inCombatUnits .. ",")) or ""
            inCombatUnits = inCombatUnits .. UnitName(unit)
        end
    end

    if inCombatUnits then
        Epos:Msg("|cffff0000" .. ERROR_CAPS .. ".|r " .. L.RaidGroupsPlayersInCombat .. ": " .. inCombatUnits)
        return
    end

    local needGroup = {}
    local needPosInGroup = {}
    local lockedUnit = {}

    local RLName, _, RLGroup = GetRaidRosterInfo(1)
    local isRLfound = false

    for i = 1, 8 do
        local pos = 1
        for j = 1, 5 do
            local name = list[(i - 1) * 5 + j]
            if name == RLName then
                needGroup[name] = i
                needPosInGroup[name] = pos
                pos = pos + 1
                isRLfound = true
                break
            end
        end
        for j = 1, 5 do
            local name = list[(i - 1) * 5 + j]
            if name and name ~= RLName and UnitName(name) then
                needGroup[name] = i
                needPosInGroup[name] = pos
                pos = pos + 1
            end
        end
    end

    local s = EposRT.Setups.AssignmentHandler
    s.needGroup = needGroup
    s.needPosInGroup = needPosInGroup
    s.lockedUnit = lockedUnit
    s.groupsReady = false
    s.groupWithRL = isRLfound and 0 or RLGroup
    Epos:ProcessRoster()
end

function Epos:ProcessRoster ()
    local s = EposRT.Setups.AssignmentHandler

    local UnitsInCombat
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitAffectingCombat(unit) then
            UnitsInCombat = (UnitsInCombat or "") .. (UnitsInCombat and "," or "") .. UnitName(unit)
        end
    end
    if UnitsInCombat then
        Epos:Msg("|cffff0000" .. ERROR_CAPS .. ".|r " .. L.RaidGroupsCombatStarted .. ": " .. UnitsInCombat)

        s.needGroup = nil

        Epos.EventFrame:UnregisterEvent('GROUP_ROSTER_UPDATE')
        return
    end

    local needGroup = s.needGroup
    local needPosInGroup = s.needPosInGroup
    local lockedUnit = s.lockedUnit
    if not needGroup then
        return
    end

    Epos.EventFrame:RegisterEvent('GROUP_ROSTER_UPDATE')

    local currentGroup = {}
    local currentPos = {}
    local nameToID = {}
    local groupSize = {}

    wipe(currentGroup)
    for i = 1, 8 do
        groupSize[i] = 0
    end
    for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup = GetRaidRosterInfo(i)
        if not needGroup[name] and name:find("%-") and needGroup[strsplit("-", name)] then
            name = strsplit("-", name)
        end
        currentGroup[name] = subgroup
        nameToID[name] = i
        groupSize[subgroup] = groupSize[subgroup] + 1
        currentPos[name] = groupSize[subgroup]
    end

    if not s.groupsReady then
        local WaitForGroup = false
        for unit, group in pairs(needGroup) do
            if currentGroup[unit] and currentGroup[unit] ~= needGroup[unit] then
                local currGroupUnit = currentGroup[unit]
                local needGroupUnit = needGroup[unit]
                if groupSize[needGroupUnit] < 5 then
                    SetRaidSubgroup(nameToID[unit], needGroupUnit)

                    groupSize[currGroupUnit] = groupSize[currGroupUnit] - 1
                    groupSize[needGroupUnit] = groupSize[needGroupUnit] + 1

                    WaitForGroup = true
                end
            end
        end
        if WaitForGroup then
            return
        end

        local SetToSwap = {}
        local WaitForSwap = false
        for unit, group in pairs(needGroup) do
            if not SetToSwap[unit] and currentGroup[unit] and currentGroup[unit] ~= group then
                local currGroupUnit = currentGroup[unit]

                local unitToSwap
                for unit2, group2 in pairs(currentGroup) do
                    if not SetToSwap[unit2] and group2 == group and needGroup[unit2] ~= group2 then
                        unitToSwap = unit2
                        break
                    end
                end

                if unitToSwap then
                    SwapRaidSubgroup(nameToID[unit], nameToID[unitToSwap])

                    WaitForSwap = true
                    SetToSwap[unit] = true
                    SetToSwap[unitToSwap] = true
                end
            end
        end
        if WaitForSwap then
            return
        end

        s.groupsReady = true
    end

    do
        local SetToSwap = {}
        local WaitForSwap = false
        for unit, pos in pairs(needPosInGroup) do
            if currentGroup[unit] == s.groupWithRL then
                pos = pos + 1
            end
            if not lockedUnit[unit] and currentPos[unit] and currentPos[unit] ~= pos and nameToID[unit] ~= 1 and not SetToSwap[unit] then
                local currGroupUnit = currentGroup[unit]

                local unitToSwapBridge
                for unit2, group2 in pairs(currentGroup) do
                    if group2 ~= currentGroup[unit] and nameToID[unit2] ~= 1 and not SetToSwap[unit2] then
                        unitToSwapBridge = unit2
                        break
                    end
                end

                local unitToSwap
                for unit2, pos2 in pairs(currentPos) do
                    if currentGroup[unit2] == currentGroup[unit] and pos2 == pos and nameToID[unit2] ~= 1 and not SetToSwap[unit2] then
                        unitToSwap = unit2
                        break
                    end
                end

                if unitToSwap and unitToSwapBridge then
                    lockedUnit[unit] = true
                    SwapRaidSubgroup(nameToID[unit], nameToID[unitToSwapBridge])
                    SwapRaidSubgroup(nameToID[unitToSwapBridge], nameToID[unitToSwap])
                    SwapRaidSubgroup(nameToID[unit], nameToID[unitToSwapBridge])

                    WaitForSwap = true
                    SetToSwap[unit] = true
                    SetToSwap[unitToSwap] = true
                    SetToSwap[unitToSwapBridge] = true
                end
            end
        end
        if WaitForSwap then
            return
        end
    end

    s.needGroup = nil

    if EposRT.Settings.AnnounceBenchedPlayers then
        local index = EposRT.Setups.Current.Boss:match("^(%d+)")
        local _, _, _, _, link = EJ_GetEncounterInfoByIndex(index, 1296)
        local displayText

        if EposRT.Settings.AnnouncementChannel == "WHISPER" then
            displayText = "You are benched for: " .. link
            for _, bench in pairs(EposRT.Setups.Current.Setup.benched) do
                print(bench)
                SendChatMessage(displayText, "WHISPER", nil, bench)
            end
        else
            local benchNames = {}
            for _, bench in pairs(EposRT.Setups.Current.Setup.benched) do
                table.insert(benchNames, bench)
            end
            local benchList = table.concat(benchNames, ", ")
            displayText = "The following players are benched for: " .. link .. " - " .. benchList
            SendChatMessage(displayText, EposRT.Settings.AnnouncementChannel)
        end
    end

    Epos:Msg("Applied Setup for " .. EposRT.Setups.Current.Boss)
    Epos.EventFrame:UnregisterEvent('GROUP_ROSTER_UPDATE')
end