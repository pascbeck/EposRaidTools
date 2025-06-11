-- ui/addons/AddOns+Options.lua

local _, Epos = ...

-- Cached Globals
local DF = _G.DetailsFramework
local UIParent = _G.UIParent
local CreateFrame = _G.CreateFrame
local table_insert = table.insert
local table_sort = table.sort

-- Local Constants
local PANEL_WIDTH = 485
local PANEL_HEIGHT = 400
local SCROLL_WIDTH = PANEL_WIDTH - 40
local SCROLL_HEIGHT = 300
local ROW_HEIGHT = 40
local VISIBLE_ROWS = 15

local C_AddOns = _G.C_AddOns
local C = Epos.Constants

function BuildAddOnsInterfaceOptions()

    -- Create the Main Panel
    local options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "AddOns Options",
            "AddOnsOptionsFrame",
            { DontRightClickClose = true }
    )
    options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData()
        local data = {}
        for _, addon in pairs(EposRT.AddOns.Fetch) do
            local name = C_AddOns.GetAddOnMetadata(addon, "Title") or addon
            local icon = C_AddOns.GetAddOnMetadata(addon, "IconTexture") or nil
            local id = addon

            table_insert(data, {
                id = id,
                name = name,
                icon = icon,
            })
        end

        -- Sort by id ascending
        table_sort(data, function(a, b)
            return a.id < b.id
        end)

        return data
    end

    local function Refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local addon = data[index]
            if addon then
                local line = self:GetLine(i)

                -- set id for add / remove
                line.id = addon.id

                -- Icon
                line.icon:SetTexture(addon.icon)
                line.icon:Show()

                -- Name
                line.name:SetText(addon.name)
            end
        end
    end

    local function CreateLine (self, index)
        local line = CreateFrame("Frame", "$parentLine"..index, self, "BackdropTemplate")
        line:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -((index - 1) * ROW_HEIGHT) - 1)
        line:SetSize(self:GetWidth() - 2, ROW_HEIGHT)
        DF:ApplyStandardBackdrop(line)

        -- Icon
        line.icon = line:CreateTexture(nil, "ARTWORK")
        line.icon:SetSize(32, 32)
        line.icon:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Name
        line.name = DF:CreateLabel(line, "")
        line.name:SetPoint("LEFT", line.icon, "RIGHT", 8, 0)
        line.name:SetWidth(240)

        -- Delete
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    local addon = line.id
                    if not addon then return end

                    Epos:DeleteAddOn(addon, options_frame)
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
            "$parentaddons_data_scroll_box",
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

    -- Input Area: Add New AddOn Name
    local new_label = DF:CreateLabel(options_frame, "New AddOn:", 11)
    new_label:SetPoint("TOPLEFT", scrollBox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            options_frame,
            function()
                local input = new_entry:GetText():trim()
                if input == "" then return end
                Epos:AddAddOn(input, options_frame)
                new_entry:SetText("")
            end,
            60,
            20,
            "Add",
            nil, nil, nil,
            nil,nil,nil,
            C.templates.button
    )
    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)

    -- Hide Panel by Default
    options_frame:Hide()
    return options_frame
end

function Epos:AddAddOn (input, parent)
    -- Avoid duplicates
    for _, existing in pairs(EposRT.AddOns.Fetch) do
        if existing == input then return end
    end

    -- Validate that this AddOn folder actually exists (via metadata Title)
    local title = C_AddOns.GetAddOnMetadata(input, "Title")
    if not title then return end

    table_insert(EposRT.AddOns.Fetch, input)
    EposRT.AddOns.Current = input

    -- refresh
    local dropdown = EposUI.AddOnsTab.__dropdown
    dropdown:Refresh()
    dropdown:Select(input)
    EposUI.AddOnsTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end

function Epos:DeleteAddOn (addon, parent)
    for i, v in pairs(EposRT.AddOns.Fetch) do
        if v == addon then
            table.remove(EposRT.AddOns.Fetch, i)
            break
        end
    end

    if addon == EposRT.AddOns.Current then
        EposRT.AddOns.Current = EposRT.AddOns.Fetch[1] or nil
    end

    -- refresh
    local dropdown = EposUI.AddOnsTab.__dropdown
    dropdown:Refresh()
    dropdown:Select(EposRT.AddOns.Current)
    EposUI.AddOnsTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end