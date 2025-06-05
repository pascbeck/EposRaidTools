-- ui/WeakAuras/WeakAurasOptionsUI
local _, Epos = ...
local DF = _G["DetailsFramework"]

function BuildWeakAurasOptions()
    -- Create main options panel
    local wa_options_frame = DF:CreateSimplePanel(
        UIParent,
        485,
        420,
        "WeakAuras Options",
        "WeakAurasOptionsFrame",
        { DontRightClickClose = true }
    )
    wa_options_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    ---
    -- PrepareData: gather all saved WA‐set entries
    -- @return table A sorted list of WA data tables, each containing:
    --   - id          (number): WA set ID
    --   - name        (string): WA set name or "Invalid ID"
    --   - description (string): WA set description or empty
    --   - iconFileID  (number): WA set icon texture ID or nil
    ---
    local function PrepareData()
        local data = {}

        for _, id in pairs(EposRT.WeakAurasOptions["fetch"]) do
            -- Attempt to retrieve WA set info; replace with actual WA‐API call if different
            local info = WeakAuras and WeakAuras.GetData(id) or nil
            local name = (info and info.id) or id
            local description = (info and info.desc) or ""
            local iconFileID = (info and info.icon) or nil

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
    ---
    local function MasterRefresh(self)
        local data = PrepareData()
        self:SetData(data)
        self:Refresh()
    end

    ---
    -- refresh: populate each scroll line with WA‐set info
    -- @param self       The scrollbox object
    -- @param data       Table containing WA entries
    -- @param offset     Starting index offset into data table
    -- @param totalLines Number of line frames to update
    ---
    local function refresh(self, data, offset, totalLines)
        for i = 1, totalLines do
            local index = i + offset
            local entry = data[index]

            if entry then
                local line = self:GetLine(i)
                line.waSetID = entry.id

                -- Icon (if valid)
                line.iconTexture:SetTexture("Interface\\AddOns\\EposRaidTools\\Media\\logo_64.tga")
                line.iconTexture:Show()

                -- Name
                line.nameLabel:SetText(entry.name)

                -- Description (truncate if needed)
                line.descLabel:SetText(entry.description)
            end
        end
    end

    ---
    -- createLineFunc: create one row in the scrollbox showing icon, name, desc, and delete button
    -- @param self  Frame Parent scrollbox frame
    -- @param index number Line index (used for vertical offset)
    -- @return Frame A configured line frame with:
    --   - iconTexture   (Texture): WA‐set icon
    --   - nameLabel     (FontString): WA‐set name
    --   - descLabel     (FontString): WA‐set description
    --   - deleteButton  (Button): Remove this WA entry
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
            local id = line.waSetID
            if not id then return end

            -- Remove `id` from the “fetch” list
            local list = EposRT.WeakAurasOptions["fetch"]
            for i = #list, 1, -1 do
                if list[i] == id then
                    tremove(list, i)
                    break
                end
            end


            if EposRT.WeakAurasOptions["show"] == id then
                EposRT.WeakAurasOptions["show"] = EposRT.WeakAurasOptions["fetch"][1] or nil
            end

        if not next(EposRT.WeakAurasOptions.fetch or {}) then
            EposRT.WeakAurasOptions.show = nil
        end

            if (EposUI.weakauras_tab) then
                local dd = EposUI.weakauras_tab.__waDropdown
                if dd then
                    dd:Refresh()
                    dd:Select(EposRT.WeakAurasOptions["fetch"][1])
                    EposUI.weakauras_tab:MasterRefresh()
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

    local wa_scrollbox = DF:CreateScrollBox(
        wa_options_frame,
        "$parentWeakAurasScrollBox",
        refresh,
        {},
        scrollWidth,   -- width
        300,           -- height
        scrollLines,   -- visible rows
        rowHeight,     -- row height
        createLineFunc
    )

    wa_options_frame.scrollbox = wa_scrollbox
    wa_scrollbox.MasterRefresh = MasterRefresh
    DF:ReskinSlider(wa_scrollbox)
    wa_scrollbox.ReajustNumFrames = true
    wa_scrollbox:SetPoint("TOPLEFT", wa_options_frame, "TOPLEFT", 10, -50)

    -- Create exactly as many line frames as will fit on screen
    for i = 1, scrollLines do
        wa_scrollbox:CreateLine(createLineFunc)
    end

    -- OnShow: refresh data when panel is shown
    wa_scrollbox:SetScript("OnShow", function(self)
        self:MasterRefresh()
    end)

    ---
    -- Input area for adding new WA set ID
    ---
    -- Label "New Identifier:"
    local new_label = DF:CreateLabel(wa_options_frame, "New Identifier:", 11)
    new_label:SetPoint("TOPLEFT", wa_scrollbox, "BOTTOMLEFT", 0, -20)

    -- Text entry for ID input
    local new_entry = DF:CreateTextEntry(wa_options_frame, function() end, 120, 20)
    new_entry:SetPoint("LEFT", new_label, "RIGHT", 10, 0)
    new_entry:SetTemplate(DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

    -- Add button to insert the entered WA ID
    local add_button = DF:CreateButton(wa_options_frame, function()
        local id = new_entry:GetText():trim()


        -- Avoid duplicates
        for _, existing in ipairs(EposRT.WeakAurasOptions["fetch"]) do
            if existing == id then
                return
            end
        end


        print(id)
        local wa = WeakAuras.GetData(id)
        if not wa then
            print("Invalid WeakAura")
            return
        end
        tinsert(EposRT.WeakAurasOptions["fetch"], id)
        EposRT.WeakAurasOptions["show"] = id
        DevTools_Dump(EposRT.WeakAurasOptions["show"])
        new_entry:SetText("")
        wa_scrollbox:MasterRefresh()

        if (EposUI.weakauras_tab) then
            local dd = EposUI.weakauras_tab.__waDropdown
            if dd then
                dd:Refresh()
                dd:Select(id)
                EposUI.weakauras_tab:MasterRefresh()
            end
        end
    end, 60, 20, "Add")

    add_button:SetPoint("LEFT", new_entry, "RIGHT", 10, 0)
    add_button:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

    wa_options_frame:Hide()
    return wa_options_frame
end
