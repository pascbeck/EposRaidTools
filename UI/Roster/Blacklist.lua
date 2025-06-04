local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildBlacklistUI()
    EposRT.Blacklist = EposRT.Blacklist or {}

    local blacklist_frame = DF:CreateSimplePanel(
        UIParent,
        485,
        420,
        "Blacklist",
        "BlacklistEditFrame",
        { DontRightClickClose = true }
    )
    blacklist_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    --- PrepareData: gather all blacklisted player names
    local function PrepareData()
        local data = {}
        for fullName in pairs(EposRT.Blacklist) do
            tinsert(data, { fullName = fullName })
        end

        table.sort(data, function(a, b)
            return a.fullName < b.fullName
        end)

        return data
    end

    --- MasterRefresh: clears and repopulates the scrollbox with updated data
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    --- refresh: populate each scroll line with player name
    -- @param self       The scrollbox object
    -- @param data       Table containing blacklist entries
    -- @param offset     Starting index offset into data table
    -- @param totalLines Number of line frames to update
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

    --- createLineFunc: create one row in the scrollbox showing player name and delete button
    -- @param self  Frame  Parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with:
    --   - playerText   (FontString): Player name
    --   - deleteButton (Button): Remove this blacklist entry
    local function createLineFunc(self, index)
        local line = CreateFrame("Frame", "$parentLine" .. index, self, "BackdropTemplate")
        line:SetPoint(
            "TOPLEFT",
            self,
            "TOPLEFT",
            1,
            -((index - 1) * (self.LineHeight)) - 1
        )
        line:SetSize(self:GetWidth() - 2, self.LineHeight)
        DF:ApplyStandardBackdrop(line)

        -- Player name label
        line.playerText = DF:CreateLabel(line, "")
        line.playerText:SetPoint("LEFT", line, "LEFT", 5, 0)
        line.playerText:SetTextColor(1, 1, 1)

        -- Delete button (12x12) at far right
        line.deleteButton = DF:CreateButton(line, function()
            if line.fullName then
                EposRT.Blacklist[line.fullName] = nil
                line:GetParent():MasterRefresh()
                if EposUI.roster_tab then
                    EposUI.roster_tab:MasterRefresh()
                end
            end
        end, 12, 12)

        line.deleteButton:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetHighlightTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
        line.deleteButton:GetNormalTexture():SetDesaturated(true)
        line.deleteButton:GetHighlightTexture():SetDesaturated(true)
        line.deleteButton:GetPushedTexture():SetDesaturated(true)
        line.deleteButton:SetPoint("RIGHT", line, "RIGHT", -5, 0)

        return line
    end

    --- ScrollBox Setup
    local scrollLines = 15

    local blacklist_scrollbox = DF:CreateScrollBox(
        blacklist_frame,
        "$parentBlacklistScrollBox",
        refresh,
        {},
        445,            -- width
        300,            -- height
        scrollLines,    -- visible rows
        20,             -- row height
        createLineFunc
    )
    blacklist_frame.scrollbox = blacklist_scrollbox
    blacklist_scrollbox:SetPoint("TOPLEFT", blacklist_frame, "TOPLEFT", 10, -50)
    blacklist_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(blacklist_scrollbox)
    blacklist_scrollbox.ReajustNumFrames = true

    -- Create exactly as many line frames as will fit
    for i = 1, scrollLines do
        blacklist_scrollbox:CreateLine(createLineFunc)
    end

    -- Column header label
    DF:CreateLabel(blacklist_frame, "Player Name", 11)
        :SetPoint("TOPLEFT", blacklist_frame, "TOPLEFT", 20, -30)

    -- Refresh on show
    blacklist_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    --- Input area for adding new player to blacklist
    local new_label = DF:CreateLabel(blacklist_frame, "New Player:", 11)
    new_label:SetPoint("TOPLEFT", blacklist_scrollbox, "BOTTOMLEFT", 0, -20)

    local new_entry = DF:CreateTextEntry(blacklist_frame, function() end, 200, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

    local add_button = DF:CreateButton(blacklist_frame, function()
        local input = new_entry:GetText():trim()
        if input ~= "" then
            local hasRealm = strfind(input, "%-")
            local fullName = input

            if not hasRealm then
                local realm = GetRealmName():gsub("%s+", "")
                fullName = input .. "-" .. realm
            end

            EposRT.Blacklist[fullName] = true
            new_entry:SetText("")
            blacklist_scrollbox:MasterRefresh()

            if EposUI.roster_tab then
                EposUI.roster_tab:MasterRefresh()
            end
        end
    end, 60, 20, "Add")

    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

    blacklist_frame:Hide()
    return blacklist_frame
end