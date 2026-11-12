-- The Earthen Shrink: rank list (starting guesses only)
--
-- IMPORTANT: these spell IDs and levels are OLD CLASSIC values. They are NOT
-- trusted as WoW Forever facts. They are only used as a "where to look" list.
--
-- When the addon runs, Data/SpellData.lua asks the game itself about every
-- ID below:
--   * If the game says the ID has a different name, the rank is thrown away.
--   * The level comes from the game (C_Spell.GetSpellLevelLearned) when it can,
--     or from your class trainer window once you've opened it.
--   * Damage, mana cost and cast time ALWAYS come from the game's own tooltip.
-- Spells found in your spellbook are added too, even if they're not listed here.
--
-- Format: { id = spell ID, rank = rank number, level = Classic level (guess) }

local _, ns = ...

ns.RANKS = {
    -- Damage spells ------------------------------------------------------
    { key = "LB", name = "Lightning Bolt", school = "Nature", kind = "spell", ranks = {
        { id = 403,   rank = 1,  level = 1 },  { id = 529,   rank = 2,  level = 8 },
        { id = 548,   rank = 3,  level = 14 }, { id = 915,   rank = 4,  level = 20 },
        { id = 943,   rank = 5,  level = 26 }, { id = 6041,  rank = 6,  level = 32 },
        { id = 10391, rank = 7,  level = 38 }, { id = 10392, rank = 8,  level = 44 },
        { id = 15207, rank = 9,  level = 50 }, { id = 15208, rank = 10, level = 56 },
    } },
    { key = "CL", name = "Chain Lightning", school = "Nature", kind = "spell", ranks = {
        { id = 421,   rank = 1, level = 32 }, { id = 930,   rank = 2, level = 40 },
        { id = 2860,  rank = 3, level = 48 }, { id = 10605, rank = 4, level = 56 },
    } },
    { key = "ES", name = "Earth Shock", school = "Nature", kind = "spell", ranks = {
        { id = 8042,  rank = 1, level = 4 },  { id = 8044,  rank = 2, level = 8 },
        { id = 8045,  rank = 3, level = 14 }, { id = 8046,  rank = 4, level = 24 },
        { id = 10412, rank = 5, level = 36 }, { id = 10413, rank = 6, level = 48 },
        { id = 10414, rank = 7, level = 60 },
    } },
    { key = "FlS", name = "Flame Shock", school = "Fire", kind = "spell", ranks = {
        { id = 8050,  rank = 1, level = 10 }, { id = 8052,  rank = 2, level = 18 },
        { id = 8053,  rank = 3, level = 28 }, { id = 10447, rank = 4, level = 40 },
        { id = 10448, rank = 5, level = 52 }, { id = 29228, rank = 6, level = 60 },
    } },
    { key = "FrS", name = "Frost Shock", school = "Frost", kind = "spell", ranks = {
        { id = 8056,  rank = 1, level = 20 }, { id = 8058,  rank = 2, level = 34 },
        { id = 10472, rank = 3, level = 46 }, { id = 10473, rank = 4, level = 58 },
    } },
    -- Forever made Fire Nova a spell (it was a totem). These IDs are the old
    -- totem ones, so they will probably be thrown away by the name check and
    -- replaced with whatever is in your spellbook.
    { key = "FN", name = "Fire Nova", school = "Fire", kind = "spell", aoe = true, ranks = {
        { id = 1535,  rank = 1, level = 12 }, { id = 8498,  rank = 2, level = 22 },
        { id = 8499,  rank = 3, level = 32 }, { id = 11314, rank = 4, level = 42 },
        { id = 11315, rank = 5, level = 52 },
    } },
    -- Lava Burst is new in Forever (31-point Elemental talent). No ID known yet,
    -- so it only shows up if it's in your spellbook.
    { key = "LvB", name = "Lava Burst", school = "Fire", kind = "spell", ranks = {} },

    -- Stormstrike (Enhancement talent): a weapon strike. Its mana cost is read
    -- from the game, so a cost that is a % of your base mana works too.
    -- No ID known for Forever yet, so it only shows if it's in your spellbook.
    { key = "SS", name = "Stormstrike", kind = "strike", ranks = {} },
    -- Lightning Shield: hits back when you're hit, a few charges, then recast.
    { key = "LS", name = "Lightning Shield", school = "Nature", kind = "shield", ranks = {
        { id = 324,   rank = 1, level = 8 },  { id = 325,   rank = 2, level = 16 },
        { id = 905,   rank = 3, level = 24 }, { id = 945,   rank = 4, level = 32 },
        { id = 8134,  rank = 5, level = 40 }, { id = 10431, rank = 6, level = 48 },
        { id = 10432, rank = 7, level = 56 },
    } },

    -- Healing spells (used to judge healing totems) -------------------------
    { key = "HW", name = "Healing Wave", school = "Nature", kind = "heal", ranks = {
        { id = 331,   rank = 1,  level = 1 },  { id = 332,   rank = 2,  level = 6 },
        { id = 547,   rank = 3,  level = 12 }, { id = 913,   rank = 4,  level = 18 },
        { id = 939,   rank = 5,  level = 24 }, { id = 959,   rank = 6,  level = 32 },
        { id = 8005,  rank = 7,  level = 40 }, { id = 10395, rank = 8,  level = 48 },
        { id = 10396, rank = 9,  level = 56 }, { id = 25357, rank = 10, level = 60 },
    } },
    { key = "LHW", name = "Lesser Healing Wave", school = "Nature", kind = "heal", ranks = {
        { id = 8004,  rank = 1, level = 20 }, { id = 8008,  rank = 2, level = 28 },
        { id = 8010,  rank = 3, level = 36 }, { id = 10466, rank = 4, level = 44 },
        { id = 10467, rank = 5, level = 52 }, { id = 10468, rank = 6, level = 60 },
    } },
    { key = "CH", name = "Chain Heal", school = "Nature", kind = "heal", ranks = {
        { id = 1064,  rank = 1, level = 40 }, { id = 10622, rank = 2, level = 46 },
        { id = 10623, rank = 3, level = 54 },
    } },
    { key = "RT", name = "Riptide", school = "Nature", kind = "heal", ranks = {} },

    -- Totems -------------------------------------------------------------
    -- totem = what kind of value it gives: "dmg" (one target), "aoe" (all
    -- nearby enemies), "heal", "mana", or "buff" (no mana value to compare).
    { key = "ST", name = "Searing Totem", element = "Fire", school = "Fire", kind = "totem", totem = "dmg", ranks = {
        { id = 3599,  rank = 1, level = 10 }, { id = 6363,  rank = 2, level = 20 },
        { id = 6364,  rank = 3, level = 30 }, { id = 6365,  rank = 4, level = 40 },
        { id = 10437, rank = 5, level = 50 }, { id = 10438, rank = 6, level = 60 },
    } },
    { key = "MT", name = "Magma Totem", element = "Fire", school = "Fire", kind = "totem", totem = "aoe", ranks = {
        { id = 8190,  rank = 1, level = 26 }, { id = 10585, rank = 2, level = 36 },
        { id = 10586, rank = 3, level = 46 }, { id = 10587, rank = 4, level = 56 },
    } },
    { key = "FTT", name = "Flametongue Totem", element = "Fire", kind = "totem", totem = "buff", ranks = {
        { id = 8227,  rank = 1, level = 28 }, { id = 8249,  rank = 2, level = 38 },
        { id = 10526, rank = 3, level = 48 }, { id = 16387, rank = 4, level = 58 },
    } },
    { key = "HST", name = "Healing Stream Totem", element = "Water", kind = "totem", totem = "heal", ranks = {
        { id = 5394,  rank = 1, level = 20 }, { id = 6375,  rank = 2, level = 30 },
        { id = 6377,  rank = 3, level = 40 }, { id = 10462, rank = 4, level = 50 },
        { id = 10463, rank = 5, level = 60 },
    } },
    { key = "MST", name = "Mana Spring Totem", element = "Water", kind = "totem", totem = "mana", ranks = {
        { id = 5675,  rank = 1, level = 26 }, { id = 10495, rank = 2, level = 36 },
        { id = 10496, rank = 3, level = 46 }, { id = 10497, rank = 4, level = 56 },
    } },
    { key = "MTT", name = "Mana Tide Totem", element = "Water", kind = "totem", totem = "mana", ranks = {} },
    { key = "SKT", name = "Stoneskin Totem", element = "Earth", kind = "totem", totem = "buff", ranks = {
        { id = 8071,  rank = 1, level = 4 },  { id = 8154,  rank = 2, level = 14 },
        { id = 8155,  rank = 3, level = 24 }, { id = 10406, rank = 4, level = 34 },
        { id = 10407, rank = 5, level = 44 }, { id = 10408, rank = 6, level = 54 },
    } },
    { key = "SOE", name = "Strength of Earth Totem", element = "Earth", kind = "totem", totem = "buff", ranks = {
        { id = 8075,  rank = 1, level = 10 }, { id = 8160,  rank = 2, level = 24 },
        { id = 8161,  rank = 3, level = 38 }, { id = 10442, rank = 4, level = 52 },
        { id = 25361, rank = 5, level = 60 },
    } },
    { key = "EBT", name = "Earthbind Totem", element = "Earth", kind = "totem", totem = "buff", ranks = {
        { id = 2484, rank = 1, level = 6 },
    } },
    { key = "TT", name = "Tremor Totem", element = "Earth", kind = "totem", totem = "buff", ranks = {
        { id = 8143, rank = 1, level = 18 },
    } },
    { key = "WFT", name = "Windfury Totem", element = "Air", kind = "totem", totem = "buff", ranks = {
        { id = 8512,  rank = 1, level = 32 }, { id = 10613, rank = 2, level = 42 },
        { id = 10614, rank = 3, level = 52 },
    } },
    { key = "GOA", name = "Grace of Air Totem", element = "Air", kind = "totem", totem = "buff", ranks = {
        { id = 8835,  rank = 1, level = 42 }, { id = 10627, rank = 2, level = 56 },
        { id = 25359, rank = 3, level = 60 },
    } },
    { key = "GT", name = "Grounding Totem", element = "Air", kind = "totem", totem = "buff", ranks = {
        { id = 8177, rank = 1, level = 30 },
    } },

    -- Totem tools (new in Forever; only found through your spellbook) ------
    { key = "COE", name = "Call of the Elements", kind = "utility", ranks = {} },
    { key = "TR", name = "Totemic Recall", kind = "utility", ranks = {} },

    -- Weapon imbues ------------------------------------------------------
    { key = "RB", name = "Rockbiter Weapon", kind = "imbue", ranks = {
        { id = 8017,  rank = 1, level = 1 },  { id = 8018,  rank = 2, level = 8 },
        { id = 8019,  rank = 3, level = 16 }, { id = 10399, rank = 4, level = 24 },
        { id = 16314, rank = 5, level = 34 }, { id = 16315, rank = 6, level = 44 },
        { id = 16316, rank = 7, level = 54 },
    } },
    { key = "FT", name = "Flametongue Weapon", kind = "imbue", ranks = {
        { id = 8024,  rank = 1, level = 10 }, { id = 8027,  rank = 2, level = 18 },
        { id = 8030,  rank = 3, level = 26 }, { id = 16339, rank = 4, level = 36 },
        { id = 16341, rank = 5, level = 46 }, { id = 16342, rank = 6, level = 56 },
    } },
    { key = "FB", name = "Frostbrand Weapon", kind = "imbue", ranks = {
        { id = 8033,  rank = 1, level = 20 }, { id = 8038,  rank = 2, level = 28 },
        { id = 10456, rank = 3, level = 38 }, { id = 16355, rank = 4, level = 48 },
        { id = 16356, rank = 5, level = 58 },
    } },
    { key = "WF", name = "Windfury Weapon", kind = "imbue", ranks = {
        { id = 8232,  rank = 1, level = 30 }, { id = 8235,  rank = 2, level = 40 },
        { id = 10486, rank = 3, level = 50 }, { id = 16362, rank = 4, level = 60 },
    } },
}

-- Built-in imbue numbers, used only when the game's tooltip can't be read.
-- ONLY numbers someone has seen in Forever go here, with where they came from.
ns.IMBUE_FALLBACK = {
    WF = {
        -- Angel read this rank 1 tooltip in game on 2026-11-12:
        -- "Each hit has a 20% chance of granting you two extra attacks with
        --  104 extra melee attack power."
        [1] = { chance = 20, attacks = 2, ap = 104, source = "rank 1 tooltip seen in Forever, Nov 12" },
    },
}

-- Quick lookups: ns.RANKS_BY_KEY.LB, ns.RANKS_BY_NAME["Lightning Bolt"]
ns.RANKS_BY_KEY, ns.RANKS_BY_NAME = {}, {}
for _, s in ipairs(ns.RANKS) do
    ns.RANKS_BY_KEY[s.key] = s
    ns.RANKS_BY_NAME[s.name] = s
end
