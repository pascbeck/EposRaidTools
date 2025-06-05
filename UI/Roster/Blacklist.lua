-- ui/roster/BlacklistUI.lua

local _, Epos = ...

-- Cached Globals
local DF             = _G.DetailsFramework                    -- DetailsFramework library
local UIParent       = _G.UIParent                            -- Blizzard UI parent frame
local CreateFrame    = _G.CreateFrame                         -- Frame creation
local table_insert   = table.insert                           -- Table insert
local table_sort     = table.sort                             -- Table sort
local strfind        = _G.strfind                             -- String find
local GetRealmName   = _G.GetRealmName                        -- Realm name
local C              = Epos.Constants                         -- Constants (templates, sizes, colors)

-- Local Constants
local PANEL_WIDTH    = 485                                     -- Width of the blacklist panel
local PANEL_HEIGHT   = 420                                     -- Height of the blacklist panel
local SCROLL_WIDTH   = PANEL_WIDTH - 40                        -- ScrollBox width (padding)
local SCROLL_HEIGHT  = 300                                     -- ScrollBox height
local ROW_HEIGHT     = C.tabs.lineHeight                       -- Height of each scroll row (20)
local VISIBLE_ROWS   = 15                                      -- Number of rows visible in ScrollBox

--- BuildBlacklistUI()
-- @return Frame  The created blacklist panel (hidden by default).
function BuildBlacklistUI()
    -- =========================================================================
    -- Create the Main Panel
    -- =========================================================================
    local blacklist_frame = DF:CreateSimplePanel(
            UIParent,
            PANEL_WIDTH,
            PANEL_HEIGHT,
            "Blacklist",
            "BlacklistEditFrame",
            { DontRightClickClose = true }
    )
    blacklist_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    --- Local Helper: PrepareData
    --- Gathers all blacklisted player names into a sorted table.
    -- @return table  Array of { fullName = string } entries.
    local function PrepareData()
        local data = {}
        for fullName in pairs(EposRT.Blacklist) do
            table_insert(data, { fullName = fullName })
        end
        table_sort(data, function(a, b)
            return a.fullName < b.fullName
        end)
        return data
    end


    --- Local Helper: MasterRefresh
    --- Clears the ScrollBox’s data and repopulates it with updated blacklist entries.
    -- @param self  ScrollBox  The ScrollBox instance to refresh.
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    --- Local Helper: refresh
    --- Populates each ScrollBox line with a blacklisted player’s name.
    -- @param self       ScrollBox  The ScrollBox instance.
    -- @param data       table      Array returned by PrepareData().
    -- @param offset     number     Starting index offset into data.
    -- @param totalLines number     Number of line frames to update.
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]
            if entry then
                local line = self:GetLine(i)
                line.fullName = entry.fullName
                line.playerText:SetText(entry.fullName)
            end
        end
    end

    --- Local Helper: createLineFunc
    --- Creates a single row frame for the ScrollBox listing player name and a delete button.
    -- @param self  Frame  The parent ScrollBox frame.
    -- @param index number  Line index (1-based), used for vertical positioning.
    -- @return Frame A configured line frame with:
    --   - playerText   (FontString): Player name.
    --   - deleteButton (Button): Button to remove this player from the blacklist.
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
                "TOPLEFT",
                self,
                "TOPLEFT",
                1,
                -((index - 1) * ROW_HEIGHT) - 1
        )
        line:SetSize(self:GetWidth() - 2, ROW_HEIGHT)
        DF:ApplyStandardBackdrop(line)

        -- Player name label (white text)
        line.playerText = DF:CreateLabel(line, "")
        line.playerText:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.playerText:SetTextColor(1, 1, 1)

        -- Delete button (12x12) at far right to remove entry
        line.deleteButton = DF:CreateButton(
                line,
                function()
                    if line.fullName then
                        EposRT.Blacklist[line.fullName] = nil
                        line:GetParent():MasterRefresh()
                        if EposUI and EposUI.roster_tab then
                            EposUI.roster_tab:MasterRefresh()
                        end
                    end
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

    -- ScrollBox Setup
    local blacklist_scrollbox = DF:CreateScrollBox(
            blacklist_frame,
            "$parentBlacklistScrollBox",
            refresh,
            {},
            SCROLL_WIDTH,
            SCROLL_HEIGHT,
            VISIBLE_ROWS,
            ROW_HEIGHT,
            createLineFunc
    )
    blacklist_frame.scrollbox = blacklist_scrollbox
    blacklist_scrollbox:SetPoint("TOPLEFT", blacklist_frame, "TOPLEFT", 10, -50)
    blacklist_scrollbox.MasterRefresh = MasterRefresh
    blacklist_scrollbox.ReajustNumFrames = true
    DF:ReskinSlider(blacklist_scrollbox)

    -- Pre-create exactly VISIBLE_ROWS line frames for performance
    for i = 1, VISIBLE_ROWS do
        blacklist_scrollbox:CreateLine(createLineFunc)
    end

    -- Column Header Label
    DF:CreateLabel(blacklist_frame, "Player Name", 11)
      :SetPoint("TOPLEFT", blacklist_frame, "TOPLEFT", 20, -30)

    -- Refresh on Panel Show
    blacklist_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    -- Input Area: Add New Player
    local new_label = DF:CreateLabel(blacklist_frame, "New Player:", 11)
    new_label:SetPoint("TOPLEFT", blacklist_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(blacklist_frame, function() end, 200, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(C.templates.dropdown)

    local add_button = DF:CreateButton(
            blacklist_frame,
            function()
                local input = new_entry:GetText():trim()
                if input ~= "" then
                    local fullName = input
                    -- If no realm specified, append current realm
                    if not strfind(input, "%-") then
                        local realm = GetRealmName():gsub("%s+", "")
                        fullName = input .. "-" .. realm
                    end
                    EposRT.Blacklist[fullName] = true
                    new_entry:SetText("")
                    blacklist_scrollbox:MasterRefresh()
                    if EposUI and EposUI.roster_tab then
                        EposUI.roster_tab:MasterRefresh()
                    end
                end
            end,
            60,
            20,
            "Add",
            nil, nil, nil,
            C.templates.button
    )
    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)

    -- Hide Panel by Default
    blacklist_frame:Hide()
    return blacklist_frame
end
