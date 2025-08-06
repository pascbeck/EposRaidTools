-- constants.lua

local _, Epos = ...
local DF = _G.DetailsFramework
local math_floor = math.floor

--- Layout Dimensions
-- Base window dimensions
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600

-- Height of each row in list views
local LINE_HEIGHT = 24

-- Total vertical space available for scrollable content
local TOTAL_HEIGHT = WINDOW_HEIGHT - 180              -- Account for header/footer spacing

-- Number of rows visible in a scrollable area given LINE_HEIGHT
local VISIBLE_ROWS = math_floor(TOTAL_HEIGHT / LINE_HEIGHT)

--- Font & Template References
-- Path to custom font file used in Epos Raid Tools
local EXPRESSWAY_FONT_PATH = [[Interface\AddOns\EposRaidTools\Media\Expressway.TTF]]

-- UI template fetcher (DetailsFramework)
-- These templates define how various UI elements look and behave.
local TEMPLATES = {
    text = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE"),
    dropdown = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"),
    switch = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"),
    slider = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE"),
    button = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"),
}

--- Color Definitions
-- Header text color (RGB normalized 0–1)
local COLORS = {
    headerColorR = 120 / 255, -- Normalizing the red value
    headerColorG = 170 / 255, -- Normalizing the green value
    headerColorB = 255 / 255, -- Normalizing the blue value
}

--- Tab Configuration
-- Defines sizing and spacing for tab buttons and content
local TABS = {
    buttonWidth = 120, -- Width of each tab button
    buttonHeight = 20, -- Height of each tab button
    spacingX = 10, -- Horizontal spacing between tabs
    topPadding = -20, -- Padding from the top edge for tab row
    leftPadding = 10, -- Padding from the left edge for first tab
    rightPadding = -30, -- Padding from the right edge of the container
    startY = -100, -- Y‐offset where tabs begin (below header)
    lineHeight = LINE_HEIGHT,
    totalHeight = TOTAL_HEIGHT,
    visibleRows = VISIBLE_ROWS,
}

local BOSS_ICONS = {
    6922080,
    6922087,
    6922081,
    6922084,
    6922082,
    6922085,
    6922086,
    6922083
}

local GUILD_RANKS = {
    "Guildlead",
    "Officer",
    "Officer Alt",
    "Raider",
    "Raid Alt",
    "Trial",
	}

--- Combine into Epos.Constants
Epos.Constants = {
    -- Window dimensions
    window_width = WINDOW_WIDTH,
    window_height = WINDOW_HEIGHT,

    -- Custom font path
    expressway = EXPRESSWAY_FONT_PATH,

    -- UI element templates
    templates = TEMPLATES,

    -- Standardized colors
    colors = COLORS,

    -- Tab layout settings
    tabs = TABS,

    -- Placeholder for additional option constants (populated at runtime)
    options = {},

    guildRanks = GUILD_RANKS,

    bossIcons = BOSS_ICONS,
}
