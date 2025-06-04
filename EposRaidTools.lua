-- EposRaidTools.lua
local _, Epos = ...
_G["EPOSAPI"] = {}

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

function Epos:fetchGuild()
    EposRT.GuildRoster = {}  -- clear existing roster

    local maxLevel = GetMaxLevelForLatestExpansion()
    for i = 1, GetNumGuildMembers() do
        local fullName, rank, _, level, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
        if level == maxLevel then
            table.insert(EposRT.GuildRoster, {
                name  = fullName,
                rank  = rank,
                level = level,
                class = classFile,
            })
        end
    end
end

function Epos:InitLDB()
    if not LDB then
        return
    end

    local databroker = LDB:NewDataObject("EposRT", {
        type                = "launcher",
        label               = "Epos Raid Tools",
        icon                = [[Interface\AddOns\EposRaidTools\Media\EposLogo]],
        showInCompartment   = true,
        OnClick = function(self, button)
            if button == "LeftButton" then
                Epos.EposUI:ToggleMainFrame()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Epos Raid Tools", 0, 1, 1)
            tooltip:AddLine("|cFFCFCFCFLeft click|r: Show/Hide Options Window")
        end,
    })

    if databroker and not LDBIcon:IsRegistered("EposRT") then
        LDBIcon:Register("EposRT", databroker, EposRT.Settings["Minimap"])
        LDBIcon:AddButtonToCompartment("EposRT")
    end

    Epos.databroker = databroker
end