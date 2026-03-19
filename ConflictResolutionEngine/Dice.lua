-- Dice.lua — Dice engine: parse "2d6+3", "4d6k3", advantage/disadvantage, history
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

-- Roll history (session only, last 50 rolls)
ns.rollHistory = {}
local MAX_HISTORY = 50

-- ─── Core RNG ────────────────────────────────────────────────────────────────

-- Roll a single die with `sides` faces (1–sides)
local function RollDie(sides)
    return math.random(1, sides)
end

-- ─── History ─────────────────────────────────────────────────────────────────

local function PushHistory(entry)
    table.insert(ns.rollHistory, 1, entry)
    if #ns.rollHistory > MAX_HISTORY then
        table.remove(ns.rollHistory)
    end
end

-- ─── Expression Parser ───────────────────────────────────────────────────────
-- Supports:
--   NdS          e.g. 2d6
--   NdS+M / NdS-M  e.g. 2d6+3
--   NdSkK        e.g. 4d6k3  (keep highest K dice)
--   NdSlK        e.g. 4d6l3  (keep lowest K dice)

function ns.ParseDiceExpr(expr)
    expr = expr:lower():gsub("%s+", "")

    -- Pattern: NdSkK or NdSlK (keep highest/lowest)
    local count, sides, keepType, keepN = expr:match("^(%d+)d(%d+)([kl])(%d+)$")
    if count then
        return {
            type     = "keep",
            count    = tonumber(count),
            sides    = tonumber(sides),
            keepType = keepType,  -- "k" = highest, "l" = lowest
            keepN    = tonumber(keepN),
            modifier = 0,
        }
    end

    -- Pattern: NdS+M or NdS-M
    local count2, sides2, sign, mod = expr:match("^(%d+)d(%d+)([%+%-])(%d+)$")
    if count2 then
        return {
            type     = "standard",
            count    = tonumber(count2),
            sides    = tonumber(sides2),
            modifier = tonumber(mod) * (sign == "-" and -1 or 1),
        }
    end

    -- Pattern: NdS
    local count3, sides3 = expr:match("^(%d+)d(%d+)$")
    if count3 then
        return {
            type     = "standard",
            count    = tonumber(count3),
            sides    = tonumber(sides3),
            modifier = 0,
        }
    end

    return nil  -- invalid
end

-- ─── Roll execution ───────────────────────────────────────────────────────────

-- Roll a parsed expression table.  Returns result table:
--   { rolls={...}, kept={...}, modifier=N, total=N, expr="..." }
local function ExecuteParsed(parsed)
    if not parsed then return nil end

    local rolls = {}
    for i = 1, parsed.count do
        rolls[i] = RollDie(parsed.sides)
    end

    local kept = {}
    if parsed.type == "keep" then
        -- Sort and keep top/bottom K
        local sorted = {}
        for _, v in ipairs(rolls) do sorted[#sorted + 1] = v end
        table.sort(sorted, function(a, b) return a > b end)
        if parsed.keepType == "k" then
            for i = 1, parsed.keepN do kept[i] = sorted[i] end
        else
            for i = #sorted - parsed.keepN + 1, #sorted do
                kept[#kept + 1] = sorted[i]
            end
        end
    else
        for _, v in ipairs(rolls) do kept[#kept + 1] = v end
    end

    local sum = 0
    for _, v in ipairs(kept) do sum = sum + v end
    local total = sum + (parsed.modifier or 0)

    return {
        rolls    = rolls,
        kept     = kept,
        modifier = parsed.modifier or 0,
        total    = total,
    }
end

-- Roll a dice expression string.  Returns result table or nil + error msg.
function ns.RollExpr(expr)
    local parsed = ns.ParseDiceExpr(expr)
    if not parsed then
        return nil, "Invalid dice expression: " .. tostring(expr)
    end
    if parsed.count < 1 or parsed.count > 100 then
        return nil, "Dice count must be between 1 and 100."
    end
    if parsed.sides < 2 or parsed.sides > 10000 then
        return nil, "Dice sides must be between 2 and 10000."
    end

    local result = ExecuteParsed(parsed)
    result.expr  = expr
    PushHistory({ expr = expr, result = result, time = time() })
    return result, nil
end

-- ─── Simple single-die helpers ────────────────────────────────────────────────

-- Roll N dice of `sides` sides, return {rolls={...}, total=N}
function ns.RollDice(count, sides)
    local result, err = ns.RollExpr(count .. "d" .. sides)
    return result, err
end

-- Roll a single die
function ns.RollD(sides)
    return ns.RollDice(1, sides)
end

-- ─── Advantage / Disadvantage ─────────────────────────────────────────────────

-- Roll 2d20 with advantage (keep higher) or disadvantage (keep lower)
-- Returns { roll1, roll2, kept, mode="advantage"|"disadvantage" }
function ns.RollAdvantage(mode, modifier)
    modifier = modifier or 0
    local r1 = RollDie(20)
    local r2 = RollDie(20)
    local kept
    if mode == "advantage" then
        kept = math.max(r1, r2)
    else
        kept = math.min(r1, r2)
    end
    local total = kept + modifier
    local result = {
        roll1    = r1,
        roll2    = r2,
        kept     = kept,
        modifier = modifier,
        total    = total,
        mode     = mode,
        expr     = "2d20" .. (modifier >= 0 and "+" or "") .. modifier .. " (" .. mode .. ")",
    }
    PushHistory({ expr = result.expr, result = result, time = time() })
    return result
end

-- ─── Chat formatting ─────────────────────────────────────────────────────────

local c = ns.colors

-- Format dice array as [4, 2, 6]
local function FormatRolls(rolls)
    local parts = {}
    for _, v in ipairs(rolls) do
        parts[#parts + 1] = tostring(v)
    end
    return "[" .. table.concat(parts, ", ") .. "]"
end

-- Return color for d20 roll (nat 20 = gold, nat 1 = red, else orange)
local function D20Color(roll, sides)
    if sides == 20 then
        if roll == 20 then return c.gold end
        if roll == 1  then return c.red  end
    end
    return c.orange
end

-- Build a printable string for a standard roll result
function ns.FormatRollResult(result, label)
    label = label or result.expr
    -- For nat 20/1 coloring: extract the raw single-die roll if applicable
    local rawRoll = (result.rolls and #result.rolls == 1) and result.rolls[1] or 0
    local rollColor = D20Color(rawRoll, rawRoll)

    -- Detect if it's a d20 roll (single die, sides=20) for natural 1/20 coloring
    local kept = result.kept or result.rolls or {}
    local keptStr = FormatRolls(kept)

    local modStr = ""
    if result.modifier ~= 0 then
        modStr = " " .. (result.modifier > 0 and "+" or "") .. result.modifier
    end

    local totalColor = c.white
    return c.addon .. "[CRE]" .. c.r .. " " ..
           c.cyan  .. UnitName("player") .. c.r ..
           " rolls " ..
           c.yellow .. label .. c.r .. ": " ..
           c.orange .. keptStr .. c.r ..
           modStr ..
           " = " ..
           totalColor .. result.total .. c.r
end

-- Format advantage/disadvantage result
function ns.FormatAdvResult(result, label)
    label = label or (result.mode == "advantage" and "Advantage" or "Disadvantage")
    local r1Color = (result.roll1 == result.kept) and c.green or c.grey
    local r2Color = (result.roll2 == result.kept) and c.green or c.grey
    local natColor = result.kept == 20 and c.gold or (result.kept == 1 and c.red or c.white)

    local modStr = ""
    if result.modifier ~= 0 then
        modStr = (result.modifier > 0 and " +" or " ") .. result.modifier
    end

    return c.addon .. "[CRE]" .. c.r .. " " ..
           c.cyan  .. UnitName("player") .. c.r ..
           " rolls " ..
           c.yellow .. label .. c.r .. ": [" ..
           r1Color .. result.roll1 .. c.r .. ", " ..
           r2Color .. result.roll2 .. c.r .. "]" ..
           modStr ..
           " = " .. natColor .. result.total .. c.r
end

-- ─── Quick-roll helper (also broadcasts) ─────────────────────────────────────

-- Roll expression, format message, optionally broadcast
-- channel: "SAY", "PARTY", etc.   target: whisper target
function ns.QuickRoll(expr, channel, target)
    local result, err = ns.RollExpr(expr)
    if not result then
        ns.Print(c.red .. err .. c.r)
        return
    end
    local msg = ns.FormatRollResult(result, expr)
    ns.Print(msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))  -- plain text to chat frame
    -- Build plain-text version for SendChat
    local kept = result.kept or result.rolls or {}
    local parts = {}
    for _, v in ipairs(kept) do parts[#parts + 1] = tostring(v) end
    local modStr = result.modifier ~= 0 and (" " .. (result.modifier > 0 and "+" or "") .. result.modifier) or ""
    local plain = "[CRE] " .. UnitName("player") .. " rolls " .. expr .. ": [" .. table.concat(parts, ", ") .. "]" .. modStr .. " = " .. result.total
    if channel then
        ns.SendChat(plain, channel, target)
    end
    return result
end
