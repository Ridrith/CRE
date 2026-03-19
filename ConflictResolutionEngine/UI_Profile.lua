-- UI_Profile.lua — Profile creation/editing UI tab
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

-- State for the profile tab editor
local editor = {
    profile    = nil,   -- working copy being edited
    profileName = nil,  -- name before any rename
}

-- ─── Build ────────────────────────────────────────────────────────────────────
function ns.BuildProfileTab(panel)
    -- ── Left column: profile list ──
    local listLabel = ns.MakeLabel(panel, "Profiles", 1, 0.82, 0.2)
    listLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)

    -- Scroll list for profile names
    local listScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    listScroll:SetSize(130, 340)
    listScroll:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -4)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(130, 340)
    listScroll:SetScrollChild(listContent)
    editor.listContent = listContent

    -- New / Delete buttons
    local newBtn = ns.MakeButton(panel, "New Profile", 130, 22)
    newBtn:SetPoint("TOPLEFT", listScroll, "BOTTOMLEFT", 0, -4)
    newBtn:SetScript("OnClick", function()
        editor.newMode = true
        editor.profile = {
            name          = "",
            class         = "Warrior",
            attributes    = {},
            armor         = "None",
            hasShield     = false,
            passiveTraits = {},
            activeTraits  = {},
        }
        for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
            editor.profile.attributes[key] = 0
        end
        ns.RefreshProfileEditor()
    end)

    local delBtn = ns.MakeButton(panel, "Delete", 130, 22)
    delBtn:SetPoint("TOPLEFT", newBtn, "BOTTOMLEFT", 0, -4)
    delBtn:SetScript("OnClick", function()
        local _, name = ns.GetActiveProfile()
        if name then
            ns.DeleteProfile(name)
            ns.RefreshProfileList()
            ns.RefreshProfileEditor()
        end
    end)

    local exportBtn = ns.MakeButton(panel, "Export", 62, 22)
    exportBtn:SetPoint("TOPLEFT", delBtn, "BOTTOMLEFT", 0, -4)
    exportBtn:SetScript("OnClick", function()
        local _, name = ns.GetActiveProfile()
        if not name then return end
        local encoded, err = ns.ExportProfile(name)
        if encoded then
            ns.Print(c.gold .. "Export for '" .. name .. "':" .. c.r)
            ns.Print(encoded)
        else
            ns.PrintError(err)
        end
    end)

    local importBtn = ns.MakeButton(panel, "Import", 62, 22)
    importBtn:SetPoint("TOPLEFT", exportBtn, "TOPRIGHT", 4, 0)
    importBtn:SetScript("OnClick", function()
        -- Show a simple input box
        if editor.importBox and editor.importBox:IsShown() then
            editor.importBox:Hide()
        else
            if editor.importBox then
                editor.importBox:Show()
            else
                local ib = ns.MakeEditBox(panel, 130, 20)
                ib:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -4)
                ib:SetMaxLetters(2000)
                ib:SetScript("OnEnterPressed", function(self)
                    local text = ns.Trim(self:GetText())
                    local ok, result = ns.ImportProfile(text)
                    if ok then
                        ns.Print(c.green .. "Imported profile: " .. result)
                        ns.SetActiveProfile(result)
                        ns.RefreshProfileList()
                        ns.RefreshProfileEditor()
                        self:SetText("")
                        self:Hide()
                    else
                        ns.PrintError(result)
                    end
                end)
                editor.importBox = ib
                ib:Show()
                ib:SetFocus()
            end
        end
    end)

    -- ── Right column: editor ──
    local edLabel = ns.MakeLabel(panel, "Character Sheet", 1, 0.82, 0.2)
    edLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 150, -8)

    -- Profile name input
    local nameLabel = ns.MakeLabel(panel, "Name:", 0.8, 0.8, 0.8)
    nameLabel:SetPoint("TOPLEFT", edLabel, "BOTTOMLEFT", 0, -6)

    local nameBox = ns.MakeEditBox(panel, 220, 20)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
    nameBox:SetMaxLetters(40)
    editor.nameBox = nameBox

    -- Class dropdown
    local classLabel = ns.MakeLabel(panel, "Class:", 0.8, 0.8, 0.8)
    classLabel:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -6)

    local classDD = ns.MakeDropdown(panel, ns.CLASS_ORDER, "Warrior", function(selected)
        if editor.profile then
            editor.profile.class = selected
            ns.RefreshAttributeDisplay()
        end
    end)
    classDD:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", -16, -2)
    editor.classDD = classDD

    -- Armor dropdown
    local armorLabel = ns.MakeLabel(panel, "Armor:", 0.8, 0.8, 0.8)
    armorLabel:SetPoint("TOPLEFT", classDD, "BOTTOMLEFT", 16, -6)

    local armorDD = ns.MakeDropdown(panel, ns.ARMOR_TYPES, "None", function(selected)
        if editor.profile then
            editor.profile.armor = selected
            ns.RefreshAttributeDisplay()
        end
    end)
    armorDD:SetPoint("TOPLEFT", armorLabel, "BOTTOMLEFT", -16, -2)
    editor.armorDD = armorDD

    -- Shield checkbox
    local shieldCb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    shieldCb:SetSize(20, 20)
    shieldCb:SetPoint("TOPLEFT", armorDD, "BOTTOMLEFT", 16, -4)
    shieldCb.text = shieldCb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    shieldCb.text:SetPoint("LEFT", shieldCb, "RIGHT", 2, 0)
    shieldCb.text:SetText("Shield (off-hand)")
    shieldCb:SetScript("OnClick", function(self)
        if editor.profile then
            editor.profile.hasShield = self:GetChecked() and true or false
            ns.RefreshAttributeDisplay()
        end
    end)
    editor.shieldCb = shieldCb

    -- Attribute point allocation
    local attrLabel = ns.MakeLabel(panel, "Attributes (10 pts, max +6):", 0.8, 0.8, 0.8)
    attrLabel:SetPoint("TOPLEFT", shieldCb, "BOTTOMLEFT", -16, -8)

    editor.pointsLeft = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.pointsLeft:SetPoint("TOPLEFT", attrLabel, "BOTTOMLEFT", 0, -4)
    editor.pointsLeft:SetText("Points remaining: 10")
    editor.pointsLeft:SetTextColor(1, 0.82, 0.2)

    editor.attrRows = {}
    local attrY = -4
    local attrAnchor = editor.pointsLeft

    for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
        local row = {}
        local rowFrame = CreateFrame("Frame", nil, panel)
        rowFrame:SetSize(220, 18)
        rowFrame:SetPoint("TOPLEFT", attrAnchor, "BOTTOMLEFT", 0, attrY)

        local lbl = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        lbl:SetText(ns.ATTRIBUTE_NAMES[key])
        lbl:SetTextColor(0.8, 0.8, 0.8)
        lbl:SetWidth(70)

        local minusBtn = ns.MakeButton(rowFrame, "-", 18, 18)
        minusBtn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        minusBtn:SetScript("OnClick", function()
            if not editor.profile then return end
            local cur = editor.profile.attributes[key] or 0
            if cur > 0 then
                editor.profile.attributes[key] = cur - 1
                ns.RefreshAttributeDisplay()
            end
        end)

        local valText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        valText:SetPoint("LEFT", minusBtn, "RIGHT", 4, 0)
        valText:SetText("0")
        valText:SetTextColor(0.2, 0.9, 0.4)
        valText:SetWidth(20)
        valText:SetJustifyH("CENTER")

        local plusBtn = ns.MakeButton(rowFrame, "+", 18, 18)
        plusBtn:SetPoint("LEFT", valText, "RIGHT", 4, 0)
        plusBtn:SetScript("OnClick", function()
            if not editor.profile then return end
            local cur = editor.profile.attributes[key] or 0
            local spent = ns.AttributePointsSpent(editor.profile.attributes)
            if cur < ns.ATTRIBUTE_MAX and spent < ns.ATTRIBUTE_POINT_TOTAL then
                editor.profile.attributes[key] = cur + 1
                ns.RefreshAttributeDisplay()
            end
        end)

        row.key     = key
        row.valText = valText
        editor.attrRows[key] = row
        attrAnchor = rowFrame
        attrY = 0
    end

    -- Derived stats display
    editor.statsText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editor.statsText:SetPoint("TOPLEFT", attrAnchor, "BOTTOMLEFT", 0, -8)
    editor.statsText:SetTextColor(0.7, 0.9, 1)
    editor.statsText:SetJustifyH("LEFT")
    editor.statsText:SetWidth(230)

    -- Save button
    local saveBtn = ns.MakeButton(panel, "Save & Activate", 160, 24)
    saveBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 150, 8)
    saveBtn:SetScript("OnClick", function()
        if not editor.profile then return end
        local nameVal = ns.Trim(nameBox:GetText())
        if nameVal == "" then
            ns.PrintError("Profile name is required.")
            return
        end
        local spent = ns.AttributePointsSpent(editor.profile.attributes)
        if spent ~= ns.ATTRIBUTE_POINT_TOTAL then
            ns.PrintError("You must spend exactly 10 attribute points (currently " .. spent .. ").")
            return
        end
        editor.profile.name = nameVal
        if editor.newMode then
            local ok, result = ns.CreateProfile(nameVal, editor.profile.class)
            if not ok then
                ns.PrintError(result)
                return
            end
            -- Copy the edited fields into the newly created profile
            result.attributes    = editor.profile.attributes
            result.armor         = editor.profile.armor
            result.hasShield     = editor.profile.hasShield
            result.passiveTraits = editor.profile.passiveTraits
            result.activeTraits  = editor.profile.activeTraits
            ns.SaveProfile(result)
            editor.newMode = false
        else
            -- Check for rename
            local oldName = editor.profileName
            if oldName and oldName ~= nameVal then
                local ok, err = ns.RenameProfile(oldName, nameVal)
                if not ok then ns.PrintError(err) return end
            else
                ns.SaveProfile(editor.profile)
            end
        end
        editor.profileName = nameVal
        ns.SetActiveProfile(nameVal)
        ns.Print(c.green .. "Profile '" .. nameVal .. "' saved and activated.")
        ns.RefreshProfileList()
        ns.RefreshAttributeDisplay()
        if ns.RefreshCombatTab then ns.RefreshCombatTab() end
    end)

    ns.RefreshProfileList()
end

-- ─── Refresh functions ────────────────────────────────────────────────────────

function ns.RefreshProfileTab()
    ns.RefreshProfileList()
    ns.RefreshProfileEditor()
end

function ns.RefreshProfileList()
    if not editor.listContent then return end
    -- Clear old buttons
    for _, child in pairs({ editor.listContent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local _, activeProfileName = ns.GetActiveProfile()
    local names = ns.ListProfiles()
    local y = 0
    for i, name in ipairs(names) do
        local btn = ns.MakeButton(editor.listContent, name, 120, 20)
        btn:SetPoint("TOPLEFT", editor.listContent, "TOPLEFT", 0, -y)
        if name == activeProfileName then
            btn:SetBackdropColor(0.2, 0.15, 0.05, 1)
            btn.txt:SetTextColor(1, 0.82, 0.2)
        end
        btn:SetScript("OnClick", function()
            local p = ns.GetProfile(name)
            if p then
                ns.SetActiveProfile(name)
                editor.profile     = p
                editor.profileName = name
                editor.newMode     = false
                ns.RefreshProfileEditor()
                ns.RefreshProfileList()
            end
        end)
        y = y + 22
    end
    editor.listContent:SetHeight(math.max(y, 20))
end

function ns.RefreshProfileEditor()
    if not editor.nameBox then return end

    local p = editor.profile
    if not p then
        editor.nameBox:SetText("")
        if editor.pointsLeft then editor.pointsLeft:SetText("Points remaining: 10") end
        if editor.statsText  then editor.statsText:SetText("") end
        return
    end

    editor.nameBox:SetText(p.name or "")
    if editor.classDD  then UIDropDownMenu_SetText(editor.classDD, p.class or "Warrior") end
    if editor.armorDD  then UIDropDownMenu_SetText(editor.armorDD, p.armor or "None") end
    if editor.shieldCb then editor.shieldCb:SetChecked(p.hasShield and true or false) end

    ns.RefreshAttributeDisplay()
end

function ns.RefreshAttributeDisplay()
    if not editor.profile then return end
    local p = editor.profile

    local spent = ns.AttributePointsSpent(p.attributes)
    local remaining = ns.ATTRIBUTE_POINT_TOTAL - spent
    if editor.pointsLeft then
        local color = remaining == 0 and c.green or (remaining < 0 and c.red or c.yellow)
        editor.pointsLeft:SetText("Points remaining: " .. color .. remaining .. c.r)
    end

    for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
        local row = editor.attrRows and editor.attrRows[key]
        if row and row.valText then
            local v = (p.attributes and p.attributes[key]) or 0
            row.valText:SetText(ns.SignedNum(v))
            if v == ns.ATTRIBUTE_MAX then
                row.valText:SetTextColor(1, 0.5, 0.2)
            elseif v > 0 then
                row.valText:SetTextColor(0.2, 0.9, 0.4)
            else
                row.valText:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    if editor.statsText then
        local maxStrikes = ns.CalcMaxStrikes(p)
        local defense    = ns.CalcDefense(p)
        local inventory  = ns.CalcInventory(p)
        local classData  = ns.CLASS_DATA[p.class or "Warrior"] or {}
        editor.statsText:SetText(
            "|cFFFFD700Strikes:|r " .. maxStrikes ..
            "   |cFF4499FFDefense:|r " .. defense ..
            "   |cFFAAAAAA Inventory:|r " .. inventory .. " slots" ..
            "\n|cFFFFFFFF" .. (p.class or "") .. ":|r " .. (classData.flavor or "")
        )
    end
end
