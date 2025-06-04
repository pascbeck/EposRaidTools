-- constants.lua
local _, Epos = ...
local DF = _G["DetailsFramework"]

Epos.Constants = {
    window_width  = 800,
    window_height = 600,
    expressway    = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]],
    templates = {
        text     = DF:GetTemplate("font",     "OPTIONS_FONT_TEMPLATE"),
        dropdown = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
        switch   = DF:GetTemplate("switch",   "OPTIONS_CHECKBOX_TEMPLATE"),
        slider   = DF:GetTemplate("slider",   "OPTIONS_SLIDER_TEMPLATE"),
        button   = DF:GetTemplate("button",   "OPTIONS_BUTTON_TEMPLATE"),
    },
}