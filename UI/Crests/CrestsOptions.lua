local _, Epos = ...
local DF  = _G["DetailsFramework"]

function BuildCrestsOptions()

    local crests_options_modal = DF:CreateSimplePanel(
        UIParent, 485, 420,
        "Roles Management", "RolesEditFrame",
        { DontRightClickClose = true }
    )
    crests_options_modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    currencyNameLabel = DF:CreateLabel(crests_options_modal, "", 9, "cyan")
    currencyNameLabel:SetPoint("topleft", crests_options_modal, "topleft", 10, -70)

    currencyIconTexture = DF:CreateTexture(crests_options_modal)
    currencyIconTexture:SetSize(24, 24)  -- force small size
    currencyIconTexture:SetPoint("left", currencyNameLabel, "right", 4, -1)  -- align with text
    currencyIconTexture:SetTexCoord(0.075, 0.925, 0.075, 0.925)  -- crop padding
    currencyIconTexture:Hide()


    local info = C_CurrencyInfo.GetCurrencyInfo(EposRT.CrestsOptions["fetch"])
    currencyNameLabel.label:SetText(info and info.name or "Invalid ID")

    if info and info.iconFileID then
        currencyIconTexture:SetTexture(info.iconFileID)
        currencyIconTexture:Show()
    else
        currencyIconTexture:Hide()
    end

    local options = {
        {
            type          = "label",
            get           = function() return "Fetch Options" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "textentry",
            name = "Crest Unique Identifier",
            desc = [[Enter any currency identifier to fetch for the database

Press 'Enter' to set the identifier]],
            get = function()
                return EposRT.CrestsOptions["fetch"]
            end,
            set = function(self, _, value) end,
            hooks = {
                OnEnterPressed = function(self)
                    local text = self:GetText()
                    -- try to convert to a number (if you expect numeric IDs)
                    local id = tonumber(text)
                    if not id then
                        print("Invalid crest ID. Please enter a number.")
                        return
                    end

                    print("enter")
                    print(currencyNameLabel)
                    -- store in your table (you can choose any value; here we just mark true)
                    EposRT.CrestsOptions["fetch"] = id

                    -- clear focus so the user sees that input is accepted
                    self:ClearFocus()


                    local info = C_CurrencyInfo.GetCurrencyInfo(id)
                    currencyNameLabel.label:SetText(info and info.name or "Invalid ID")

                    if info and info.iconFileID then
                        currencyIconTexture:SetTexture(info.iconFileID)

                        currencyIconTexture:Show()
                    else
                        currencyIconTexture:Hide()
                    end

                end,
            },
        },
        {
            type            = "break"
        },
        {
            type            = "break"
        },
        {
            type          = "label",
            get           = function() return "General Options" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide empty or outdated entries",
            desc = "Hide players without valid database entry (no entry at all, wrong crest id)",
            get = function() return EposRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                EposRT.Settings["Minimap"].hide = value
            end,
        },
    }

    DF:BuildMenu(
        crests_options_modal,
        options,
        10, -30,  -- x, y offset
        380, false,
        DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"),
        DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
        DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"),
        true,
        DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE"),
        DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"),
        nil
    )

    crests_options_modal:Hide()
    return crests_options_modal
end