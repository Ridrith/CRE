-- UI_Dice.lua — Dice roller UI tab
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

local diceState = {
    channel     = "SAY",
    target      = "",
    customExpr  = "",
    historyText = nil,
}

-- ─── Build ────────────────────────────────────────────────────────────────────
function ns.BuildDiceTab(panel)

    -- ── Channel selector ──
    local chanLabel = ns.MakeLabel(panel, "Output Channel:", 0.8, 0.8, 0.8)
    chanLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)

    local chanItems = {}
    for _, ch in ipairs(ns.CHAT_CHANNELS) do
        chanItems[#chanItems + 1] = ns.CHAT_CHANNEL_LABELS[ch]
    end

    local chanDD = ns.MakeDropdown(panel, chanItems, "Say", function(selected)
        -- Map label back to key
        for k, v in pairs(ns.CHAT_CHANNEL_LABELS) do
            if v == selected then
                diceState.channel = k
                ns.SetSetting("chatChannel", k)
                break
            end
        end
        -- Show/hide whisper target box
        if diceState.channel == "WHISPER" then
            diceState.targetBox:Show()
            diceState.targetLabel:Show()
        else
            diceState.targetBox:Hide()
            diceState.targetLabel:Hide()
        end
    end)
    chanDD:SetPoint("TOPLEFT", chanLabel, "BOTTOMLEFT", -16, -2)
    diceState.chanDD = chanDD

    -- Whisper target (hidden unless WHISPER selected)
    local targetLabel = ns.MakeLabel(panel, "Whisper target:", 0.8, 0.8, 0.8)
    targetLabel:SetPoint("TOPLEFT", chanDD, "BOTTOMLEFT", 16, -6)
    targetLabel:Hide()
    diceState.targetLabel = targetLabel

    local targetBox = ns.MakeEditBox(panel, 130, 20)
    targetBox:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -2)
    targetBox:Hide()
    targetBox:SetMaxLetters(50)
    targetBox:SetScript("OnTextChanged", function(self)
        diceState.target = self:GetText()
        ns.SetSetting("whisperTarget", diceState.target)
    end)
    diceState.targetBox = targetBox

    -- ── Common dice buttons ──
    local diceLabel = ns.MakeLabel(panel, "Quick Roll:", 0.8, 0.8, 0.8)
    diceLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -80)

    local diceRow = CreateFrame("Frame", nil, panel)
    diceRow:SetSize(400, 26)
    diceRow:SetPoint("TOPLEFT", diceLabel, "BOTTOMLEFT", 0, -4)

    local xOff = 0
    for _, sides in ipairs(ns.COMMON_DICE) do
        local btn = ns.MakeButton(diceRow, "d" .. sides, 50, 26)
        btn:SetPoint("LEFT", diceRow, "LEFT", xOff, 0)
        btn:SetScript("OnClick", function()
            local ch = ns.GetSetting("chatChannel") or "SAY"
            local tg = ns.GetSetting("whisperTarget") or ""
            local result, err = ns.RollDice(1, sides)
            if not result then ns.PrintError(err) return end
            local roll = result.rolls[1]
            local rollColor = (sides == 20 and roll == 20) and c.gold or (sides == 20 and roll == 1) and c.red or c.orange
            local msg = c.addon .. "[CRE]" .. c.r .. " " .. c.cyan .. UnitName("player") .. c.r ..
                        " rolls " .. c.yellow .. "d" .. sides .. c.r .. ": " ..
                        rollColor .. "[" .. roll .. "]" .. c.r
            ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
            ns.SendChat("[CRE] " .. UnitName("player") .. " rolls d" .. sides .. ": [" .. roll .. "]", ch, tg)
            ns.RefreshDiceHistory()
        end)
        xOff = xOff + 54
    end

    -- ── Advantage / Disadvantage ──
    local advLabel = ns.MakeLabel(panel, "d20 Advantage / Disadvantage:", 0.8, 0.8, 0.8)
    advLabel:SetPoint("TOPLEFT", diceRow, "BOTTOMLEFT", 0, -10)

    local advModLabel = ns.MakeLabel(panel, "Modifier:", 0.7, 0.7, 0.7)
    advModLabel:SetPoint("TOPLEFT", advLabel, "BOTTOMLEFT", 0, -4)

    local advModBox = ns.MakeEditBox(panel, 40, 20)
    advModBox:SetPoint("LEFT", advModLabel, "RIGHT", 4, 0)
    advModBox:SetMaxLetters(4)
    advModBox:SetNumeric(false)
    diceState.advModBox = advModBox

    local advBtn = ns.MakeButton(panel, "Advantage", 90, 24)
    advBtn:SetPoint("TOPLEFT", advLabel, "BOTTOMLEFT", 120, -4)
    advBtn:SetScript("OnClick", function()
        local ch  = ns.GetSetting("chatChannel") or "SAY"
        local tg  = ns.GetSetting("whisperTarget") or ""
        local mod = tonumber(advModBox:GetText()) or 0
        local result = ns.RollAdvantage("advantage", mod)
        local msg = ns.FormatAdvResult(result, "Advantage (d20)")
        ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        local plain = "[CRE] " .. UnitName("player") .. " rolls Advantage: [" .. result.roll1 .. ", " .. result.roll2 .. "]"
        if mod ~= 0 then plain = plain .. (mod > 0 and " +" or " ") .. mod end
        plain = plain .. " = " .. result.total
        ns.SendChat(plain, ch, tg)
        ns.RefreshDiceHistory()
    end)

    local disBtn = ns.MakeButton(panel, "Disadvantage", 100, 24)
    disBtn:SetPoint("LEFT", advBtn, "RIGHT", 4, 0)
    disBtn:SetScript("OnClick", function()
        local ch  = ns.GetSetting("chatChannel") or "SAY"
        local tg  = ns.GetSetting("whisperTarget") or ""
        local mod = tonumber(advModBox:GetText()) or 0
        local result = ns.RollAdvantage("disadvantage", mod)
        local msg = ns.FormatAdvResult(result, "Disadvantage (d20)")
        ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        local plain = "[CRE] " .. UnitName("player") .. " rolls Disadvantage: [" .. result.roll1 .. ", " .. result.roll2 .. "]"
        if mod ~= 0 then plain = plain .. (mod > 0 and " +" or " ") .. mod end
        plain = plain .. " = " .. result.total
        ns.SendChat(plain, ch, tg)
        ns.RefreshDiceHistory()
    end)

    -- ── Custom expression ──
    local customLabel = ns.MakeLabel(panel, "Custom Roll (e.g. 2d6+3, 4d6k3):", 0.8, 0.8, 0.8)
    customLabel:SetPoint("TOPLEFT", advModLabel, "BOTTOMLEFT", 0, -28)

    local customBox = ns.MakeEditBox(panel, 180, 20)
    customBox:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -4)
    customBox:SetMaxLetters(40)
    diceState.customBox = customBox

    local rollCustomBtn = ns.MakeButton(panel, "Roll", 70, 22)
    rollCustomBtn:SetPoint("LEFT", customBox, "RIGHT", 6, 0)
    rollCustomBtn:SetScript("OnClick", function()
        local expr = ns.Trim(customBox:GetText())
        if expr == "" then return end
        local ch = ns.GetSetting("chatChannel") or "SAY"
        local tg = ns.GetSetting("whisperTarget") or ""
        ns.QuickRoll(expr, ch, tg)
        ns.RefreshDiceHistory()
    end)
    customBox:SetScript("OnEnterPressed", function()
        rollCustomBtn:Click()
    end)

    -- ── Result display ──
    local resultLabel = ns.MakeLabel(panel, "Last Result:", 0.8, 0.8, 0.8)
    resultLabel:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -52)

    local resultText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    resultText:SetPoint("TOPLEFT", resultLabel, "BOTTOMLEFT", 0, -4)
    resultText:SetTextColor(1, 0.82, 0.2)
    resultText:SetText("—")
    resultText:SetWidth(350)
    resultText:SetJustifyH("LEFT")
    diceState.resultText = resultText

    -- ── Roll history ──
    local histLabel = ns.MakeLabel(panel, "Roll History (last 20):", 0.8, 0.8, 0.8)
    histLabel:SetPoint("TOPLEFT", resultText, "BOTTOMLEFT", 0, -12)

    local histScroll, histContent = ns.MakeScrollFrame(panel, 350, 120)
    histScroll:SetPoint("TOPLEFT", histLabel, "BOTTOMLEFT", 0, -4)
    diceState.historyText = histContent
end

-- ─── Refresh ──────────────────────────────────────────────────────────────────
function ns.RefreshDiceTab()
    -- Restore channel setting
    local ch = ns.GetSetting("chatChannel") or "SAY"
    diceState.channel = ch
    if diceState.chanDD then
        UIDropDownMenu_SetText(diceState.chanDD, ns.CHAT_CHANNEL_LABELS[ch] or "Say")
    end
    ns.RefreshDiceHistory()
end

function ns.RefreshDiceHistory()
    if not diceState.historyText then return end

    -- Clear
    for _, child in pairs({ diceState.historyText:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local history = ns.rollHistory
    local y = 0
    local limit = math.min(20, #history)
    for i = 1, limit do
        local entry = history[i]
        local result = entry.result
        local text = diceState.historyText:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", diceState.historyText, "TOPLEFT", 0, -y)
        text:SetWidth(320)
        text:SetJustifyH("LEFT")

        local kept = result.kept or result.rolls or {}
        local parts = {}
        for _, v in ipairs(kept) do parts[#parts + 1] = tostring(v) end
        local rollStr = "[" .. table.concat(parts, ", ") .. "]"
        local modStr  = (result.modifier and result.modifier ~= 0) and
                        (" " .. (result.modifier > 0 and "+" or "") .. result.modifier) or ""

        -- Result display with nat 20/1 coloring for d20 rolls (only when no modifier)
        local totalColor = "|cFFFFFFFF"
        if result.total and (not result.modifier or result.modifier == 0) then
            if result.total == 20 then totalColor = "|cFFFFD700"
            elseif result.total == 1 then totalColor = "|cFFFF3333" end
        end

        text:SetText(entry.expr .. ": " .. rollStr .. modStr .. " = " .. totalColor .. (result.total or "?") .. "|r")
        text:SetTextColor(0.8, 0.75, 0.6)
        y = y + 16
    end
    diceState.historyText:SetHeight(math.max(y, 20))

    -- Update last result display
    if diceState.resultText and #history > 0 then
        local latest = history[1].result
        local kept = latest.kept or latest.rolls or {}
        local parts = {}
        for _, v in ipairs(kept) do parts[#parts + 1] = tostring(v) end
        local rollStr = "[" .. table.concat(parts, ", ") .. "]"
        local modStr  = (latest.modifier and latest.modifier ~= 0) and
                        (" " .. (latest.modifier > 0 and "+" or "") .. latest.modifier) or ""
        local totalColor = latest.total == 20 and "|cFFFFD700" or (latest.total == 1 and "|cFFFF3333" or "|cFFFFFFFF")
        diceState.resultText:SetText(history[1].expr .. ": " .. rollStr .. modStr .. " = " ..
            totalColor .. (latest.total or "?") .. "|r")
    end
end
