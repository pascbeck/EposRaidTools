-- ui/crests/Crests+Options.lua

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

local C_CurrencyInfo = _G.C_CurrencyInfo
local C = Epos.Constants

function BuildCrestsInterfaceOptions()

    -- Create the Main Panel
    local options_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "Crests Options",
            "CrestsOptionsFrame",
            { DontRightClickClose = true }
    )
    options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local function PrepareData()
        local data = {}
        for _, id in pairs(EposRT.Crests.Fetch) do
            local currency = C_CurrencyInfo.GetCurrencyInfo(id)
            local name = currency and currency.name or id
            local icon = currency and currency.iconFileID or id

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
            local currency = data[index]
            if currency then
                local line = self:GetLine(i)

                -- to add / remove currency
                line.id = currency.id

                -- Icon
                line.icon:SetTexture(currency.icon)
                line.icon:Show()

                -- Name
                line.name:SetText(currency.name)
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
                    local currency = line.id
                    if not currency then return end

                    Epos:DeleteCurrency(currency, options_frame, line)
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
            "$parentcrests_data_scroll_box",
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

    -- Input Area: Add New Crest Name
    local new_label = DF:CreateLabel(options_frame, "New Crest:", 11)
    new_label:SetPoint("TOPLEFT", scrollBox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            options_frame,
            function()
                local text = new_entry:GetText():trim()
                local id = tonumber(text)
                if not id then return end

                Epos:AddCurrency(id, options_frame)
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

function Epos:AddCurrency (id, parent)
    -- Avoid duplicates
    for _, existing in pairs(EposRT.Crests.Fetch) do
        if existing == id then return end
    end

    local data = C_CurrencyInfo.GetCurrencyInfo(id)
    if not data then return end

    table_insert(EposRT.Crests.Fetch, id)
    EposRT.Crests.Current = id

    local currencyLink = C_CurrencyInfo.GetCurrencyLink(id)
    Epos:Msg("Added " .. currencyLink .. " to crests")

    -- refresh
    local dropdown = EposUI.CrestsTab.__dropdown
    dropdown:Refresh()
    dropdown:Select(id)
    EposUI.CrestsTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end

function Epos:DeleteCurrency (currency, parent, line)
    for i, v in pairs(EposRT.Crests.Fetch) do
        if v == currency then
            table.remove(EposRT.Crests.Fetch, i)
            break
        end
    end

    local data = C_CurrencyInfo.GetCurrencyInfo(currency)
    if not data then return end

    if currency == EposRT.Crests.Current then
        EposRT.Crests.Current = EposRT.Crests.Fetch[1] or nil
    end

    local currencyLink = C_CurrencyInfo.GetCurrencyLink(currency)
    Epos:Msg("Removed " .. currencyLink .. " from crests")

    -- refresh
    local dropdown = EposUI.CrestsTab.__dropdown
    dropdown:Refresh()
    dropdown:Select(EposRT.Crests.Current)
    EposUI.CrestsTab:MasterRefresh()
    parent.scrollbox:MasterRefresh()
end