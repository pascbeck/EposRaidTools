-- constants.lua
local _, Epos = ...
local DF = _G["DetailsFramework"]

local window_width  = 800
local window_height = 600
local lineHeight    = 20
local totalHeight   = window_height - 180
local visibleRows   = math.floor(totalHeight / lineHeight)

Epos.Constants = {
    window_width  = window_width,
    window_height = 600,
    expressway    = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]],
    templates = {
        text     = DF:GetTemplate("font",     "OPTIONS_FONT_TEMPLATE"),
        dropdown = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
        switch   = DF:GetTemplate("switch",   "OPTIONS_CHECKBOX_TEMPLATE"),
        slider   = DF:GetTemplate("slider",   "OPTIONS_SLIDER_TEMPLATE"),
        button   = DF:GetTemplate("button",   "OPTIONS_BUTTON_TEMPLATE"),
    },
    colors = {
        headerColorR    = 0,
        headerColorG    = 1,
        headerColorB    = 1
    },
    tabs = {
        buttonWidth     = 120,
        buttonHeight    = 20,
        spacingX        = 10,
        topPadding      = -20,
        leftPadding     = 10,
        rightPadding    = -30,
        startY          = -100,
        lineHeight      = lineHeight,
        totalHeight     = totalHeight,
        visibleRows     = visibleRows
    },
    options = {}
}
