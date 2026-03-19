-- UI_Reference.lua — Quick-reference rules viewer UI tab
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

local refUI = {
    section = "classes",  -- "classes", "armor", "attributes", "combat"
}

local SECTIONS = {"Classes", "Armor", "Attributes", "Combat Rules"}
local SECTION_KEYS = {"classes", "armor", "attributes", "combat"}

-- ─── Build ────────────────────────────────────────────────────────────────────
function ns.BuildReferenceTab(panel)

    -- Section nav buttons
    local navBtns = {}
    local xOff = 0
    for i, sec in ipairs(SECTIONS) do
        local btn = ns.MakeButton(panel, sec, 100, 22)
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", xOff + 4, -6)
        btn:SetScript("OnClick", function()
            refUI.section = SECTION_KEYS[i]
            ns.RefreshReferenceContent()
        end)
        navBtns[i] = btn
        xOff = xOff + 104
    end

    -- Class filter dropdown (only visible in Classes section)
    local classLabel = ns.MakeLabel(panel, "Class:", 0.8, 0.8, 0.8)
    classLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -34)

    local classDD = ns.MakeDropdown(panel, ns.CLASS_ORDER, ns.CLASS_ORDER[1], function(selected)
        refUI.selectedClass = selected
        if refUI.section == "classes" then ns.RefreshReferenceContent() end
    end)
    classDD:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", -16, -2)
    refUI.classDD    = classDD
    refUI.classLabel = classLabel

    -- Content scroll area
    local scroll, content = ns.MakeScrollFrame(panel, 470, 440)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -86)
    refUI.content = content

    refUI.selectedClass = ns.CLASS_ORDER[1]
end

-- ─── Refresh ──────────────────────────────────────────────────────────────────
function ns.RefreshReferenceTab()
    ns.RefreshReferenceContent()
end

local function ClearContent()
    if not refUI.content then return end
    for _, child in pairs({ refUI.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    -- Also clear font strings (not GetChildren)
    for _, region in pairs({ refUI.content:GetRegions() }) do
        region:Hide()
    end
end

local function AddLine(parent, text, y, r, g, b, wrap)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
    fs:SetWidth(440)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    fs:SetTextColor(r or 0.9, g or 0.85, b or 0.7)
    if wrap ~= false then fs:SetWordWrap(true) end
    return fs
end

function ns.RefreshReferenceContent()
    if not refUI.content then return end
    ClearContent()

    local section = refUI.section or "classes"
    local y = 0
    local lineH = 16

    -- Show/hide class dropdown
    if refUI.classLabel then refUI.classLabel:SetShown(section == "classes") end
    if refUI.classDD    then refUI.classDD:SetShown(section == "classes") end

    if section == "classes" then
        local className = refUI.selectedClass or ns.CLASS_ORDER[1]
        local data = ns.CLASS_DATA[className]
        if not data then return end
        local classColor = ns.classColors[className] or c.white

        local title = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        title:SetText(classColor .. className .. "|r  |cFFAAAAAA— " .. data.flavor .. "|r")
        title:SetWidth(440)
        y = y - 24

        local strikes = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        strikes:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        strikes:SetText("|cFFFF4444⚔ " .. data.strikes .. " Strikes|r")
        y = y - 20

        -- Divider
        local div = refUI.content:CreateTexture(nil, "ARTWORK")
        div:SetColorTexture(0.4, 0.3, 0.1, 0.6)
        div:SetSize(440, 1)
        div:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        y = y - 12

        -- Abilities
        for _, ab in ipairs(data.abilities) do
            local abTitle = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            abTitle:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
            abTitle:SetText("|cFFFFD700" .. ab.name .. "|r  |cFF6699FF(" .. ab.usesLabel .. ")|r")
            y = y - 18

            local abDesc = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            abDesc:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 12, y)
            abDesc:SetWidth(430)
            abDesc:SetJustifyH("LEFT")
            abDesc:SetText(ab.desc)
            abDesc:SetTextColor(0.9, 0.85, 0.7)
            abDesc:SetWordWrap(true)
            y = y - 32
        end

    elseif section == "armor" then
        local title = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        title:SetText("|cFFFFD700Armor Table|r")
        y = y - 22

        -- Header
        local function MakeRow(ay, armorName, defBonus, drLabel, notes, isHeader)
            local r = isHeader and 1   or 0.9
            local g = isHeader and 0.82 or 0.85
            local b = isHeader and 0.2  or 0.7

            local fs1 = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs1:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, ay)
            fs1:SetText(armorName)
            fs1:SetTextColor(r, g, b)
            fs1:SetWidth(80)

            local fs2 = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs2:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 90, ay)
            fs2:SetText(defBonus)
            fs2:SetTextColor(r, g, b)
            fs2:SetWidth(80)

            local fs3 = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs3:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 175, ay)
            fs3:SetText(drLabel)
            fs3:SetTextColor(r, g, b)
            fs3:SetWidth(60)

            local fs4 = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs4:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 245, ay)
            fs4:SetText(notes)
            fs4:SetTextColor(r, g, b)
            fs4:SetWidth(200)
            fs4:SetWordWrap(true)
        end

        MakeRow(y, "Armor", "Def Bonus", "DR Range", "Notes", true)
        y = y - lineH
        for _, name in ipairs(ns.ARMOR_TYPES) do
            local d = ns.ARMOR_DATA[name]
            MakeRow(y, name, "+" .. d.defenseBonus, d.drLabel, d.notes, false)
            y = y - lineH
        end
        y = y - 8
        local note = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        note:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        note:SetText("|cFFAAAAFFDefense Score|r = Finesse + 5 + Armor Bonus")
        note:SetWidth(440)
        y = y - lineH
        local note2 = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        note2:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        note2:SetText("|cFFAAAAFFDR Roll|r: roll d6 after being hit; if result ≤ DR Range, reduce damage by 1 Strike.")
        note2:SetWidth(440)
        note2:SetWordWrap(true)

    elseif section == "attributes" then
        local title = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        title:SetText("|cFFFFD700The Nine Pillars|r")
        y = y - 22

        local sub = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sub:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        sub:SetText("10 points to distribute. Max +6 per attribute at creation.")
        sub:SetTextColor(0.7, 0.7, 0.7)
        y = y - 20

        local lastCat = ""
        for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
            local cat = ns.ATTRIBUTE_CATEGORIES[key]
            if cat ~= lastCat then
                lastCat = cat
                y = y - 4
                local catLabel = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                catLabel:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
                catLabel:SetText("|cFF88AAFF" .. cat .. "|r")
                y = y - 18
            end

            local nameLabel = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 12, y)
            nameLabel:SetText("|cFFFFD700" .. ns.ATTRIBUTE_NAMES[key] .. "|r")
            y = y - 16

            local descLabel = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            descLabel:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 20, y)
            descLabel:SetWidth(430)
            descLabel:SetJustifyH("LEFT")
            descLabel:SetText(ns.ATTRIBUTE_DESCRIPTIONS[key])
            descLabel:SetTextColor(0.9, 0.85, 0.7)
            descLabel:SetWordWrap(true)
            y = y - 28
        end

    elseif section == "combat" then
        local title = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
        title:SetText("|cFFFFD700Combat Rules Summary|r")
        y = y - 22

        local rules = {
            { "|cFFFFD700Attack Roll|r", "d20 + Might (melee) or Finesse (ranged) vs target Defense Score." },
            { "|cFFFFD700Defense Score|r", "Finesse + 5 + Armor Defense Bonus (+ Shield bonus if applicable)." },
            { "|cFFFFD700Strikes (HP)|r", "Class determines starting value. Losing all Strikes = incapacitated. Reaching −1 = death (unless Tenacious)." },
            { "|cFFFFD700Damage Reduction|r", "When hit, you may roll d6. If result ≤ your armor's DR Range, reduce incoming damage by 1 Strike." },
            { "|cFFFFD700Initiative|r", "d20 + Finesse + 1 if Tactician passive trait is active." },
            { "|cFFFFD700Critical Hit|r", "Natural 20 = Critical Hit. Deals +2 Strikes (only +1 if target has Pain Hardened)." },
            { "|cFFFFD700Critical Miss|r", "Natural 1 = Critical Miss. GM decides consequence." },
            { "|cFFFFD700Advantage|r", "Roll 2d20, keep the higher result." },
            { "|cFFFFD700Disadvantage|r", "Roll 2d20, keep the lower result." },
            { "|cFFFFFFFFInventory|r", "10 + Endurance slots." },
        }

        for _, row in ipairs(rules) do
            local nameLabel = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 4, y)
            nameLabel:SetText(row[1])
            y = y - 16

            local descLabel = refUI.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            descLabel:SetPoint("TOPLEFT", refUI.content, "TOPLEFT", 12, y)
            descLabel:SetWidth(430)
            descLabel:SetJustifyH("LEFT")
            descLabel:SetText(row[2])
            descLabel:SetTextColor(0.9, 0.85, 0.7)
            descLabel:SetWordWrap(true)
            y = y - 30
        end
    end

    refUI.content:SetHeight(math.abs(y) + 40)
end
