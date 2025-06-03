-- constants.lua
local _, Epos = ...
local DF  = _G["DetailsFramework"]

Epos.Constants = {
    window_width  = 800,
    window_height = 600,
    expressway    = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]],
    templates = {
        text     = _G["DetailsFramework"]:GetTemplate("font",   "OPTIONS_FONT_TEMPLATE"),
        dropdown = _G["DetailsFramework"]:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
        switch   = _G["DetailsFramework"]:GetTemplate("switch",   "OPTIONS_CHECKBOX_TEMPLATE"),
        slider   = _G["DetailsFramework"]:GetTemplate("slider",   "OPTIONS_SLIDER_TEMPLATE"),
        button   = _G["DetailsFramework"]:GetTemplate("button",   "OPTIONS_BUTTON_TEMPLATE"),
    },
}