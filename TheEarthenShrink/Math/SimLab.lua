-- The Earthen Shrink: Sim Lab math
--
-- "What if I had 17 more Strength?" We take your real character (read from
-- the game, like every other tab), add the extra stats, and run the same
-- spell math again. Nothing is equipped and nothing changes in the game.
--
-- How extra stats turn into the numbers the math uses (rules marked 🔶 are
-- OLD CLASSIC rules, placeholders until they're tested in Forever):

local _, ns = ...
local S = {}
ns.SimMath = S

S.RULES = {
    apPerStr = 2,             -- 🔶 1 Strength = 2 attack power for a Shaman
    agiPerMeleeCrit = 20,     -- 🔶 20 Agility = 1% melee crit
    manaPerInt = 15,          -- 🔶 1 Intellect = 15 mana
    -- 🔶 Intellect for 1% spell crit: about 59.5 at level 60, less at low level.
    intPerSpellCrit = function(level) return 10 + 49.5 * (level / 60) end,
    -- Mental Dexterity (Enhancement talent, 3/3): attack power equal to 100%
    -- of your Intellect (Angel, 2026-11-10 hotfix). Only used when ticked.
    mentalDexApPerInt = 1.0,
    -- Mental Quickness (Enhancement talent): spell damage and healing equal
    -- to 15% of your Intellect for each point. Angel-reported (in game,
    -- 2026-11-12: 87 Int gave 13 spell power with 1 point). The exact
    -- tooltip text isn't checked yet.
    mentalQuickSpPerIntPerRank = 0.15,
    mentalQuickMaxRank = 5,   -- guess; only limits the button
}

-- Points in Mental Quickness: your setting, or your talents, or 0.
-- Returns rank, where it came from ("talents", "setting" or "none").
function S.MentalQuickRank()
    local set = ns.db().simMentalQuick
    if type(set) == "number" then return set, "setting" end
    local r = ns.Talents and ns.Talents.Rank("Mental Quickness")
    if r then return r, "talents" end
    return 0, "none"
end

-- The stats you can add. Order = order of the sliders.
S.STATS = {
    { key = "str",  label = "Strength",       min = -60, max = 120, step = 1 },
    { key = "agi",  label = "Agility",        min = -60, max = 120, step = 1 },
    { key = "int",  label = "Intellect",      min = -60, max = 120, step = 1 },
    { key = "sp",   label = "Spell Power",    min = -60, max = 150, step = 1 },
    { key = "heal", label = "Healing",        min = -60, max = 150, step = 1 },
    { key = "ap",   label = "Attack Power",   min = -100, max = 300, step = 2 },
    { key = "crit", label = "Crit",           min = -5, max = 10, step = 1, unit = "%" },
    { key = "hit",  label = "Hit",            min = -5, max = 10, step = 1, unit = "%" },
}

function S.Empty()
    local add = {}
    for _, st in ipairs(S.STATS) do add[st.key] = 0 end
    return add
end

-- Returns a copy of profile p with the extra stats in "add".
-- weapon = a different main-hand weapon to use (from an item you tried on).
-- Also returns a list of lines saying where each change came from.
function S.Apply(p, add, opts)
    opts = opts or {}
    local R, L = S.RULES, p.level or 60
    local q = {}
    for k, v in pairs(p) do q[k] = v end
    local why = {}
    local function note(s) why[#why + 1] = s end
    local f = ns.fmt

    -- Mental Quickness: Intellect also gives spell damage and healing.
    local mq = opts.mentalQuick or 0
    local spFromInt = (add.int or 0) * R.mentalQuickSpPerIntPerRank * mq
    q.sp = {}
    for school, v in pairs(p.sp or {}) do q.sp[school] = v + (add.sp or 0) + spFromInt end
    q.source = "sim"
    if spFromInt ~= 0 then
        note(("%s Intellect × %s%% × %d (Mental Quickness) = %s spell power and healing"):format(
            f(add.int), f(R.mentalQuickSpPerIntPerRank * 100), mq, f(spFromInt, 1)))
    end

    local apFromStr = (add.str or 0) * R.apPerStr
    local apFromInt = opts.mentalDex and (add.int or 0) * R.mentalDexApPerInt or 0
    q.ap = (p.ap or 0) + apFromStr + apFromInt + (add.ap or 0)
    if apFromStr ~= 0 then note(("%s Strength × %s = %s attack power"):format(f(add.str), f(R.apPerStr), f(apFromStr))) end
    if apFromInt ~= 0 then note(("%s Intellect × %s (Mental Dexterity) = %s attack power"):format(f(add.int), f(R.mentalDexApPerInt), f(apFromInt))) end

    local critFromAgi = (add.agi or 0) / R.agiPerMeleeCrit
    q.meleeCrit = math.max(0, (p.meleeCrit or 0) + critFromAgi + (add.crit or 0))
    if critFromAgi ~= 0 then note(("%s Agility ÷ %s = %s%% melee crit"):format(f(add.agi), f(R.agiPerMeleeCrit), f(critFromAgi, 2))) end

    local intPerCrit = R.intPerSpellCrit(L)
    local critFromInt = (add.int or 0) / intPerCrit
    q.spellCrit = math.max(0, (p.spellCrit or 0) + critFromInt + (add.crit or 0))
    if critFromInt ~= 0 then note(("%s Intellect ÷ %s = %s%% spell crit"):format(f(add.int), f(intPerCrit, 1), f(critFromInt, 2))) end

    local manaFromInt = (add.int or 0) * R.manaPerInt
    q.mana = math.max(0, (p.mana or 0) + manaFromInt)
    if manaFromInt ~= 0 then note(("%s Intellect × %s = %s mana"):format(f(add.int), f(R.manaPerInt), f(manaFromInt))) end

    q.hit = (p.hit or 0) + (add.hit or 0)
    q.spellHit = (p.spellHit or 0) + (add.hit or 0)
    q.healing = (p.healing or 0) + (add.heal or 0) + spFromInt
    if opts.weapon and opts.weapon.min then q.weapon = opts.weapon end
    return q, why
end

-- Plain melee swings with your main-hand weapon (no weapon buff).
function S.Melee(p)
    local w = p.weapon
    if not (w and w.min and w.speed and w.speed > 0) then return nil end
    local IR = ns.ImbueMath.RULES
    local c = {}
    c.avg = (w.min + w.max) / 2 + (p.ap or 0) / IR.apPerDps * w.speed
    local miss = math.max(0, IR.meleeMiss - (p.hit or 0))
    c.land = math.max(0, 1 - (miss + IR.dodge) / 100)
    c.critMult = 1 + (p.meleeCrit or 0) / 100 * IR.meleeCritBonus
    c.expected = c.avg * c.critMult * c.land
    c.dps = c.expected / w.speed
    return c
end

---------------------------------------------------------------------------
-- Items: which slot an item goes in, and what changes if you wear it
---------------------------------------------------------------------------

-- Equip location -> the slot(s) it can go in.
S.SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
S.SLOT_NAMES = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest", [6] = "Waist", [7] = "Legs",
    [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Ring 1", [12] = "Ring 2", [13] = "Trinket 1",
    [14] = "Trinket 2", [15] = "Back", [16] = "Main Hand", [17] = "Off Hand", [18] = "Relic",
}

function S.SlotsFor(link)
    local loc
    if C_Item and C_Item.GetItemInfoInstant then
        loc = select(4, ns.try(C_Item.GetItemInfoInstant, link))
    end
    return loc and S.SLOTS[loc], loc
end

-- Item stat keys that map onto a slider. Spell power lines in this era say
-- "damage and healing", so they move both the Spell Power and Healing sliders.
local ITEM_TO_SLIDER = { str = { "str" }, agi = { "agi" }, int = { "int" }, sp = { "sp", "heal" },
                         ap = { "ap" }, crit = { "crit" }, hit = { "hit" } }

-- new = stats of the item you're trying, old = the item it would replace.
-- Returns the slider values, and the weapon to use if it's a main-hand weapon.
function S.ItemDelta(new, old, slot)
    local add = S.Empty()
    for k, sliders in pairs(ITEM_TO_SLIDER) do
        local d = (new[k] or 0) - (old[k] or 0)
        for _, key in ipairs(sliders) do add[key] = add[key] + d end
    end
    local weapon
    if slot == 16 and new.wMin then
        weapon = { min = new.wMin, max = new.wMax, speed = new.wSpeed, name = new.name }
    end
    -- Stats that don't change damage, shown as a note.
    local other = {}
    for _, k in ipairs({ "sta", "spi" }) do
        local d = (new[k] or 0) - (old[k] or 0)
        if d ~= 0 then other[#other + 1] = (d > 0 and "+" or "") .. d .. (k == "sta" and " Stamina" or " Spirit") end
    end
    return add, weapon, other
end
