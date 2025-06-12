-- ui/database/Database+Options.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local UIParent = _G.UIParent
local CreateFrame = _G.CreateFrame
local table_insert = table.insert
local table_sort = table.sort
local strfind = _G.strfind
local GetRealmName = _G.GetRealmName

local C = Epos.Constants

-- Local Constants
local PANEL_WIDTH = 485
local PANEL_HEIGHT = 400
local SCROLL_WIDTH = PANEL_WIDTH - 40
local SCROLL_HEIGHT = 300
local ROW_HEIGHT = C.tabs.lineHeight
local VISIBLE_ROWS = 15

function BuildDatabaseInterfaceOptions()

    -- Create the Main Panel
    local options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "Database Options",
            "DatabaseOptionsFrame",
            { DontRightClickClose = true }
    )
    options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local options = {}
    options[#options + 1] = {
        type = "label",
        get = function()
            return "Track Guild Ranks"
        end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }

    -- Toggles for each rank
    for _, rankName in pairs(C.guildRanks) do
        options[#options + 1] = {
            type = "toggle",
            boxfirst = true,
            name = rankName,
            desc = "Enable or disable tracking for " .. rankName,
            get = function()
                return EposRT.GuildRoster.Tracked[rankName]
            end,
            set = function(_, _, value)
                EposRT.GuildRoster.Tracked[rankName] = value
                Epos:Msg((value and "Enabled " or "Disabled ") .. "'" .. rankName .. "'" .. " rank for data requests")
                -- refresh
                EposUI.DatabaseTab:MasterRefresh()
                EposUI.CrestsTab:MasterRefresh()
                EposUI.WeakAurasTab:MasterRefresh()
                EposUI.AddOnsTab:MasterRefresh()
            end,
            nocombat = true,
        }
    end

    options[#options + 1] = { type = "break" }
    options[#options + 1] = {
        type = "label",
        get = function()
            return "Blacklist & Whitelist"
        end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }

    -- Button: Edit Blacklist
    options[#options + 1] = {
        type = "execute",
        name = "Edit Blacklist",
        desc = "Manually add players to the tracking blacklist",
        func = function()
            EposUI.DatabaseTabOptions:Hide()
            EposUI.DatabaseTabOptionsBlacklist:Show()
        end,
    }

    -- Build the Menu Using Constants for Templates
    DF:BuildMenu(
            options_frame,
            options,
            10,
            -30,
            380,
            false,
            C.templates.text,
            C.templates.dropdown,
            C.templates.switch,
            true,
            C.templates.slider,
            C.templates.button,
            nil
    )

    -- Initially hide the frame; shown when user clicks “Roles Management”
    options_frame:Hide()

    return options_frame
end

function BuildDatabaseInterfaceOptionsBlacklist()
    -- Create the Main Panel
    local options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "Database Blacklist Options",
            "DatabaseBlacklistOptionsFrame",
            { DontRightClickClose = true }
    )
    options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData()
        local data = {}
        for name in pairs(EposRT.GuildRoster.Blacklist) do
            table_insert(data, { name = name })
        end
        table_sort(data, function(a, b)
            return a.name < b.name
        end)

        return data
    end

    local function Refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local player = data[index]
            if player then
                local line = self:GetLine(i)
                line.name:SetText(player.name)
                line.name:SetTextColor(Epos:GetClassColorForPlayer(player.name))
                line.id = player.name
            end
        end
    end

    local function CreateLine (self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * ROW_HEIGHT) - 1)
        line:SetSize(self:GetWidth() - 2, ROW_HEIGHT)
        DF:ApplyStandardBackdrop(line)

        -- Name
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Delete
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    local name = line.id
                    if not name then
                        return
                    end

                    Epos:DeleteBlacklistEntry(name, options_frame)
                end,
                12,
                12
        )
        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData({})
        self:SetData(data)
        self:Refresh()
    end

    -- ScrollBox Setup
    local scrollBox = DF:CreateScrollBox(
            options_frame,
            "$parentdatabase_options_data_scroll_box",
            Refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            CreateLine
    )
    options_frame.scrollbox = scrollBox
    scrollBox.MasterRefresh = MasterRefresh
    scrollBox.ReajustNumFrames = true
    DF:ReskinSlider(scrollBox)
    scrollBox:SetPoint("TOPLEFT", options_frame, "TOPLEFT", 10, -50)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        scrollBox:CreateLine(CreateLine)
    end

    -- Refresh when the panel is shown
    scrollBox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    -- Input Area: Add New Blacklist Name
    local new_label = DF:CreateLabel(options_frame, "New Player:", 11)
    new_label:SetPoint("TOPLEFT", scrollBox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(options_frame, function()
    end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            options_frame,
            function()
                local input = new_entry:GetText():trim()
                if input == "" then
                    return
                end
                Epos:AddBlacklistEntry(input, options_frame)
                new_entry:SetText("")
            end,
            60,
            20,
            "Add",
            nil, nil, nil,
            nil, nil, nil,
            C.templates.button
    )
    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)

    -- Hide Panel by Default
    options_frame:Hide()
    return options_frame
end

function Epos:AddBlacklistEntry(name, parent)
    local name = name
    if not strfind(name, "%-") then
        local realm = GetRealmName():gsub("%s+", "")
        name = name .. "-" .. realm
    end

    local guildEntry = EposRT.GuildRoster.Players[name]
    if not guildEntry then
        return
    end

    EposRT.GuildRoster.Blacklist[name] = true

    -- Get the player's class color
    local classColor = RAID_CLASS_COLORS[guildEntry.class] or { r = 1, g = 1, b = 1 } -- default to white if no class is found
    local classColorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)

    -- Send the message with class color for name
    Epos:Msg("Added " .. classColorCode .. name .. "|r to Blacklist")

    EposUI.DatabaseTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end

function Epos:DeleteBlacklistEntry(name, parent)
    local guildEntry = EposRT.GuildRoster.Players[name]
    if not guildEntry then
        return
    end

    -- Get the player's class color
    local classColor = RAID_CLASS_COLORS[guildEntry.class] or { r = 1, g = 1, b = 1 } -- default to white if no class is found
    local classColorCode = string.format("|cff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)

    EposRT.GuildRoster.Blacklist[name] = nil

    -- Send the message with class color for name
    Epos:Msg("Removed " .. classColorCode .. name .. "|r from Blacklist")

    parent.scrollbox:MasterRefresh()
    EposUI.DatabaseTab:MasterRefresh()
end