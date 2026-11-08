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
    { key = "WF", name = "Windfury Weapon", kind = "imbue", ranks = {
        { id = 8232,  rank = 1, level = 30 }, { id = 8235,  rank = 2, level = 40 },
        { id = 10486, rank = 3, level = 50 }, { id = 16362, rank = 4, level = 60 },
    } },
}

-- Quick lookups: ns.RANKS_BY_KEY.LB, ns.RANKS_BY_NAME["Lightning Bolt"]
ns.RANKS_BY_KEY, ns.RANKS_BY_NAME = {}, {}
for _, s in ipairs(ns.RANKS) do
    ns.RANKS_BY_KEY[s.key] = s
    ns.RANKS_BY_NAME[s.name] = s
end
