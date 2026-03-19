-- Combat.lua — Attack rolls, defense calc, DR, initiative, strike tracking
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

-- ─── Initiative ──────────────────────────────────────────────────────────────

-- Roll initiative using the active profile.
-- Returns formatted string and numeric result.
function ns.RollInitiative(channel, target)
    local profile = ns.GetActiveProfile()
    if not profile then
        ns.PrintError("No active profile. Create or select one first.")
        return
    end

    local finesse   = (profile.attributes and profile.attributes.finesse) or 0
    local hasTacticianTrait = false
    for _, tid in ipairs(profile.passiveTraits or {}) do
        if tid == "tactician" then hasTacticianTrait = true break end
    end

    local dieResult, _ = ns.RollD(20)
    local roll = dieResult.rolls[1]

    local modTotal   = finesse + (hasTacticianTrait and 1 or 0)
    local total      = roll + modTotal

    -- Build formatted message
    local rollColor  = roll == 20 and c.gold or (roll == 1 and c.red or c.orange)
    local modParts   = {}
    if finesse ~= 0 then
        modParts[#modParts + 1] = c.cyan .. finesse .. c.r .. " (Finesse)"
    end
    if hasTacticianTrait then
        modParts[#modParts + 1] = c.green .. "+1" .. c.r .. " (Tactician)"
    end
    local modStr = #modParts > 0 and (" + " .. table.concat(modParts, " + ")) or ""

    local msg = c.addon .. "[CRE]" .. c.r .. " " ..
                c.cyan .. UnitName("player") .. c.r ..
                " rolls Initiative: " ..
                rollColor .. "[" .. roll .. "]" .. c.r ..
                modStr ..
                " = " .. c.white .. total .. c.r

    ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))

    local plain = "[CRE] " .. UnitName("player") .. " rolls Initiative: [" .. roll .. "]"
    if finesse ~= 0 then plain = plain .. " + " .. finesse .. " (Finesse)" end
    if hasTacticianTrait then plain = plain .. " + 1 (Tactician)" end
    plain = plain .. " = " .. total

    if channel then ns.SendChat(plain, channel, target) end
    return total
end

-- ─── Attack Roll ─────────────────────────────────────────────────────────────

-- mode: "melee" (uses Might) or "ranged" (uses Finesse)
-- targetDefense: numeric target's Defense Score
function ns.RollAttack(mode, targetDefense, channel, target)
    local profile = ns.GetActiveProfile()
    if not profile then
        ns.PrintError("No active profile. Create or select one first.")
        return
    end

    local attr, attrName
    if mode == "ranged" then
        attr     = (profile.attributes and profile.attributes.finesse) or 0
        attrName = "Finesse"
    else
        attr     = (profile.attributes and profile.attributes.might) or 0
        attrName = "Might"
    end

    local dieResult, _ = ns.RollD(20)
    local roll    = dieResult.rolls[1]
    local total   = roll + attr

    local hit = (targetDefense and total >= targetDefense)
    local rollColor = roll == 20 and c.gold or (roll == 1 and c.red or c.orange)
    local outcomeColor = hit and c.green or c.red
    local outcome = hit and "HIT!" or "MISS"
    if roll == 20 then outcome = "CRITICAL HIT!" end
    if roll == 1  then outcome = "CRITICAL MISS!" end

    local defStr = targetDefense and (" vs Defense " .. c.blue .. targetDefense .. c.r) or ""
    local modStr = attr ~= 0 and (" + " .. c.cyan .. attr .. c.r .. " (" .. attrName .. ")") or ""

    local msg = c.addon .. "[CRE]" .. c.r .. " " ..
                c.cyan .. UnitName("player") .. c.r ..
                " rolls Attack (" .. mode .. "): " ..
                rollColor .. "[" .. roll .. "]" .. c.r ..
                modStr ..
                " = " .. c.white .. total .. c.r ..
                defStr ..
                " — " .. outcomeColor .. outcome .. c.r

    ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))

    local plain = "[CRE] " .. UnitName("player") .. " rolls Attack (" .. mode .. "): [" .. roll .. "]"
    if attr ~= 0 then plain = plain .. " + " .. attr .. " (" .. attrName .. ")" end
    plain = plain .. " = " .. total
    if targetDefense then plain = plain .. " vs Defense " .. targetDefense .. " — " .. outcome end

    if channel then ns.SendChat(plain, channel, target) end
    return total, hit, roll == 20
end

-- ─── Damage Reduction Roll ────────────────────────────────────────────────────

-- Rolls d6 and checks if result falls within armor's DR range.
-- Uses active profile's armor, or `armorOverride` if provided.
function ns.RollDR(armorOverride, channel, target)
    local profile = ns.GetActiveProfile()
    if not profile and not armorOverride then
        ns.PrintError("No active profile. Create or select one first.")
        return
    end

    local armorType = armorOverride or (profile and profile.armor) or "None"
    local armorData = ns.ARMOR_DATA[armorType] or ns.ARMOR_DATA["None"]

    if armorData.drRange == 0 then
        local msg = "[CRE] " .. UnitName("player") .. " — " .. armorType .. " provides no Damage Reduction."
        ns.Print(msg)
        if channel then ns.SendChat(msg, channel, target) end
        return false
    end

    local roll = math.random(1, 6)
    local reduced = (roll <= armorData.drRange)
    local rollColor = reduced and c.green or c.orange
    local outcome = reduced and "Reduced! (-1 Strike)" or "Not reduced."
    local outcomeColor = reduced and c.green or c.grey

    local msg = c.addon .. "[CRE]" .. c.r .. " " ..
                c.cyan .. UnitName("player") .. c.r ..
                " rolls DR (" .. armorType .. "): " ..
                rollColor .. "[" .. roll .. "]" .. c.r ..
                " — " .. outcomeColor .. outcome .. c.r

    ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))

    local plain = "[CRE] " .. UnitName("player") .. " rolls DR (" .. armorType .. "): [" .. roll .. "] — " .. outcome
    if channel then ns.SendChat(plain, channel, target) end
    return reduced, roll
end

-- ─── Strike Management ────────────────────────────────────────────────────────

function ns.AdjustStrikes(delta)
    local profile, name = ns.GetActiveProfile()
    if not profile then
        ns.PrintError("No active profile.")
        return
    end
    local maxStrikes = ns.CalcMaxStrikes(profile)
    local current    = profile.currentStrikes or maxStrikes
    local newVal     = math.max(-1, math.min(maxStrikes, current + delta))
    profile.currentStrikes = newVal
    ns.SaveProfile(profile)
    return newVal, maxStrikes
end

function ns.SetStrikes(value)
    local profile, name = ns.GetActiveProfile()
    if not profile then return end
    local maxStrikes = ns.CalcMaxStrikes(profile)
    profile.currentStrikes = math.max(-1, math.min(maxStrikes, value))
    ns.SaveProfile(profile)
    return profile.currentStrikes, maxStrikes
end

-- ─── Full profile summary (chat output) ──────────────────────────────────────

function ns.PrintProfileSummary()
    local profile, name = ns.GetActiveProfile()
    if not profile then
        ns.PrintError("No active profile. Use /cre profile to create one.")
        return
    end

    local classData = ns.CLASS_DATA[profile.class] or {}
    local classColor = ns.classColors[profile.class] or c.white
    local maxStrikes = ns.CalcMaxStrikes(profile)
    local defense    = ns.CalcDefense(profile)
    local inventory  = ns.CalcInventory(profile)

    ns.Print(c.gold .. "═══ " .. profile.name .. " ═══" .. c.r)
    ns.Print("Class: " .. classColor .. profile.class .. c.r .. " (" .. (classData.flavor or "") .. ")")
    ns.Print("Strikes: " .. c.red .. (profile.currentStrikes or maxStrikes) .. c.r .. "/" .. c.red .. maxStrikes .. c.r)
    ns.Print("Defense: " .. c.blue .. defense .. c.r .. "  |  Armor: " .. profile.armor)
    ns.Print("Inventory: " .. inventory .. " slots")

    local attrParts = {}
    for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
        local v = (profile.attributes and profile.attributes[key]) or 0
        attrParts[#attrParts + 1] = ns.ATTRIBUTE_NAMES[key] .. " " .. ns.SignedNum(v)
    end
    ns.Print("Attributes: " .. table.concat(attrParts, "  "))

    -- Passive traits
    if profile.passiveTraits and #profile.passiveTraits > 0 then
        local names = {}
        for _, tid in ipairs(profile.passiveTraits) do
            local t = ns.PASSIVE_TRAIT_BY_ID[tid]
            if t then names[#names + 1] = t.name end
        end
        ns.Print("Passives: " .. table.concat(names, ", "))
    end

    -- Active traits with remaining uses
    if profile.activeTraits and #profile.activeTraits > 0 then
        local parts = {}
        for _, tid in ipairs(profile.activeTraits) do
            local t = ns.ACTIVE_TRAIT_BY_ID[tid]
            if t then
                local uses = (profile.traitUses and profile.traitUses[tid]) or t.uses
                parts[#parts + 1] = t.name .. " (" .. uses .. "/" .. t.uses .. ")"
            end
        end
        ns.Print("Actives: " .. table.concat(parts, ", "))
    end
end
