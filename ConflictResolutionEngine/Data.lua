-- Data.lua — All rules constants: classes, attributes, traits, armor table
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

-- ─── Attributes ──────────────────────────────────────────────────────────────
ns.ATTRIBUTE_ORDER = {
    "might", "finesse", "endurance",
    "insight", "resolve",
    "presence",
    "faith", "magick", "luck"
}

ns.ATTRIBUTE_NAMES = {
    might     = "Might",
    finesse   = "Finesse",
    endurance = "Endurance",
    insight   = "Insight",
    resolve   = "Resolve",
    presence  = "Presence",
    faith     = "Faith",
    magick    = "Magick",
    luck      = "Luck",
}

ns.ATTRIBUTE_DESCRIPTIONS = {
    might     = "Add to melee attacks and strength-related checks (swimming, climbing, breaking doors).",
    finesse   = "Add to defense, ranged attacks, stealth, lockpicking, balancing, acrobatics.",
    endurance = "Carry 10 + Endurance slots. Saving throws vs poison/disease; increases healing while resting.",
    insight   = "Add to history/knowledge rolls. +1 = basic literacy.",
    resolve   = "Add to fear/morale/mind-based saving throws, searching, tracking.",
    presence  = "Add to reaction checks, persuasion, deception. Determines number of hirelings.",
    faith     = "Add to divine abilities and saves vs malevolent forces.",
    magick    = "Add to spellcasting rolls and saves vs magical effects.",
    luck      = "Favorable outcomes in uncertain situations.",
}

ns.ATTRIBUTE_CATEGORIES = {
    might     = "Physical",
    finesse   = "Physical",
    endurance = "Physical",
    insight   = "Mental",
    resolve   = "Mental",
    presence  = "Social",
    faith     = "Divine/Arcane/Fortune",
    magick    = "Divine/Arcane/Fortune",
    luck      = "Divine/Arcane/Fortune",
}

ns.ATTRIBUTE_POINT_TOTAL = 10
ns.ATTRIBUTE_MAX         = 6

-- ─── Armor Table ─────────────────────────────────────────────────────────────
ns.ARMOR_TYPES = {"None", "Leather", "Chain", "Plate", "Shield"}

ns.ARMOR_DATA = {
    ["None"]   = { defenseBonus = 0, drRange = 0,  drLabel = "—",   notes = "No protection." },
    ["Leather"]= { defenseBonus = 1, drRange = 1,  drLabel = "1",   notes = "Light, no penalties." },
    ["Chain"]  = { defenseBonus = 2, drRange = 2,  drLabel = "1–2", notes = "Disadvantage on stealth." },
    ["Plate"]  = { defenseBonus = 3, drRange = 3,  drLabel = "1–3", notes = "Disadvantage on stealth, −1 Finesse checks." },
    ["Shield"] = { defenseBonus = 1, drRange = 0,  drLabel = "—",   notes = "Enables Shield Bash trait. Off-hand only." },
}

-- ─── Passive Traits ──────────────────────────────────────────────────────────
ns.PASSIVE_TRAITS = {
    {
        id   = "stalwart",
        name = "Stalwart",
        desc = "+1 maximum Strike.",
    },
    {
        id   = "scarred_veteran",
        name = "Scarred Veteran",
        desc = "+1 to all Resolve-based saving throws.",
    },
    {
        id   = "tenacious",
        name = "Tenacious",
        desc = "You do not fall unconscious until −1 Strike instead of 0.",
    },
    {
        id   = "iron_gut",
        name = "Iron Gut",
        desc = "+2 to all Endurance saves vs poison and disease.",
    },
    {
        id   = "tactician",
        name = "Tactician",
        desc = "+1 to all Initiative rolls. Allies within 10 ft also gain +1.",
    },
    {
        id   = "pain_hardened",
        name = "Pain Hardened",
        desc = "Critical hits against you deal only +1 Strike (instead of +2).",
    },
    {
        id   = "divine_shell",
        name = "Divine Shell",
        desc = "Take −1 Strike from unholy/necrotic/fiendish sources once per encounter.",
    },
    {
        id   = "foe_reader",
        name = "Foe Reader",
        desc = "You always know if a humanoid target is stronger or weaker than you.",
    },
    {
        id   = "keen_eyed",
        name = "Keen-Eyed",
        desc = "+2 to detect illusions, forgeries, or falsehoods.",
    },
    {
        id   = "unshakable_faith",
        name = "Unshakable Faith",
        desc = "Immune to fear effects from enemies with fewer Strikes than you.",
    },
    {
        id   = "blooded",
        name = "Blooded",
        desc = "Once per day, automatically succeed a morale or Resolve save.",
    },
    {
        id   = "magick_sense",
        name = "Magick Sense",
        desc = "Detect active magical effects within 30 ft at will.",
    },
    {
        id   = "void_gaze",
        name = "Void Gaze",
        desc = "Once per encounter, force one enemy to reroll an attack against you.",
    },
    {
        id   = "quiet_mind",
        name = "Quiet Mind",
        desc = "+2 to saves vs charm, domination, or mind-reading.",
    },
    {
        id   = "hard_to_kill",
        name = "Hard to Kill",
        desc = "When gaining a Horrible Wound, roll twice and take the better result.",
    },
    {
        id   = "shadow_step",
        name = "Shadow Step",
        desc = "Moving through darkness/dim light costs no extra movement and makes no noise.",
    },
}

-- ─── Active Traits ───────────────────────────────────────────────────────────
ns.ACTIVE_TRAITS = {
    {
        id      = "battle_cry",
        name    = "Battle Cry",
        uses    = 1,
        desc    = "Allies within 30 ft gain +1 to attack rolls for 1 round.",
    },
    {
        id      = "second_wind",
        name    = "Second Wind",
        uses    = 1,
        desc    = "Heal 1d6 Strikes as a free action.",
    },
    {
        id      = "parry",
        name    = "Parry",
        uses    = 2,
        desc    = "Turn a successful melee attack against you into a miss.",
    },
    {
        id      = "intimidate",
        name    = "Intimidate",
        uses    = 1,
        desc    = "Enemy Resolve save DC 14 or flee 1d4 rounds.",
    },
    {
        id      = "precise_shot",
        name    = "Precise Shot",
        uses    = 2,
        desc    = "Next ranged attack ignores cover and deals +1 Strike.",
    },
    {
        id      = "rally",
        name    = "Rally",
        uses    = 1,
        desc    = "Remove Morale Broken or Fear from self or one ally within 30 ft.",
    },
    {
        id      = "shield_bash",
        name    = "Shield Bash",
        uses    = 2,
        desc    = "With shield: attack that Stuns target on hit (no damage).",
    },
    {
        id      = "study_weakness",
        name    = "Study Weakness",
        uses    = 1,
        desc    = "Observe 1 round; next attack has Advantage.",
    },
    {
        id      = "heroic_surge",
        name    = "Heroic Surge",
        uses    = 1,
        desc    = "Take an additional action this turn.",
    },
    {
        id      = "deathblow",
        name    = "Deathblow",
        uses    = 1,
        desc    = "Vs enemy at half Strikes or fewer: +2 Strikes.",
    },
    {
        id      = "taunt",
        name    = "Taunt",
        uses    = 2,
        desc    = "Enemy targets only you for 1 round or takes 1 Strike psychic damage.",
    },
    {
        id      = "arcane_surge",
        name    = "Arcane Surge",
        uses    = 1,
        desc    = "Advantage on next spellcast (risk Mishap on 1d6=1).",
    },
    {
        id      = "divine_smite",
        name    = "Divine Smite",
        uses    = 2,
        desc    = "Melee attack +2 Strikes vs unholy/fiendish.",
    },
    {
        id      = "gamblers_edge",
        name    = "Gambler's Edge",
        uses    = 3,
        desc    = "Declare before roll: success = +2; failure = 1 Strike.",
    },
    {
        id      = "lucky_twist",
        name    = "Lucky Twist",
        uses    = 1,
        desc    = "Reroll any d20 you just made (must accept result).",
    },
    {
        id      = "poisoned_strike",
        name    = "Poisoned Strike",
        uses    = 2,
        desc    = "On hit, apply poison; target Endurance DC 12 or Poisoned.",
    },
}

-- Build lookup tables for fast access
ns.PASSIVE_TRAIT_BY_ID = {}
for _, t in ipairs(ns.PASSIVE_TRAITS) do
    ns.PASSIVE_TRAIT_BY_ID[t.id] = t
end

ns.ACTIVE_TRAIT_BY_ID = {}
for _, t in ipairs(ns.ACTIVE_TRAITS) do
    ns.ACTIVE_TRAIT_BY_ID[t.id] = t
end

-- ─── WoW Classes ─────────────────────────────────────────────────────────────
ns.CLASS_ORDER = {
    "Warrior", "Rogue", "Hunter", "Paladin", "Priest",
    "Mage", "Warlock", "Druid", "Shaman", "Death Knight",
    "Evoker", "Demon Hunter", "Monk"
}

ns.CLASS_DATA = {
    ["Warrior"] = {
        flavor  = "Fury & Steel",
        strikes = 6,
        abilities = {
            {
                name  = "Rending Slash",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Deal 1 Strike. Target bleeds, taking 1 additional Strike at the end of their next turn.",
            },
            {
                name  = "Battle Cry",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "You and nearby allies gain +1 to attack rolls for 1 round.",
            },
            {
                name  = "Last Breath",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "When reduced to 0 Strikes, remain standing at 1 Strike and take your full next turn.",
            },
        },
    },
    ["Rogue"] = {
        flavor  = "Shadows & Deception",
        strikes = 5,
        abilities = {
            {
                name  = "Backstab",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "If target has already acted this encounter, deal +1 Strike on a successful attack.",
            },
            {
                name  = "Poisoned Blade",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "On hit, target must pass Endurance save or take 1 additional Strike next round.",
            },
            {
                name  = "Marked for Death",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Choose a target: attacks against them deal +1 Strike for rest of encounter.",
            },
        },
    },
    ["Hunter"] = {
        flavor  = "Bow and Fang",
        strikes = 5,
        abilities = {
            {
                name  = "Pinning Shot",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "On hit, target cannot use active abilities on their next turn.",
            },
            {
                name  = "Hunter's Focus",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Reroll a ranged attack or gain +2 to a tracking or perception-based check.",
            },
            {
                name  = "Trophy Kill",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "If you reduce a beast or monster to 0 Strikes, gain 1 temporary Strike.",
            },
        },
    },
    ["Paladin"] = {
        flavor  = "Righteous Fury",
        strikes = 6,
        abilities = {
            {
                name  = "Judgment",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Deal 1 Strike. If the target is unholy, deal +1 additional Strike.",
            },
            {
                name  = "Lay on Hands",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Restore 2 Strikes to yourself or an ally.",
            },
            {
                name  = "Divine Flame",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Smite target for 2 Strikes. Target takes 1 Strike next encounter if Faith save fails.",
            },
        },
    },
    ["Priest"] = {
        flavor  = "Divine Grace",
        strikes = 4,
        abilities = {
            {
                name  = "Heal",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Restore 1 Strike to yourself or an ally.",
            },
            {
                name  = "Sanctuary",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Negate all damage from a single attack on one ally this round.",
            },
            {
                name  = "Soothe Madness",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Remove a mental or spiritual affliction from an ally.",
            },
        },
    },
    ["Mage"] = {
        flavor  = "Arcane Mastery",
        strikes = 4,
        abilities = {
            {
                name  = "Firebolt",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Deal 1 Strike. Target catches fire, takes 1 Strike next encounter on failed Magick save.",
            },
            {
                name  = "Arcane Barrier",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Block the next incoming spell or negate 1 Strike of magical damage.",
            },
            {
                name  = "Dispel Magick",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "End one magical effect or curse on a target (Magick save vs 12).",
            },
        },
    },
    ["Warlock"] = {
        flavor  = "Forbidden Power",
        strikes = 5,
        abilities = {
            {
                name  = "Shadow Coil",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Deal 1 Strike. Target loses 1 use of an active trait next encounter if Magick save fails.",
            },
            {
                name  = "Drain Soul",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Steal 1 Strike from an enemy: deal 1 Strike, regain 1 yourself.",
            },
            {
                name  = "Pact Seal",
                uses  = 0,
                usesLabel = "Passive",
                desc  = "Once per day, reroll a failed spell roll. If you fail again, summon a hostile demon.",
            },
        },
    },
    ["Druid"] = {
        flavor  = "Nature's Wrath",
        strikes = 5,
        abilities = {
            {
                name  = "Entangling Roots",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Target cannot use active traits next turn if they fail Resolve save.",
            },
            {
                name  = "Nature's Grace",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Heal 1 Strike and gain +1 to your next Faith or Endurance roll.",
            },
            {
                name  = "Regrowth",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Restore 1 Strike immediately, and another 1 Strike at the end of the round.",
            },
        },
    },
    ["Shaman"] = {
        flavor  = "Elemental Harmony",
        strikes = 5,
        abilities = {
            {
                name  = "Lightning Surge",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Deal 1 Strike. If you roll a natural 20, deal 2 additional Strikes.",
            },
            {
                name  = "Spirit Echo",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Your last healing spell echoes to a second ally for 1 Strike.",
            },
            {
                name  = "Storm Wrath",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Call the storm: all enemies take 1 Strike unless they pass a Resolve save.",
            },
        },
    },
    ["Death Knight"] = {
        flavor  = "Undeath's Champion",
        strikes = 6,
        abilities = {
            {
                name  = "Death Coil",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Deal 1 Strike. If target dies from this, regain 1 Strike yourself.",
            },
            {
                name  = "Unholy Frenzy",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Until end of encounter, deal +1 Strike with all attacks, take 1 Strike yourself each round.",
            },
            {
                name  = "Raise Ghoul",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Summon decaying servant. Makes 1 attack per encounter for 1 Strike.",
            },
        },
    },
    ["Evoker"] = {
        flavor  = "Soldier of the Flight",
        strikes = 5,
        abilities = {
            {
                name  = "Breath of Devastation",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Unleash draconic breath in a cone. Targets take 1 Strike unless they pass Magick save.",
            },
            {
                name  = "Temporal Rift",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Rewind time: undo the last action taken by any character this round.",
            },
            {
                name  = "Time Dilation",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Slow time for enemies: all foes act with Disadvantage on their next turn.",
            },
        },
    },
    ["Demon Hunter"] = {
        flavor  = "Fel-Forged Vengeance",
        strikes = 5,
        abilities = {
            {
                name  = "Fel Blade",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Deal 1 Strike with fel energy. Target takes 1 additional Strike next turn if Endurance save fails.",
            },
            {
                name  = "Metamorphosis",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Transform into demonic form. Gain +2 to attacks and +1 Strike damage for 2 rounds.",
            },
            {
                name  = "Soul Cleave",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Deal 2 Strikes to a demon or fiend. If you kill it, regain 2 Strikes yourself.",
            },
        },
    },
    ["Monk"] = {
        flavor  = "Body & Spirit",
        strikes = 5,
        abilities = {
            {
                name  = "Chi Burst",
                uses  = 3,
                usesLabel = "3/enc",
                desc  = "Channel inner energy to heal 1 Strike or deal 1 Strike to an enemy within 30 feet.",
            },
            {
                name  = "Flurry of Blows",
                uses  = 2,
                usesLabel = "2/enc",
                desc  = "Make two unarmed attacks in rapid succession. Each deals 1 Strike.",
            },
            {
                name  = "Transcendence",
                uses  = 1,
                usesLabel = "1/enc",
                desc  = "Become one with universe. Ignore all damage/effects for 1 round, but cannot act.",
            },
        },
    },
}

-- ─── Combat constants ─────────────────────────────────────────────────────────
ns.DEFENSE_BASE = 5           -- Defense = Finesse + 5 + Armor Bonus
ns.INVENTORY_BASE = 10        -- Inventory = 10 + Endurance

-- ─── Channel options ─────────────────────────────────────────────────────────
ns.CHAT_CHANNELS = {"SAY", "PARTY", "RAID", "WHISPER", "OFFICER", "EMOTE"}
ns.CHAT_CHANNEL_LABELS = {
    SAY     = "Say",
    PARTY   = "Party",
    RAID    = "Raid",
    WHISPER = "Whisper",
    OFFICER = "Officer",
    EMOTE   = "Emote",
}

-- ─── Dice options ─────────────────────────────────────────────────────────────
ns.COMMON_DICE = {4, 6, 8, 10, 12, 20, 100}
