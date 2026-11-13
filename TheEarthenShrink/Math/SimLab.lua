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
    -- Agility / Intellect per 1% crit: asked from the game, else the 🔶
    -- Classic rule. See Math/HitCrit.lua (H.Conversions).
    manaPerInt = 15,          -- 🔶 1 Intellect = 15 mana
    -- Mental Dexterity (Enhancement talent, 3 points): attack power from
    -- Intellect. The shaman patch is live (Angel, in game 2026-11-13):
    -- 33% / 66% / 100% of Intellect for 1 / 2 / 3 points. The talent's own
    -- text wins when the addon can read it (see MentalDexRatio).
    mentalDexApPerInt = 1.0,     -- with all points
    -- Mental Quickness (Enhancement talent): spell damage and healing from
    -- Intellect. Angel, in game 2026-11-13: 30% of Intellect at max rank.
    -- We split that evenly over the ranks the game says it has (2 ranks =
    -- 15% each, 3 ranks = 10% each). The talent's own text wins when the
    -- addon can read it (see MentalQuickRatio).
    mentalQuickSpPerIntMax = 0.30,
}

---------------------------------------------------------------------------
-- Talents the Sim Lab knows about
---------------------------------------------------------------------------
-- By default the points come from your character (read from the game).
-- You can turn a talent off ("I don't have it") or set other points to
-- test a different build. "Reset" goes back to your real talents.
--   db.simTalents[key] = { points = n or nil, off = true or nil }
-- maxFallback = the max points we use only if the game doesn't tell us.
S.TALENTS = {
    { key = "MD", name = "Mental Dexterity", what = "Intellect gives attack power",
      maxFallback = 3 },   -- Angel, in game 2026-11-12: "3 ranks"
    { key = "MQ", name = "Mental Quickness", what = "Intellect gives spell power",
      maxFallback = 3 },   -- 🔶 guess; the game's number wins when the addon can read it
    -- Talents that change weapon buffs (Angel, in game 2026-11-12: both
    -- change Rockbiter). HOW MUCH is read from the talent's own text by
    -- Math/TalentMods.lua; nothing here is a typed-in number.
    { key = "EW", name = "Elemental Weapons", what = "Makes weapon buffs stronger (read from the talent text)",
      maxFallback = 3, buff = true },   -- 🔶 max is a guess until the game tells us
    { key = "SW", name = "Spirit Weapons", what = "Changes weapon buffs (read from the talent text)",
      maxFallback = 3, buff = true },   -- 🔶 max is a guess until the game tells us
}
S.TALENT_BY_KEY = {}
for _, t in ipairs(S.TALENTS) do S.TALENT_BY_KEY[t.key] = t end

local function talentDb(key)
    local db = ns.db()
    db.simTalents = db.simTalents or {}
    db.simTalents[key] = db.simTalents[key] or {}
    return db.simTalents[key]
end

-- Everything about one talent for the Sim Lab:
--   real   = your points, read from the game (nil if the addon can't tell)
--   max    = most points it can have (from the game, else maxFallback)
--   points = the points the Sim Lab uses now (0 when turned off)
--   set    = the points you picked (or real), even while turned off
--   on     = the "I have it" tick
--   changed = true if you changed anything from your real talents
function S.Talent(key)
    local t = S.TALENT_BY_KEY[key]
    local real, max = nil, nil
    if ns.Talents then real, max = ns.Talents.Rank(t.name) end
    local maxFromGame = max ~= nil and max > 0
    max = maxFromGame and max or t.maxFallback
    local d = talentDb(key)
    -- Settings from v0.9 (a tick box and a number) carry over once, but
    -- only if the game doesn't tell us your real talents.
    local db = ns.db()
    if real == nil and not d.migrated then
        d.migrated = true
        if key == "MD" and db.simMentalDex then d.points = max end
        if key == "MQ" and type(db.simMentalQuick) == "number" then d.points = db.simMentalQuick end
    end
    local set = d.points or real or 0
    set = math.max(0, math.min(max, set))
    local on = not d.off and set > 0
    return {
        key = key, name = t.name, what = t.what, real = real, max = max, maxFromGame = maxFromGame,
        set = set, on = on, points = on and set or 0,
        changed = (d.points ~= nil and d.points ~= real) or (d.off ~= nil and set > 0),
    }
end

-- Tick "I have it" on or off.
function S.SetTalentOn(key, on)
    local d = talentDb(key)
    local info = S.Talent(key)
    if on then
        d.off = nil
        if info.set == 0 then d.points = 1 end     -- ticking it with 0 points means at least 1
    else
        d.off = true
    end
end

-- Pick the points (the slider). 0 points also clears the tick.
function S.SetTalentPoints(key, n)
    local d = talentDb(key)
    d.points = math.floor(n + 0.5)
    d.off = nil
end

-- Back to the talents your character really has.
function S.ResetTalents()
    local db = ns.db()
    db.simTalents = db.simTalents or {}
    for _, t in ipairs(S.TALENTS) do db.simTalents[t.key] = { migrated = true } end
end

-- Attack power per Intellect from ONE point of Mental Dexterity. From the
-- talent's own text if we can read it, otherwise the rule above.
-- Returns ratio per point, source.
function S.MentalDexRatio()
    local info = S.Talent("MD")
    local text = ns.Talents and ns.Talents.Description("Mental Dexterity")
    local pct = text and tonumber(text:lower():match("(%d+)%% of your intellect"))
    if pct then
        -- The text may show any one rank, so we read which SET of numbers
        -- it is: 50/100/150 (now) or 33/66/100 (after the patch).
        if pct == 33 or pct == 66 then return 1 / 3, "talent" end
        if pct == 50 or pct == 150 then return 0.5, "talent" end
        if pct == 100 and info.real == 2 then return 0.5, "talent" end
        if pct == 100 and info.real == 3 then return 1 / 3, "talent" end
        -- Any other number: the text shows one rank. If it's a whole
        -- step of the rule (like 33 of 100), use it per point.
        local k = info.max and info.max > 0 and math.floor(pct / (S.RULES.mentalDexApPerInt * 100 / info.max) + 0.5)
        if k and k >= 1 and k <= info.max then return pct / 100 / k, "talent" end
    end
    return S.RULES.mentalDexApPerInt / info.max, "rule"
end

-- Spell power per Intellect from ONE point of Mental Quickness. Same idea:
-- the talent's text if we can read it, else 30% at max rank split evenly.
-- Returns ratio per point, source.
function S.MentalQuickRatio()
    local info = S.Talent("MQ")
    local maxPct = S.RULES.mentalQuickSpPerIntMax * 100
    local step = maxPct / info.max
    local text = ns.Talents and ns.Talents.Description("Mental Quickness")
    local pct = text and tonumber(text:lower():match("(%d+)%% of your intellect"))
    if pct then
        -- The text shows one rank. Which one? The one whose number fits.
        local k = math.floor(pct / step + 0.5)
        if k >= 1 and k <= info.max and math.abs(pct - k * step) <= 1 then return pct / 100 / k, "talent" end
        -- It doesn't fit the 30% rule. Trust the game: count it as your rank.
        if info.real and info.real > 0 then return pct / 100 / info.real, "talent" end
    end
    return step / 100, "rule"
end

-- Points in each talent that the Sim Lab uses right now.
-- talentPoints = every talent's points (your real ones, with the Sim Lab
-- changes on top). Spells and weapon buffs use it, so "Real" and the tick
-- boxes change Rockbiter and co. too (Math/TalentMods.lua).
function S.TalentOpts()
    local points = {}
    for name, n in pairs(ns.TalentMods and ns.TalentMods.RealPoints() or {}) do points[name] = n end
    for _, t in ipairs(S.TALENTS) do points[t.name] = S.Talent(t.key).points end
    return { mentalDex = S.Talent("MD").points, mentalQuick = S.Talent("MQ").points, talentPoints = points }
end

-- The stats you can add. Order = order of the sliders.
S.STATS = {
    { key = "str",  label = "Strength",       min = -60, max = 120, step = 1 },
    { key = "agi",  label = "Agility",        min = -60, max = 120, step = 1 },
    { key = "int",  label = "Intellect",      min = -60, max = 120, step = 1 },
    { key = "sp",   label = "Spell Power",    min = -60, max = 150, step = 1 },
    { key = "heal", label = "Healing",        min = -60, max = 150, step = 1 },
    { key = "ap",   label = "Attack Power",   min = -100, max = 300, step = 2 },
    { key = "crit", label = "Crit chance",    min = -5, max = 10, step = 1, unit = "%",
      tip = "Extra chance to land a critical hit, in percentage points: +1 here takes you from 9.6% to 10.6%. In Forever gear crit counts for melee AND spells." },
    { key = "hit",  label = "Hit chance",     min = -5, max = 10, step = 1, unit = "%",
      tip = "Extra chance to hit (fewer misses), in percentage points. In Forever gear hit counts for melee AND spells. Past the hit cap it does nothing (see the Weights view)." },
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
    local mqPer = S.MentalQuickRatio()
    local spFromInt = (add.int or 0) * mqPer * mq
    q.sp = {}
    for school, v in pairs(p.sp or {}) do q.sp[school] = v + (add.sp or 0) + spFromInt end
    q.source = "sim"
    -- Talents for spells and buffs (nil = your real talents).
    q.talentPoints = opts.talentPoints or p.talentPoints
    if spFromInt ~= 0 then
        note(("%s Intellect × %s%% × %d (Mental Quickness) = %s spell power and healing"):format(
            f(add.int), f(mqPer * 100, 1), mq, f(spFromInt, 1)))
    end

    local apFromStr = (add.str or 0) * R.apPerStr
    local md = tonumber(opts.mentalDex) or 0
    local mdRatio = S.MentalDexRatio() * md
    local apFromInt = (add.int or 0) * mdRatio
    q.ap = (p.ap or 0) + apFromStr + apFromInt + (add.ap or 0)
    if apFromStr ~= 0 then note(("%s Strength × %s = %s attack power"):format(f(add.str), f(R.apPerStr), f(apFromStr))) end
    if apFromInt ~= 0 then note(("%s Intellect × %s (Mental Dexterity, %d points) = %s attack power"):format(f(add.int), f(mdRatio, 2), md, f(apFromInt))) end

    local conv = ns.HitCrit.Conversions(L)
    q.target = ns.db().simTarget or "same"
    local critFromAgi = (add.agi or 0) / conv.agi
    -- add.mcrit / add.scrit = melee-only / spell-only crit (used by the stat weights)
    q.meleeCrit = math.max(0, (p.meleeCrit or 0) + critFromAgi + (add.crit or 0) + (add.mcrit or 0))
    if critFromAgi ~= 0 then note(("%s Agility ÷ %s = %s%% melee crit"):format(f(add.agi), f(conv.agi, 1), f(critFromAgi, 2))) end

    local intPerCrit = conv.int
    local critFromInt = (add.int or 0) / intPerCrit
    q.spellCrit = math.max(0, (p.spellCrit or 0) + critFromInt + (add.crit or 0) + (add.scrit or 0))
    if critFromInt ~= 0 then note(("%s Intellect ÷ %s = %s%% spell crit"):format(f(add.int), f(intPerCrit, 1), f(critFromInt, 2))) end

    local manaFromInt = (add.int or 0) * R.manaPerInt
    q.mana = math.max(0, (p.mana or 0) + manaFromInt)
    if manaFromInt ~= 0 then note(("%s Intellect × %s = %s mana"):format(f(add.int), f(R.manaPerInt), f(manaFromInt))) end

    q.hit = (p.hit or 0) + (add.hit or 0)
    q.spellHit = (p.spellHit or 0) + (add.hit or 0)
    q.healing = (p.healing or 0) + (add.heal or 0) + spFromInt
    if opts.weapon and opts.weapon.min then q.weapon = opts.weapon end
    -- Weapon DPS (used by the stat weights): +1 DPS = + speed damage per hit.
    if (add.wdps or 0) ~= 0 and q.weapon and q.weapon.speed then
        local w = {}
        for k, v in pairs(q.weapon) do w[k] = v end
        w.min, w.max = w.min + add.wdps * w.speed, w.max + add.wdps * w.speed
        q.weapon = w
    end
    return q, why
end

-- Plain melee swings with your main-hand weapon (no weapon buff).
function S.Melee(p)
    local w = p.weapon
    if not (w and w.min and w.speed and w.speed > 0) then return nil end
    local IR = ns.ImbueMath.RULES
    local c = {}
    c.avg = (w.min + w.max) / 2 + (p.ap or 0) / IR.apPerDps * w.speed
    c.land = ns.HitCrit.LandChance(p)
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
local ITEM_TO_SLIDER = { str = { "str" }, agi = { "agi" }, int = { "int" }, sp = { "sp", "heal" }, heal = { "heal" },
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
    -- Crit / hit RATING (if Forever gear has it): turn into % if the game
    -- tells us how much rating = 1%, else show it as a note.
    local other = {}
    for _, k in ipairs({ "crit", "hit" }) do
        local d = (new[k .. "Rating"] or 0) - (old[k .. "Rating"] or 0)
        if d ~= 0 then
            local per = ns.HitCrit.RatingPerPercent(k)
            if per then
                add[k] = add[k] + d / per
            else
                other[#other + 1] = ("%s%d %s rating (can't turn into %% yet)"):format(d > 0 and "+" or "", d, k)
            end
        end
    end
    -- Stats that don't change damage, shown as a note.
    for _, k in ipairs({ "sta", "spi" }) do
        local d = (new[k] or 0) - (old[k] or 0)
        if d ~= 0 then other[#other + 1] = (d > 0 and "+" or "") .. d .. (k == "sta" and " Stamina" or " Spirit") end
    end
    return add, weapon, other
end
