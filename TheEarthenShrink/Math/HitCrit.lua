-- The Earthen Shrink: hit chance and crit chance, in one place
--
-- Angel asked: "what does Crit (1%) and Hit (1%) actually MEAN?" This file
-- holds every rule about them, so the Sim Lab, the Weapon Buffs tab and the
-- spell math all use the same numbers.
--
-- Plain words:
--   * Crit CHANCE = how often a hit is a critical hit (the big yellow number).
--     "1% crit" = one PERCENTAGE POINT, like going from 9.6% to 10.6%.
--   * Crit DAMAGE = how much bigger a crit is. Melee crits do double (+100%),
--     spell crits do one and a half (+50%). 🔶 Classic numbers.
--   * Hit chance = fewer misses. Once you never miss, more hit does nothing.
--     That point is the "hit cap". It is higher against bosses.
--
-- What we know about Forever (checked 2026-11-12):
--   * Blizzard (WoW Forever Deep Dive, Sept 2026, via method.gg and
--     rankedboost.com): melee, ranged and spell HIT are one combined stat, and
--     so is CRIT. So 1% crit or hit from gear helps melee AND spells.
--   * Whether gear says "+1% crit" or "+14 crit rating" is NOT settled: sites
--     disagree. The item reader understands both (rating needs the game to
--     tell us how much rating = 1%).
--   * Hit cap: Blizzard has not announced one. The caps below are Classic
--     numbers 🔶.
--
-- C# comparison: a static class with constants and small pure functions.

local _, ns = ...
local H = {}
ns.HitCrit = H

H.RULES = {
    -- 🔶 Classic: you miss a same-level mob 5% of the time with melee, and a
    -- boss (3 levels higher) about 9% (8% plus 1% that weapon skill hides).
    -- That is also the most melee hit that does anything ("hit cap").
    meleeMiss = { same = 5, boss = 9 },
    -- 🔶 Classic: spells miss a same-level mob 4% and a boss 17%. 1% of that
    -- can never be removed, so the useful spell hit cap is 3% / 16%.
    spellMiss = { same = 3, boss = 16 },
    spellAlwaysMiss = 1,
    -- 🔶 Classic: a mob dodges 5% of your melee attacks (from the front or back).
    dodge = 5,
    -- 🔶 Classic, Shaman: 20 Agility = 1% melee crit.
    agiPerCrit = 20,
    -- 🔶 Classic: Intellect for 1% spell crit, about 59.5 at level 60.
    intPerCrit = function(level) return 10 + 49.5 * (level / 60) end,
    -- 🔶 Flurry (Enhancement talent): after a crit, your next 3 swings are
    -- faster. Nov 2 beta notes said 6% to 30% (6% per point). The talent's
    -- own text wins if the addon can read it.
    flurryPerPoint = 6,
    flurrySwings = 3,
}

-- Who you fight. Only the Sim Lab lets you pick; other tabs use "same".
H.TARGETS = {
    same = { id = "same", name = "Same level mob", short = "same level" },
    boss = { id = "boss", name = "Boss (+3 levels)", short = "boss +3" },
}

function H.Target(p)
    local id = p and p.target or "same"
    return H.TARGETS[id] or H.TARGETS.same
end

-- Hit caps for this target: melee, spell (in %).
function H.Caps(p)
    local t = H.Target(p).id
    return H.RULES.meleeMiss[t], H.RULES.spellMiss[t]
end

-- Chance a melee swing lands (not a miss, not a dodge), 0 to 1.
function H.LandChance(p)
    local melee = H.Caps(p)
    local miss = math.max(0, melee - (p.hit or 0))
    return math.max(0, 1 - (miss + H.RULES.dodge) / 100)
end

-- Chance a spell hits, 0 to 1.
function H.SpellHitChance(p)
    local _, spell = H.Caps(p)
    local miss = math.max(0, spell - (p.spellHit or p.hit or 0)) + H.RULES.spellAlwaysMiss
    return math.max(0, 1 - miss / 100)
end

---------------------------------------------------------------------------
-- How much Agility / Intellect = 1% crit
---------------------------------------------------------------------------
-- We ask the game first: "how much crit does your Agility give you?" and
-- divide your Agility by it. If the game can't answer, we use the Classic
-- rule (🔶). Returns { agi, agiFromGame, int, intFromGame }.
local function effStat(i)
    local _, eff = ns.try(UnitStat, "player", i)
    return ns.clean(eff)
end

function H.Conversions(level)
    level = level or (UnitLevel and UnitLevel("player")) or 60
    local out = { agi = H.RULES.agiPerCrit, int = H.RULES.intPerCrit(level) }
    local agi = effStat(2)
    local fromAgi = ns.clean(ns.try(GetCritChanceFromAgility, "player"))
    if agi and fromAgi and fromAgi > 0.05 then out.agi, out.agiFromGame = agi / fromAgi, true end
    local int = effStat(4)
    local fromInt = ns.clean(ns.try(GetSpellCritChanceFromIntellect, "player"))
    if int and fromInt and fromInt > 0.05 then out.int, out.intFromGame = int / fromInt, true end
    return out
end

---------------------------------------------------------------------------
-- Ratings (in case Forever gear says "crit rating" instead of "%")
---------------------------------------------------------------------------
-- How much rating = 1%, read from your own rating. nil if the game has no
-- ratings or you have none yet.
local CR = { crit = { "CR_CRIT_MELEE", 9 }, hit = { "CR_HIT_MELEE", 6 } }
function H.RatingPerPercent(kind)
    local c = CR[kind]
    if not c then return nil end
    local id = _G[c[1]] or c[2]
    local rating = ns.clean(ns.try(GetCombatRating, id))
    local bonus = ns.clean(ns.try(GetCombatRatingBonus, id))
    if rating and bonus and rating > 0 and bonus > 0 then return rating / bonus end
    return nil
end

---------------------------------------------------------------------------
-- Flurry
---------------------------------------------------------------------------
-- Returns { points, pct = attack speed per proc (%), fromText } or nil.
function H.Flurry()
    local points = ns.Talents and ns.Talents.Rank("Flurry")
    if not points or points <= 0 then return nil end
    local text = ns.Talents.Description("Flurry")
    local pct = text and tonumber(text:lower():match("attack speed by (%d+)%%"))
    if pct then return { points = points, pct = pct, fromText = true } end
    return { points = points, pct = points * H.RULES.flurryPerPoint }
end

-- How much faster you swing on average with Flurry, as a multiplier (1 =
-- no change). uptime = chance at least one of your last 3 swings crit.
function H.FlurryFactor(p)
    local fl = H.Flurry()
    if not fl then return 1, nil end
    local c = math.min(1, (p.meleeCrit or 0) / 100)
    local uptime = 1 - (1 - c) ^ H.RULES.flurrySwings
    fl.uptime = uptime
    return 1 + uptime * fl.pct / 100, fl
end
