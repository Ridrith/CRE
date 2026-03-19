-- UI_Traits.lua — Traits browser/selector UI tab
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

local traitsUI = {
    filter    = "",
    showType  = "all",  -- "all", "passive", "active"
    selected  = nil,    -- currently highlighted trait entry
}

-- ─── Build ────────────────────────────────────────────────────────────────────
function ns.BuildTraitsTab(panel)

    -- ── Filter bar ──
    local filterLabel = ns.MakeLabel(panel, "Search:", 0.8, 0.8, 0.8)
    filterLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)

    local filterBox = ns.MakeEditBox(panel, 150, 20)
    filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 4, 0)
    filterBox:SetMaxLetters(40)
    filterBox:SetScript("OnTextChanged", function(self)
        traitsUI.filter = self:GetText():lower()
        ns.RefreshTraitsList()
    end)
    traitsUI.filterBox = filterBox

    -- Type filter buttons
    local allBtn = ns.MakeButton(panel, "All", 50, 20)
    allBtn:SetPoint("LEFT", filterBox, "RIGHT", 6, 0)
    allBtn:SetScript("OnClick", function() traitsUI.showType = "all" ns.RefreshTraitsList() end)

    local passBtn = ns.MakeButton(panel, "Passive", 60, 20)
    passBtn:SetPoint("LEFT", allBtn, "RIGHT", 4, 0)
    passBtn:SetScript("OnClick", function() traitsUI.showType = "passive" ns.RefreshTraitsList() end)

    local actBtn = ns.MakeButton(panel, "Active", 60, 20)
    actBtn:SetPoint("LEFT", passBtn, "RIGHT", 4, 0)
    actBtn:SetScript("OnClick", function() traitsUI.showType = "active" ns.RefreshTraitsList() end)

    -- ── Left: trait list ──
    local listScroll, listContent = ns.MakeScrollFrame(panel, 220, 440)
    listScroll:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -6)
    traitsUI.listContent = listContent

    -- ── Right: detail pane ──
    local detailBg = CreateFrame("Frame", nil, panel, "BackdropTemplateMixin and BackdropTemplate")
    detailBg:SetSize(220, 440)
    detailBg:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 6, 0)
    ns.SetDarkBackdrop(detailBg, 2)

    local detailTitle = detailBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailTitle:SetPoint("TOPLEFT", detailBg, "TOPLEFT", 6, -6)
    detailTitle:SetWidth(206)
    detailTitle:SetJustifyH("LEFT")
    detailTitle:SetText("Select a trait")
    detailTitle:SetTextColor(1, 0.82, 0.2)
    traitsUI.detailTitle = detailTitle

    local detailType = detailBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailType:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -4)
    detailType:SetWidth(206)
    detailType:SetJustifyH("LEFT")
    detailType:SetTextColor(0.6, 0.8, 1)
    traitsUI.detailType = detailType

    local detailDesc = detailBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailDesc:SetPoint("TOPLEFT", detailType, "BOTTOMLEFT", 0, -8)
    detailDesc:SetWidth(206)
    detailDesc:SetJustifyH("LEFT")
    detailDesc:SetTextColor(0.9, 0.85, 0.7)
    detailDesc:SetWordWrap(true)
    traitsUI.detailDesc = detailDesc

    -- Add/Remove to profile buttons
    local addBtn = ns.MakeButton(detailBg, "Add to Profile", 140, 24)
    addBtn:SetPoint("BOTTOMLEFT", detailBg, "BOTTOMLEFT", 6, 6)
    addBtn:SetScript("OnClick", function()
        local sel = traitsUI.selected
        if not sel then return end
        local profile = ns.GetActiveProfile()
        if not profile then
            ns.PrintError("No active profile.")
            return
        end
        if sel.traitType == "passive" then
            for _, tid in ipairs(profile.passiveTraits) do
                if tid == sel.id then
                    ns.Print("Trait already in profile.")
                    return
                end
            end
            profile.passiveTraits[#profile.passiveTraits + 1] = sel.id
        else
            for _, tid in ipairs(profile.activeTraits) do
                if tid == sel.id then
                    ns.Print("Trait already in profile.")
                    return
                end
            end
            profile.activeTraits[#profile.activeTraits + 1] = sel.id
            ns.RefreshTraitUses(profile)
        end
        ns.SaveProfile(profile)
        ns.Print(c.green .. "Added '" .. sel.name .. "' to profile.")
        ns.RefreshAttributeDisplay()
    end)

    local removeBtn = ns.MakeButton(detailBg, "Remove", 60, 24)
    removeBtn:SetPoint("LEFT", addBtn, "RIGHT", 4, 0)
    removeBtn:SetScript("OnClick", function()
        local sel = traitsUI.selected
        if not sel then return end
        local profile = ns.GetActiveProfile()
        if not profile then return end
        if sel.traitType == "passive" then
            for i, tid in ipairs(profile.passiveTraits) do
                if tid == sel.id then
                    table.remove(profile.passiveTraits, i)
                    break
                end
            end
        else
            for i, tid in ipairs(profile.activeTraits) do
                if tid == sel.id then
                    table.remove(profile.activeTraits, i)
                    break
                end
            end
            if profile.traitUses then profile.traitUses[sel.id] = nil end
        end
        ns.SaveProfile(profile)
        ns.Print(c.red .. "Removed '" .. sel.name .. "' from profile.")
        ns.RefreshAttributeDisplay()
    end)
end

-- ─── Refresh ──────────────────────────────────────────────────────────────────
function ns.RefreshTraitsTab()
    ns.RefreshTraitsList()
end

function ns.RefreshTraitsList()
    if not traitsUI.listContent then return end

    -- Clear old entries
    for _, child in pairs({ traitsUI.listContent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local filter   = traitsUI.filter or ""
    local showType = traitsUI.showType or "all"
    local profile  = ns.GetActiveProfile()

    local allEntries = {}
    if showType == "all" or showType == "passive" then
        for _, t in ipairs(ns.PASSIVE_TRAITS) do
            allEntries[#allEntries + 1] = { id=t.id, name=t.name, desc=t.desc, traitType="passive" }
        end
    end
    if showType == "all" or showType == "active" then
        for _, t in ipairs(ns.ACTIVE_TRAITS) do
            local label = t.name .. " (" .. t.uses .. "/enc)"
            allEntries[#allEntries + 1] = { id=t.id, name=t.name, desc=t.desc, traitType="active", uses=t.uses, label=label }
        end
    end

    local y = 0
    for _, entry in ipairs(allEntries) do
        -- Apply search filter
        if filter == "" or
           entry.name:lower():find(filter, 1, true) or
           entry.desc:lower():find(filter, 1, true) then

            local btn = ns.MakeButton(traitsUI.listContent, entry.label or entry.name, 200, 22)
            btn:SetPoint("TOPLEFT", traitsUI.listContent, "TOPLEFT", 0, -y)

            -- Check if in active profile
            local inProfile = false
            if profile then
                local list = entry.traitType == "passive" and profile.passiveTraits or profile.activeTraits
                for _, tid in ipairs(list or {}) do
                    if tid == entry.id then inProfile = true break end
                end
            end

            if inProfile then
                btn.txt:SetTextColor(0.4, 0.9, 0.4)
            elseif entry.traitType == "passive" then
                btn.txt:SetTextColor(0.9, 0.85, 0.7)
            else
                btn.txt:SetTextColor(0.6, 0.8, 1)
            end

            btn:SetScript("OnClick", function()
                traitsUI.selected = entry
                if traitsUI.detailTitle then
                    traitsUI.detailTitle:SetText(entry.name)
                end
                if traitsUI.detailType then
                    local typeStr = entry.traitType == "passive" and "Passive Trait" or ("Active Trait — " .. (entry.uses or 0) .. "/encounter")
                    traitsUI.detailType:SetText(typeStr)
                end
                if traitsUI.detailDesc then
                    traitsUI.detailDesc:SetText(entry.desc)
                end
            end)

            y = y + 24
        end
    end
    traitsUI.listContent:SetHeight(math.max(y, 20))
end
