-- UI_Combat.lua — Combat tracker UI tab
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

local combatUI = {}

-- ─── Build ────────────────────────────────────────────────────────────────────
function ns.BuildCombatTab(panel)

    -- ── Strike tracker ──
    local strikesLabel = ns.MakeLabel(panel, "Strike Tracker", 1, 0.82, 0.2)
    strikesLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)

    -- Strike bar background
    local barBg = CreateFrame("Frame", nil, panel, "BackdropTemplateMixin and BackdropTemplate")
    barBg:SetSize(300, 22)
    barBg:SetPoint("TOPLEFT", strikesLabel, "BOTTOMLEFT", 0, -4)
    barBg:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile=true, tileSize=8 })
    barBg:SetBackdropColor(0.1, 0.02, 0.02, 1)
    combatUI.barBg = barBg

    local barFill = barBg:CreateTexture(nil, "ARTWORK")
    barFill:SetColorTexture(0.7, 0.1, 0.1, 0.9)
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 1, -1)
    barFill:SetSize(1, 20)
    combatUI.barFill = barFill

    local strikesText = barBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    strikesText:SetPoint("CENTER", barBg, "CENTER")
    strikesText:SetText("— / —")
    strikesText:SetTextColor(1, 0.9, 0.9)
    combatUI.strikesText = strikesText

    -- +/- buttons
    local minusBtn = ns.MakeButton(panel, "−", 28, 22)
    minusBtn:SetPoint("LEFT", barBg, "RIGHT", 4, 0)
    minusBtn:SetScript("OnClick", function()
        local cur, maxS = ns.AdjustStrikes(-1)
        if cur then ns.UpdateStrikeBar(cur, maxS) end
    end)

    local plusBtn = ns.MakeButton(panel, "+", 28, 22)
    plusBtn:SetPoint("LEFT", minusBtn, "RIGHT", 2, 0)
    plusBtn:SetScript("OnClick", function()
        local cur, maxS = ns.AdjustStrikes(1)
        if cur then ns.UpdateStrikeBar(cur, maxS) end
    end)

    -- Reset to full
    local resetStrikesBtn = ns.MakeButton(panel, "Full", 50, 22)
    resetStrikesBtn:SetPoint("LEFT", plusBtn, "RIGHT", 4, 0)
    resetStrikesBtn:SetScript("OnClick", function()
        local profile = ns.GetActiveProfile()
        if not profile then return end
        local maxS = ns.CalcMaxStrikes(profile)
        ns.SetStrikes(maxS)
        ns.UpdateStrikeBar(maxS, maxS)
    end)

    -- ── Roll buttons ──
    local rollLabel = ns.MakeLabel(panel, "Combat Rolls", 1, 0.82, 0.2)
    rollLabel:SetPoint("TOPLEFT", barBg, "BOTTOMLEFT", 0, -12)

    -- Initiative
    local initBtn = ns.MakeButton(panel, "Roll Initiative", 120, 24)
    initBtn:SetPoint("TOPLEFT", rollLabel, "BOTTOMLEFT", 0, -4)
    initBtn:SetScript("OnClick", function()
        local ch = ns.GetSetting("chatChannel") or "SAY"
        local tg = ns.GetSetting("whisperTarget") or ""
        ns.RollInitiative(ch, tg)
    end)

    -- Attack (melee)
    local meleeLabel = ns.MakeLabel(panel, "Melee vs Defense:", 0.8, 0.8, 0.8)
    meleeLabel:SetPoint("TOPLEFT", initBtn, "BOTTOMLEFT", 0, -8)

    local defenseBox = ns.MakeEditBox(panel, 50, 20)
    defenseBox:SetPoint("LEFT", meleeLabel, "RIGHT", 4, 0)
    defenseBox:SetNumeric(true)
    defenseBox:SetMaxLetters(3)
    defenseBox:SetText("")
    combatUI.defenseBox = defenseBox

    local meleeBtn = ns.MakeButton(panel, "Melee Attack", 110, 24)
    meleeBtn:SetPoint("TOPLEFT", meleeLabel, "BOTTOMLEFT", 0, -4)
    meleeBtn:SetScript("OnClick", function()
        local ch = ns.GetSetting("chatChannel") or "SAY"
        local tg = ns.GetSetting("whisperTarget") or ""
        local def = tonumber(defenseBox:GetText())
        ns.RollAttack("melee", def, ch, tg)
    end)

    -- Ranged attack
    local rangedBtn = ns.MakeButton(panel, "Ranged Attack", 110, 24)
    rangedBtn:SetPoint("LEFT", meleeBtn, "RIGHT", 4, 0)
    rangedBtn:SetScript("OnClick", function()
        local ch = ns.GetSetting("chatChannel") or "SAY"
        local tg = ns.GetSetting("whisperTarget") or ""
        local def = tonumber(defenseBox:GetText())
        ns.RollAttack("ranged", def, ch, tg)
    end)

    -- DR roll
    local drBtn = ns.MakeButton(panel, "Roll DR", 100, 24)
    drBtn:SetPoint("TOPLEFT", meleeBtn, "BOTTOMLEFT", 0, -6)
    drBtn:SetScript("OnClick", function()
        local ch = ns.GetSetting("chatChannel") or "SAY"
        local tg = ns.GetSetting("whisperTarget") or ""
        ns.RollDR(nil, ch, tg)
    end)

    -- ── Class Abilities ──
    local abLabel = ns.MakeLabel(panel, "Class Abilities", 1, 0.82, 0.2)
    abLabel:SetPoint("TOPLEFT", drBtn, "BOTTOMLEFT", 0, -12)

    combatUI.abilitiesContainer = CreateFrame("Frame", nil, panel)
    combatUI.abilitiesContainer:SetSize(460, 80)
    combatUI.abilitiesContainer:SetPoint("TOPLEFT", abLabel, "BOTTOMLEFT", 0, -4)

    -- ── Active Traits ──
    local traitLabel = ns.MakeLabel(panel, "Active Traits", 1, 0.82, 0.2)
    traitLabel:SetPoint("TOPLEFT", combatUI.abilitiesContainer, "BOTTOMLEFT", 0, -8)

    combatUI.traitsContainer = CreateFrame("Frame", nil, panel)
    combatUI.traitsContainer:SetSize(460, 80)
    combatUI.traitsContainer:SetPoint("TOPLEFT", traitLabel, "BOTTOMLEFT", 0, -4)

    -- ── New Encounter ──
    local newEncBtn = ns.MakeButton(panel, "New Encounter (Reset Uses)", 200, 26)
    newEncBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, 8)
    newEncBtn:SetScript("OnClick", function()
        local ok, name = ns.ResetEncounter()
        if ok then
            ns.Print(c.green .. "Encounter reset for: " .. c.r .. (name or "?"))
            ns.RefreshCombatTab()
        else
            ns.PrintError(name or "No active profile.")
        end
    end)
end

-- ─── Refresh ──────────────────────────────────────────────────────────────────
function ns.UpdateStrikeBar(current, maxS)
    if not combatUI.barFill then return end
    if not maxS or maxS == 0 then return end

    local barWidth = 298
    local pct = math.max(0, math.min(1, current / maxS))
    combatUI.barFill:SetWidth(math.max(1, barWidth * pct))

    -- Color: green > 50%, yellow 25-50%, red < 25%
    if pct > 0.5 then
        combatUI.barFill:SetColorTexture(0.1, 0.7, 0.1, 0.9)
    elseif pct > 0.25 then
        combatUI.barFill:SetColorTexture(0.8, 0.7, 0.1, 0.9)
    else
        combatUI.barFill:SetColorTexture(0.8, 0.1, 0.1, 0.9)
    end

    combatUI.strikesText:SetText(current .. " / " .. maxS .. " Strikes")
end

function ns.RefreshCombatTab()
    local profile = ns.GetActiveProfile()

    -- Strike bar
    if profile then
        local maxS    = ns.CalcMaxStrikes(profile)
        local current = profile.currentStrikes
        if current == nil then current = maxS end
        ns.UpdateStrikeBar(current, maxS)
    else
        if combatUI.strikesText then combatUI.strikesText:SetText("No profile selected") end
        if combatUI.barFill     then combatUI.barFill:SetWidth(1) end
    end

    -- Class abilities
    if combatUI.abilitiesContainer then
        -- Clear old
        for _, child in pairs({ combatUI.abilitiesContainer:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
        if profile then
            local classData = ns.CLASS_DATA[profile.class]
            if classData then
                local xOff = 0
                for i, ab in ipairs(classData.abilities) do
                    local uses = (profile.abilityUses and profile.abilityUses[i]) or ab.uses
                    local total = ab.uses
                    local label = ab.name .. " (" .. uses .. "/" .. total .. ")"
                    local btn = ns.MakeButton(combatUI.abilitiesContainer, label, 145, 26)
                    btn:SetPoint("TOPLEFT", combatUI.abilitiesContainer, "TOPLEFT", xOff, 0)

                    -- Grey out if no uses
                    if uses <= 0 then
                        btn.txt:SetTextColor(0.4, 0.4, 0.4)
                    end

                    -- Tooltip with description
                    btn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(ab.name, 1, 0.82, 0.2)
                        GameTooltip:AddLine(ab.desc, 0.9, 0.85, 0.7, true)
                        GameTooltip:AddLine(ab.usesLabel, 0.6, 0.8, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    btn:SetScript("OnClick", function()
                        if uses <= 0 then
                            ns.PrintError(ab.name .. " has no uses remaining.")
                            return
                        end
                        local ok, err = ns.UseClassAbility(profile, i)
                        if ok then
                            ns.Print(c.yellow .. ab.name .. c.r .. " used. (" .. (uses-1) .. "/" .. total .. " remaining)")
                            ns.RefreshCombatTab()
                        else
                            ns.PrintError(err or "Cannot use ability.")
                        end
                    end)

                    xOff = xOff + 150
                end
            end
        end
    end

    -- Active traits
    if combatUI.traitsContainer then
        -- Clear old
        for _, child in pairs({ combatUI.traitsContainer:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
        if profile and profile.activeTraits and #profile.activeTraits > 0 then
            ns.RefreshTraitUses(profile)
            local xOff = 0
            local yOff = 0
            local col  = 0
            for _, tid in ipairs(profile.activeTraits) do
                local trait = ns.ACTIVE_TRAIT_BY_ID[tid]
                if trait then
                    local uses  = (profile.traitUses and profile.traitUses[tid]) or trait.uses
                    local total = trait.uses
                    local label = trait.name .. " (" .. uses .. "/" .. total .. ")"
                    local btn = ns.MakeButton(combatUI.traitsContainer, label, 145, 24)
                    btn:SetPoint("TOPLEFT", combatUI.traitsContainer, "TOPLEFT", xOff, -yOff)

                    if uses <= 0 then btn.txt:SetTextColor(0.4, 0.4, 0.4) end

                    btn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(trait.name, 1, 0.82, 0.2)
                        GameTooltip:AddLine(trait.desc, 0.9, 0.85, 0.7, true)
                        GameTooltip:AddLine(trait.uses .. "/encounter", 0.6, 0.8, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    btn:SetScript("OnClick", function()
                        if uses <= 0 then
                            ns.PrintError(trait.name .. " has no uses remaining.")
                            return
                        end
                        local ok, err = ns.UseActiveTrait(profile, tid)
                        if ok then
                            ns.Print(c.yellow .. trait.name .. c.r .. " used. (" .. (uses-1) .. "/" .. total .. " remaining)")
                            ns.RefreshCombatTab()
                        else
                            ns.PrintError(err or "Cannot use trait.")
                        end
                    end)

                    col = col + 1
                    if col >= 3 then
                        col  = 0
                        xOff = 0
                        yOff = yOff + 28
                    else
                        xOff = xOff + 150
                    end
                end
            end
        end
    end
end
