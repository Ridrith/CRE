-- Utils.lua — Color helpers, formatted printing, string utilities
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

-- ─── Color palette ───────────────────────────────────────────────────────────
ns.colors = {
    addon    = "|cFF8800FF",  -- Purple   — addon prefix [CRE]
    gold     = "|cFFFFD700",  -- Gold     — natural 20 / headings
    red      = "|cFFFF3333",  -- Red      — natural 1 / damage
    green    = "|cFF33FF33",  -- Green    — success / healing
    orange   = "|cFFFF8800",  -- Orange   — normal results
    cyan     = "|cFF00FFFF",  -- Cyan     — attribute values
    white    = "|cFFFFFFFF",  -- White    — totals
    grey     = "|cFFAAAAAA",  -- Grey     — secondary info
    blue     = "|cFF4499FF",  -- Blue     — defense / info
    pink     = "|cFFFF69B4",  -- Pink     — profile messages
    yellow   = "|cFFFFFF00",  -- Yellow   — general highlight
    r        = "|r",           -- Reset
}

-- WoW class colors (by localized English class name)
ns.classColors = {
    ["Warrior"]     = "|cFFC79C6E",
    ["Paladin"]     = "|cFFF58CBA",
    ["Hunter"]      = "|cFFABD473",
    ["Rogue"]       = "|cFFFFF569",
    ["Priest"]      = "|cFFFFFFFF",
    ["Death Knight"]= "|cFFC41F3B",
    ["Shaman"]      = "|cFF0070DE",
    ["Mage"]        = "|cFF40C7EB",
    ["Warlock"]     = "|cFF8787ED",
    ["Monk"]        = "|cFF00FF96",
    ["Druid"]       = "|cFFFF7D0A",
    ["Demon Hunter"]= "|cFFA330C9",
    ["Evoker"]      = "|cFF33937F",
}

-- ─── Formatted print ─────────────────────────────────────────────────────────
local c = ns.colors

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(c.addon .. "[CRE]" .. c.r .. " " .. msg)
end

function ns.PrintError(msg)
    ns.Print(c.red .. "Error: " .. c.r .. msg)
end

-- Send a message to the selected chat channel
function ns.SendChat(msg, channel, target)
    channel = channel or "SAY"
    if channel == "WHISPER" and (not target or target == "") then
        ns.PrintError("No whisper target set.")
        return
    end
    if channel == "PARTY" and not UnitInParty("player") and not UnitInRaid("player") then
        -- Fall back to SAY if not in group
        SendChatMessage(msg, "SAY")
        return
    end
    if channel == "RAID" and not UnitInRaid("player") then
        if UnitInParty("player") then
            SendChatMessage(msg, "PARTY")
        else
            SendChatMessage(msg, "SAY")
        end
        return
    end
    if channel == "OFFICER" then
        local inGuild = IsInGuild()
        if not inGuild then
            SendChatMessage(msg, "SAY")
            return
        end
    end
    if channel == "WHISPER" then
        SendChatMessage(msg, "WHISPER", nil, target)
    else
        SendChatMessage(msg, channel)
    end
end

-- ─── String utilities ────────────────────────────────────────────────────────

-- Trim whitespace from both ends
function ns.Trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Split a string by a separator, returns a table
function ns.Split(str, sep)
    local result = {}
    local pattern = "([^" .. sep .. "]+)"
    for part in str:gmatch(pattern) do
        result[#result + 1] = part
    end
    return result
end

-- Simple Base64-like encoding for profile export (portable ASCII)
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function ns.EncodeString(str)
    local encoded = {}
    for i = 1, #str, 3 do
        local b1 = str:byte(i) or 0
        local b2 = str:byte(i + 1)
        local b3 = str:byte(i + 2)
        local padding = (not b2) and 2 or (not b3) and 1 or 0
        b2 = b2 or 0
        b3 = b3 or 0
        local n = b1 * 65536 + b2 * 256 + b3
        encoded[#encoded + 1] = b64chars:sub(math.floor(n / 262144) + 1, math.floor(n / 262144) + 1)
        encoded[#encoded + 1] = b64chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        encoded[#encoded + 1] = (padding >= 2) and "=" or b64chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        encoded[#encoded + 1] = (padding >= 1) and "=" or b64chars:sub(n % 64 + 1, n % 64 + 1)
    end
    return table.concat(encoded)
end

function ns.DecodeString(str)
    -- Build reverse lookup
    local lookup = {}
    for i = 1, #b64chars do
        lookup[b64chars:sub(i, i)] = i - 1
    end
    local decoded = {}
    for i = 1, #str, 4 do
        local c1 = lookup[str:sub(i, i)] or 0
        local c2 = lookup[str:sub(i + 1, i + 1)] or 0
        local c3 = lookup[str:sub(i + 2, i + 2)]
        local c4 = lookup[str:sub(i + 3, i + 3)]
        local n = c1 * 262144 + c2 * 4096 + (c3 or 0) * 64 + (c4 or 0)
        decoded[#decoded + 1] = string.char(math.floor(n / 65536))
        if str:sub(i + 2, i + 2) ~= "=" then
            decoded[#decoded + 1] = string.char(math.floor(n / 256) % 256)
        end
        if str:sub(i + 3, i + 3) ~= "=" then
            decoded[#decoded + 1] = string.char(n % 256)
        end
    end
    return table.concat(decoded)
end

-- Serialize a simple table (flat key=value, nested with dot notation not supported)
-- Used for profile export/import.  Values must be strings, numbers, or booleans.
function ns.SerializeTable(t, indent)
    indent = indent or ""
    local parts = {}
    -- Sort keys for deterministic output
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = t[k]
        local vtype = type(v)
        if vtype == "table" then
            parts[#parts + 1] = tostring(k) .. "={" .. ns.SerializeTable(v, indent .. "  ") .. "}"
        elseif vtype == "string" then
            parts[#parts + 1] = tostring(k) .. '="' .. v:gsub('"', '\\"') .. '"'
        elseif vtype == "number" or vtype == "boolean" then
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, ";")
end

-- Deserialize the simple format produced by SerializeTable
function ns.DeserializeTable(str)
    -- Use Lua's load() with a sandboxed environment to safely parse the serialized format
    local src = "return {" .. str:gsub("={", "={"):gsub("}", "}") .. "}"
    -- Convert our format back to valid Lua table constructor
    -- Our format: key=value;key=value  nested: key={...}
    local function parseBlock(s)
        local t = {}
        local i = 1
        while i <= #s do
            -- Find next key=
            local keyStart, keyEnd, key = s:find("([^;={}]+)=", i)
            if not keyStart then break end
            i = keyEnd + 1
            if s:sub(i, i) == "{" then
                -- find matching }
                local depth = 1
                local j = i + 1
                while j <= #s and depth > 0 do
                    if s:sub(j, j) == "{" then depth = depth + 1
                    elseif s:sub(j, j) == "}" then depth = depth - 1 end
                    j = j + 1
                end
                local inner = s:sub(i + 1, j - 2)
                t[key] = parseBlock(inner)
                i = j
                if s:sub(i, i) == ";" then i = i + 1 end
            elseif s:sub(i, i) == '"' then
                local j = i + 1
                while j <= #s do
                    if s:sub(j, j) == '"' and s:sub(j - 1, j - 1) ~= "\\" then break end
                    j = j + 1
                end
                t[key] = s:sub(i + 1, j - 1):gsub('\\"', '"')
                i = j + 1
                if s:sub(i, i) == ";" then i = i + 1 end
            else
                local valEnd = s:find(";", i) or (#s + 1)
                local val = s:sub(i, valEnd - 1)
                if val == "true" then t[key] = true
                elseif val == "false" then t[key] = false
                else t[key] = tonumber(val) or val end
                i = valEnd + 1
            end
        end
        return t
    end
    local ok, result = pcall(parseBlock, str)
    if ok then return result end
    return nil
end

-- Clamp a number between min and max
function ns.Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Format a signed number (+3, -1, +0)
function ns.SignedNum(n)
    if n >= 0 then return "+" .. n end
    return tostring(n)
end
