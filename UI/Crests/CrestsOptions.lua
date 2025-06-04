-- ui/Crests/CrestsOptionsUI
local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildCrestsOptions()
    -- Create main options panel
    local crests_options_frame = DF:CreateSimplePanel(
        UIParent,
        485,
        420,
        "Crests Options",
        "CrestsOptionsFrame",
        { DontRightClickClose = true }
    )
    crests_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    ---
    -- PrepareData: gather all saved currency entries
    -- @return table A sorted list of currency data tables, each containing:
    --   - id          (number): Currency ID
    --   - name        (string): Currency name or "Invalid ID"
    --   - description (string): Currency description or empty
    --   - iconFileID  (number): Icon texture ID or nil
    ---
    local function PrepareData()
        local data = {}

        for _, id in pairs(EposRT.CrestsOptions["fetch"]) do
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            local name = info and info.name or "Invalid ID"
            local description = ""
            local iconFileID = info and info.iconFileID or nil

            tinsert(data, {
                id = id,
                name = name,
                description = description,
                iconFileID = iconFileID,
            })
        end

        table.sort(data, function(a, b)
            return a.id < b.id
        end)

        return data
    end

    ---
    -- MasterRefresh: clears and repopulates the scrollbox with updated data
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    ---
    -- refresh: populate each scroll line with currency info
    -- @param self       The scrollbox object
    -- @param data       Table containing currency entries
    -- @param offset     Starting index offset into data table
    -- @param totalLines Number of line frames to update
    ---
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]

            if entry then
                local line = self:GetLine(i)
                line.currencyID = entry.id

                -- Icon (if valid)
                if entry.iconFileID then
                    line.iconTexture:SetTexture(entry.iconFileID)
                    line.iconTexture:Show()
                else
                    line.iconTexture:Hide()
                end

                -- Name
                line.nameLabel:SetText(entry.name)

                -- Description (truncate if needed)
                line.descLabel:SetText(entry.description)

                -- Delete button handler removes by currencyID
                -- (no extra state needed here)
            end
        end
    end

    ---
    -- createLineFunc: create one row in the scrollbox showing icon, name, desc, and delete button
    -- @param self  Frame Parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with:
    --   - iconTexture   (Texture): Currency icon
    --   - nameLabel     (FontString): Currency name
    --   - descLabel     (FontString): Currency description
    --   - deleteButton  (Button): Remove this currency entry
    ---
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

        -- Icon (24x24) at left
        line.iconTexture = line:CreateTexture(nil, "ARTWORK")
        line.iconTexture:SetSize(24, 24)
        line.iconTexture:SetPoint("LEFT", line, "LEFT", 5, 0)

        -- Name label (left of icon + padding)
        line.nameLabel = DF:CreateLabel(line, "")
        line.nameLabel:SetPoint("LEFT", line.iconTexture, "RIGHT", 8, 0)
        line.nameLabel:SetWidth(240)

        -- Description label (to the right of name)
        line.descLabel = DF:CreateLabel(line, "")
        line.descLabel:SetPoint("LEFT", line.nameLabel, "RIGHT", 10, 0)
        line.descLabel:SetWidth(200)
        line.descLabel:SetJustifyH("LEFT")

        -- Delete button (12x12) at far right
        line.deleteButton = DF:CreateButton(line, function()
            local id = line.currencyID
            if not id then return end

            -- Remove `id` from the “fetch” list
            local list = EposRT.CrestsOptions["fetch"]
            for i = #list, 1, -1 do
                if list[i] == id then
                    tremove(list, i)
                    break
                end
            end

            EposRT.CrestsOptions["show"] = EposRT.CrestsOptions["fetch"][1] or nil

            if (EposUI.crests_tab) then
                local dd = EposUI.crests_tab.__crestDropdown
                if dd then
                    dd:Refresh()
                    dd:Select(EposRT.CrestsOptions["fetch"][1])
                    EposUI.crests_tab:MasterRefresh()
                end
            end

            -- Refresh the options‐panel scrollbox (that “Delete” button lives in)
            line:GetParent():MasterRefresh()
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

    -- ScrollBox Setup
    local scrollLines  = 15
    local rowHeight    = 36
    local scrollHeight = rowHeight * scrollLines
    local scrollWidth  = 445

    local crests_scrollbox = DF:CreateScrollBox(
        crests_options_frame,
        "$parentBlacklistScrollBox",
        refresh,
        {},
        scrollWidth,   -- width
        300,           -- height
        scrollLines,   -- visible rows
        rowHeight,     -- row height
        createLineFunc
    )

    crests_options_frame.scrollbox = crests_scrollbox
    crests_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(crests_scrollbox)
    crests_scrollbox.ReajustNumFrames = true
    crests_scrollbox:SetPoint("TOPLEFT", crests_options_frame, "TOPLEFT", 10, -50)

    -- Create exactly as many line frames as will fit on screen
    for i = 1, scrollLines do
        crests_scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow: refresh data when panel is shown
    crests_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    ---
    -- Input area for adding new currency ID
    ---
    -- Label "New Identifier:"
    local new_label = DF:CreateLabel(crests_options_frame, "New Identifier:", 11)
    new_label:SetPoint("TOPLEFT", crests_scrollbox, "BOTTOMLEFT", 0, -20)

    -- Text entry for ID input
    local new_entry = DF:CreateTextEntry(crests_options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

    -- Add button to insert the entered currency ID
    local add_button = DF:CreateButton(crests_options_frame, function()
        local text = new_entry:GetText():trim()
        local id = tonumber(text)

        if not id then
            print("Invalid currency ID. Please enter a number.")
            return
        end

        -- Avoid duplicates
        for _, existing in ipairs(EposRT.CrestsOptions["fetch"]) do
            if existing == id then
                return
            end
        end

        tinsert(EposRT.CrestsOptions["fetch"], id)
        EposRT.CrestsOptions["show"] = id
        new_entry:SetText("")
        crests_scrollbox:MasterRefresh()

        print("before refresh")
        if (EposUI.crests_tab) then
            print("after first refresh")

            -- Force the dropdown to rebuild its menu
            local dd = EposUI.crests_tab.__crestDropdown
            if dd then
                dd:Refresh()
                dd:Select(id)
                EposUI.crests_tab:MasterRefresh()
            end
        end
    end, 60, 20, "Add")

    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

    crests_options_frame:Hide()
    return crests_options_frame
end