-- Core.lua — Addon init, event handling, slash commands
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

-- ─── Event frame ─────────────────────────────────────────────────────────────
local frame = CreateFrame("Frame", "CRECoreFrame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= addonName then return end
        ns.InitDB()
        ns.Print("v2.0 loaded. Type " .. c.yellow .. "/cre help" .. c.r .. " for commands.")
        -- Notify UI modules
        if ns.OnAddonLoaded then ns.OnAddonLoaded() end
    elseif event == "PLAYER_LOGOUT" then
        -- SavedVariables are automatically saved by WoW; nothing extra needed.
        if ns.OnLogout then ns.OnLogout() end
    end
end)

-- ─── DB initialization ────────────────────────────────────────────────────────

function ns.InitDB()
    -- Global DB (shared settings, encounter log)
    if not ConflictResolutionEngineDB then
        ConflictResolutionEngineDB = {}
    end
    local db = ConflictResolutionEngineDB
    if not db.settings then
        db.settings = {
            chatChannel  = "SAY",
            whisperTarget = "",
            minimapPos   = 45,
        }
    end
    if not db.windowPos then
        db.windowPos = {}
    end
    if not db.encounterLog then
        db.encounterLog = {}
    end

    -- Per-character DB
    if not ConflictResolutionEngineCharDB then
        ConflictResolutionEngineCharDB = {}
    end
    local cdb = ConflictResolutionEngineCharDB
    if not cdb.profiles then
        cdb.profiles = {}
    end
    -- activeProfile may be nil (no selection yet)
end

-- ─── Settings helpers ─────────────────────────────────────────────────────────

function ns.GetSetting(key)
    if ConflictResolutionEngineDB and ConflictResolutionEngineDB.settings then
        return ConflictResolutionEngineDB.settings[key]
    end
    return nil
end

function ns.SetSetting(key, value)
    if ConflictResolutionEngineDB and ConflictResolutionEngineDB.settings then
        ConflictResolutionEngineDB.settings[key] = value
    end
end

-- ─── Slash commands ───────────────────────────────────────────────────────────

local function HandleSlash(msg)
    msg = ns.Trim(msg or ""):lower()

    -- /cre  (toggle window)
    if msg == "" then
        if ns.ToggleMainWindow then ns.ToggleMainWindow() end
        return
    end

    -- /cre help
    if msg == "help" then
        ns.Print(c.gold .. "Conflict Resolution Engine v2.0 Commands:" .. c.r)
        ns.Print(c.yellow .. "/cre" .. c.r .. " — Toggle main window")
        ns.Print(c.yellow .. "/cre roll <expr>" .. c.r .. " — Roll dice (e.g. 2d6+3, 4d6k3)")
        ns.Print(c.yellow .. "/cre attack <melee|ranged> [vs <defense>]" .. c.r .. " — Roll attack")
        ns.Print(c.yellow .. "/cre init" .. c.r .. " — Roll initiative")
        ns.Print(c.yellow .. "/cre dr [armor]" .. c.r .. " — Roll damage reduction")
        ns.Print(c.yellow .. "/cre profile" .. c.r .. " — Show active profile summary")
        ns.Print(c.yellow .. "/cre reset" .. c.r .. " — Reset encounter ability uses")
        ns.Print(c.yellow .. "/cre export" .. c.r .. " — Export active profile string")
        ns.Print(c.yellow .. "/cre help" .. c.r .. " — Show this help")
        return
    end

    -- /cre roll <expr>
    local rollExpr = msg:match("^roll%s+(.+)$")
    if rollExpr then
        local channel = ns.GetSetting("chatChannel") or "SAY"
        local target  = ns.GetSetting("whisperTarget") or ""
        ns.QuickRoll(rollExpr, channel, target)
        return
    end

    -- /cre attack <melee|ranged> [vs <defense>]
    local attackArgs = msg:match("^attack%s*(.*)$")
    if attackArgs ~= nil then
        local mode = attackArgs:match("^(melee)") or attackArgs:match("^(ranged)") or "melee"
        local defense = tonumber(attackArgs:match("vs%s*(%d+)"))
        local channel = ns.GetSetting("chatChannel") or "SAY"
        local target  = ns.GetSetting("whisperTarget") or ""
        ns.RollAttack(mode, defense, channel, target)
        return
    end

    -- /cre init
    if msg == "init" then
        local channel = ns.GetSetting("chatChannel") or "SAY"
        local target  = ns.GetSetting("whisperTarget") or ""
        ns.RollInitiative(channel, target)
        return
    end

    -- /cre dr [armor]
    local drArgs = msg:match("^dr%s*(.*)$")
    if drArgs ~= nil then
        local armorOverride = ns.Trim(drArgs)
        if armorOverride == "" then armorOverride = nil end
        -- Normalize to title-case for lookup
        if armorOverride then
            armorOverride = armorOverride:sub(1,1):upper() .. armorOverride:sub(2):lower()
        end
        local channel = ns.GetSetting("chatChannel") or "SAY"
        local target  = ns.GetSetting("whisperTarget") or ""
        ns.RollDR(armorOverride, channel, target)
        return
    end

    -- /cre profile
    if msg == "profile" then
        ns.PrintProfileSummary()
        return
    end

    -- /cre reset
    if msg == "reset" then
        local ok, name = ns.ResetEncounter()
        if ok then
            ns.Print(c.green .. "Encounter reset for: " .. c.r .. name)
        else
            ns.PrintError(name)
        end
        if ns.RefreshCombatTab then ns.RefreshCombatTab() end
        return
    end

    -- /cre export
    if msg == "export" then
        local _, name = ns.GetActiveProfile()
        if not name then
            ns.PrintError("No active profile to export.")
            return
        end
        local encoded, err = ns.ExportProfile(name)
        if not encoded then
            ns.PrintError(err)
            return
        end
        ns.Print(c.gold .. "Profile export for '" .. name .. "':" .. c.r)
        ns.Print(encoded)
        return
    end

    ns.Print(c.grey .. "Unknown command. Type " .. c.yellow .. "/cre help" .. c.r .. " for usage.")
end

SLASH_CONFLICTRESOLUTIONENGINE1 = "/cre"
SLASH_CONFLICTRESOLUTIONENGINE2 = "/conflictengine"
SlashCmdList["CONFLICTRESOLUTIONENGINE"] = HandleSlash

-- ─── Addon message prefix registration ───────────────────────────────────────
-- Keep backward compat with "CRE" prefix for party addon messages
C_ChatInfo.RegisterAddonMessagePrefix("CRE")
