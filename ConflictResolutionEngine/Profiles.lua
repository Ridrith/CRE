-- Profiles.lua — Character profile CRUD: create, save, load, delete, export/import
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

-- ─── Helpers ─────────────────────────────────────────────────────────────────

-- Returns a fresh default attribute table (all zeros)
local function DefaultAttributes()
    local attrs = {}
    for _, key in ipairs(ns.ATTRIBUTE_ORDER) do
        attrs[key] = 0
    end
    return attrs
end

-- Returns a table of default ability uses for a class
local function DefaultAbilityUses(className)
    local uses = {}
    local classData = ns.CLASS_DATA[className]
    if classData then
        for i, ab in ipairs(classData.abilities) do
            uses[i] = ab.uses
        end
    end
    return uses
end

-- Returns a table of default active trait uses for selected traits
local function DefaultTraitUses(activeTraitIds)
    local uses = {}
    for _, tid in ipairs(activeTraitIds or {}) do
        local trait = ns.ACTIVE_TRAIT_BY_ID[tid]
        if trait then
            uses[tid] = trait.uses
        end
    end
    return uses
end

-- Creates a brand-new blank profile
local function NewProfile(name, className)
    className = className or "Warrior"
    local classData = ns.CLASS_DATA[className] or ns.CLASS_DATA["Warrior"]
    return {
        name           = name or "New Profile",
        class          = className,
        attributes     = DefaultAttributes(),
        armor          = "None",
        passiveTraits  = {},   -- list of trait IDs
        activeTraits   = {},   -- list of trait IDs
        -- Runtime-only (not persisted long term but saved in session)
        currentStrikes = classData.strikes,
        abilityUses    = DefaultAbilityUses(className),
        traitUses      = {},
    }
end

-- ─── Derived stats calculations ──────────────────────────────────────────────

-- Returns total attribute points spent
function ns.AttributePointsSpent(attrs)
    local total = 0
    for _, v in pairs(attrs) do
        total = total + (v or 0)
    end
    return total
end

-- Calculate max strikes (class base + 1 if Stalwart passive selected)
function ns.CalcMaxStrikes(profile)
    local classData = ns.CLASS_DATA[profile.class]
    if not classData then return 0 end
    local base = classData.strikes
    -- Check Stalwart passive
    for _, tid in ipairs(profile.passiveTraits or {}) do
        if tid == "stalwart" then
            base = base + 1
            break
        end
    end
    return base
end

-- Defense Score = Finesse + 5 + armor bonus
function ns.CalcDefense(profile)
    local finesse    = (profile.attributes and profile.attributes.finesse) or 0
    local armorData  = ns.ARMOR_DATA[profile.armor or "None"] or ns.ARMOR_DATA["None"]
    -- If they have both armor and shield, only one defense bonus applies per slot
    -- For simplicity: profile.armor holds one entry; shield is additive if separate field exists
    local shieldBonus = profile.hasShield and ns.ARMOR_DATA["Shield"].defenseBonus or 0
    return finesse + ns.DEFENSE_BASE + armorData.defenseBonus + shieldBonus
end

-- Inventory = 10 + Endurance
function ns.CalcInventory(profile)
    local endurance = (profile.attributes and profile.attributes.endurance) or 0
    return ns.INVENTORY_BASE + endurance
end

-- ─── Profile storage helpers ─────────────────────────────────────────────────

-- Ensure the per-character DB has our namespace
local function EnsureCharDB()
    if not ConflictResolutionEngineCharDB then
        ConflictResolutionEngineCharDB = {}
    end
    if not ConflictResolutionEngineCharDB.profiles then
        ConflictResolutionEngineCharDB.profiles = {}
    end
    if not ConflictResolutionEngineCharDB.activeProfile then
        ConflictResolutionEngineCharDB.activeProfile = nil
    end
end

-- List all profile names for this character
function ns.ListProfiles()
    EnsureCharDB()
    local names = {}
    for name in pairs(ConflictResolutionEngineCharDB.profiles) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

-- Get a profile by name (returns nil if not found)
function ns.GetProfile(profileName)
    EnsureCharDB()
    return ConflictResolutionEngineCharDB.profiles[profileName]
end

-- Get the active profile (by name stored in CharDB)
function ns.GetActiveProfile()
    EnsureCharDB()
    local name = ConflictResolutionEngineCharDB.activeProfile
    if not name then return nil, nil end
    return ConflictResolutionEngineCharDB.profiles[name], name
end

-- Set the active profile by name
function ns.SetActiveProfile(profileName)
    EnsureCharDB()
    ConflictResolutionEngineCharDB.activeProfile = profileName
end

-- Create a new profile (errors if name already exists)
function ns.CreateProfile(profileName, className)
    EnsureCharDB()
    if not profileName or profileName == "" then
        return false, "Profile name cannot be empty."
    end
    if ConflictResolutionEngineCharDB.profiles[profileName] then
        return false, "A profile named '" .. profileName .. "' already exists."
    end
    local p = NewProfile(profileName, className)
    ConflictResolutionEngineCharDB.profiles[profileName] = p
    return true, p
end

-- Save (overwrite) a profile
function ns.SaveProfile(profile)
    EnsureCharDB()
    if not profile or not profile.name then
        return false, "Invalid profile."
    end
    ConflictResolutionEngineCharDB.profiles[profile.name] = profile
    return true
end

-- Delete a profile by name
function ns.DeleteProfile(profileName)
    EnsureCharDB()
    if not ConflictResolutionEngineCharDB.profiles[profileName] then
        return false, "Profile not found."
    end
    ConflictResolutionEngineCharDB.profiles[profileName] = nil
    if ConflictResolutionEngineCharDB.activeProfile == profileName then
        ConflictResolutionEngineCharDB.activeProfile = nil
    end
    return true
end

-- Rename a profile
function ns.RenameProfile(oldName, newName)
    EnsureCharDB()
    if not newName or newName == "" then
        return false, "New name cannot be empty."
    end
    if not ConflictResolutionEngineCharDB.profiles[oldName] then
        return false, "Profile '" .. oldName .. "' not found."
    end
    if ConflictResolutionEngineCharDB.profiles[newName] then
        return false, "A profile named '" .. newName .. "' already exists."
    end
    local p = ConflictResolutionEngineCharDB.profiles[oldName]
    p.name = newName
    ConflictResolutionEngineCharDB.profiles[newName] = p
    ConflictResolutionEngineCharDB.profiles[oldName] = nil
    if ConflictResolutionEngineCharDB.activeProfile == oldName then
        ConflictResolutionEngineCharDB.activeProfile = newName
    end
    return true
end

-- ─── Export / Import ─────────────────────────────────────────────────────────

function ns.ExportProfile(profileName)
    local p = ns.GetProfile(profileName)
    if not p then return nil, "Profile not found." end
    -- Shallow copy without runtime state
    local export = {
        name          = p.name,
        class         = p.class,
        armor         = p.armor,
        hasShield     = p.hasShield,
        passiveTraits = {},
        activeTraits  = {},
        attributes    = {},
    }
    for k, v in pairs(p.attributes or {}) do
        export.attributes[k] = v
    end
    for _, tid in ipairs(p.passiveTraits or {}) do
        export.passiveTraits[#export.passiveTraits + 1] = tid
    end
    for _, tid in ipairs(p.activeTraits or {}) do
        export.activeTraits[#export.activeTraits + 1] = tid
    end
    local serial = ns.SerializeTable(export)
    return ns.EncodeString(serial), nil
end

function ns.ImportProfile(encoded)
    if not encoded or encoded == "" then
        return false, "Empty import string."
    end
    local serial = ns.DecodeString(encoded)
    if not serial or serial == "" then
        return false, "Failed to decode import string."
    end
    local data = ns.DeserializeTable(serial)
    if not data or not data.name or not data.class then
        return false, "Invalid profile data."
    end
    EnsureCharDB()
    -- Prevent overwrite without warning — use a unique name if conflict
    local targetName = data.name
    if ConflictResolutionEngineCharDB.profiles[targetName] then
        targetName = targetName .. "_imported"
    end
    data.name = targetName
    -- Ensure arrays exist
    data.passiveTraits = data.passiveTraits or {}
    data.activeTraits  = data.activeTraits  or {}
    data.attributes    = data.attributes    or DefaultAttributes()
    -- Set class strike total / runtime fields
    local classData = ns.CLASS_DATA[data.class] or ns.CLASS_DATA["Warrior"]
    data.currentStrikes = classData.strikes
    data.abilityUses    = DefaultAbilityUses(data.class)
    data.traitUses      = DefaultTraitUses(data.activeTraits)
    ConflictResolutionEngineCharDB.profiles[targetName] = data
    return true, targetName
end

-- ─── Encounter reset ─────────────────────────────────────────────────────────

-- Reset all per-encounter ability/trait uses for the active profile
function ns.ResetEncounter()
    local profile, name = ns.GetActiveProfile()
    if not profile then return false, "No active profile." end
    -- Reset class ability uses
    profile.abilityUses = DefaultAbilityUses(profile.class)
    -- Reset active trait uses
    profile.traitUses = DefaultTraitUses(profile.activeTraits)
    ns.SaveProfile(profile)
    return true, name
end

-- Use one charge of a class ability (index 1-3)
function ns.UseClassAbility(profile, abilityIndex)
    if not profile or not profile.abilityUses then return false end
    local uses = profile.abilityUses[abilityIndex] or 0
    if uses <= 0 then return false, "No uses remaining." end
    profile.abilityUses[abilityIndex] = uses - 1
    ns.SaveProfile(profile)
    return true
end

-- Use one charge of an active trait
function ns.UseActiveTrait(profile, traitId)
    if not profile or not profile.traitUses then return false end
    local uses = profile.traitUses[traitId] or 0
    if uses <= 0 then return false, "No uses remaining." end
    profile.traitUses[traitId] = uses - 1
    ns.SaveProfile(profile)
    return true
end

-- Refresh active trait uses from selection (call when traits change)
function ns.RefreshTraitUses(profile)
    if not profile then return end
    if not profile.traitUses then profile.traitUses = {} end
    for _, tid in ipairs(profile.activeTraits or {}) do
        if not profile.traitUses[tid] then
            local trait = ns.ACTIVE_TRAIT_BY_ID[tid]
            if trait then
                profile.traitUses[tid] = trait.uses
            end
        end
    end
end
