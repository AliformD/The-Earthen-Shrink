-- The Earthen Shrink: damage math for spells
--
-- Base damage, mana cost and cast time come from the game's tooltips.
-- The rules marked 🔶 are OLD CLASSIC rules. They are placeholders until we
-- can test them in Forever, and they're kept in one place (RULES) so they're
-- easy to change.

local _, ns = ...
local M = {}
ns.SpellMath = M

M.RULES = {
    gcd = 1.5,                -- 🔶 global cooldown for spells, in seconds
    baseSpellHit = 96,        -- 🔶 % chance to hit a mob your own level
    maxSpellHit = 99,         -- 🔶 you can never go above this
    spellCritBonus = 0.5,     -- 🔶 a spell crit does +50% damage
    -- 🔶 How much of your spell power a spell gets ("coefficient"):
    --    cast time ÷ 3.5 for normal spells (instant spells count as 1.5 sec),
    --    duration ÷ 15 for damage over time,
    --    and half as much for spells that hit many enemies.
    directBase = 3.5, dotBase = 15, aoeFactor = 0.5,
    -- 🔶 Ranks learned before level 20 get less spell power:
    --    3.75% less for every level below 20.
    lowLevelPenaltyStart = 20, lowLevelPenaltyPerLevel = 0.0375,
}

-- Works out the spell power coefficient for one rank with the old Classic
-- rules (🔶). M.Coefficients below uses your own test result instead, if
-- you saved one on the Spell Power Test tab.
function M.RuleCoefficients(spell, rank)
    local R = M.RULES
    local cast = math.max(rank.cast or 0, R.gcd)
    local d = rank.dmg or {}
    local directC = (d.min and d.max and d.max > 0) and cast / R.directBase or 0
    local dotC = (d.dot and d.dotSec) and d.dotSec / R.dotBase or 0
    if directC > 0 and dotC > 0 then
        -- 🔶 Classic rule for spells that do both (like Flame Shock)
        local sum = directC + dotC
        directC, dotC = directC * directC / sum, dotC * dotC / sum
    end
    if spell.aoe then directC, dotC = directC * R.aoeFactor, dotC * R.aoeFactor end
    local penalty = 1
    if rank.level and rank.level < R.lowLevelPenaltyStart then
        penalty = 1 - (R.lowLevelPenaltyStart - rank.level) * R.lowLevelPenaltyPerLevel
    end
    return directC * penalty, dotC * penalty, penalty
end

-- The coefficient the rest of the addon uses. Returns direct, dot, penalty,
-- and where each number came from ("test" = you measured it in Forever,
-- "rule" = old Classic rule).
function M.Coefficients(spell, rank)
    local directC, dotC, penalty = M.RuleCoefficients(spell, rank)
    local src = { direct = "rule", dot = "rule" }
    local saved = ns.CoefTest and ns.CoefTest.Saved(spell.key, rank.rank) or {}
    if saved.direct and directC > 0 then
        directC, src.direct = saved.direct.coef, "test"
    end
    if saved.tick and dotC > 0 then
        dotC, src.dot = saved.tick.total, "test"
    end
    -- A tested number already has any low-rank penalty "baked in".
    if src.direct == "test" or src.dot == "test" then penalty = 1 end
    return directC, dotC, penalty, src
end

-- Everything about one spell rank for one character.
-- Returns nil if the game didn't give us enough to calculate.
function M.Calc(spell, rank, profile)
    if not rank or not rank.dmg or not rank.mana or rank.mana <= 0 then return nil end
    local R, d = M.RULES, rank.dmg
    local sp = (profile.sp and profile.sp[spell.school or "Nature"]) or 0
    local directC, dotC, penalty, src = M.Coefficients(spell, rank)

    local avgBase = (d.min + d.max) / 2
    local dotBase = d.dot or 0
    -- If the tooltip already has your spell power in it, take that part out
    -- first, so it isn't counted twice (and the Sim Lab can change it).
    local inTip = ns.db().tooltipIncludesSpellPower and (rank.spRead or 0) or 0
    avgBase = math.max(0, avgBase - inTip * directC)
    if d.dot then dotBase = math.max(0, dotBase - inTip * dotC) end
    local direct = avgBase + sp * directC
    local dot = d.dot and (dotBase + sp * dotC) or 0
    local hit = math.min(R.maxSpellHit, R.baseSpellHit + (profile.spellHit or 0)) / 100
    local critMult = 1 + (profile.spellCrit or 0) / 100 * R.spellCritBonus

    local c = {}
    c.sp, c.directC, c.dotC, c.penalty, c.coefSource = sp, directC, dotC, penalty, src
    c.inTip = inTip
    c.avgBase, c.direct, c.dot, c.hit, c.critMult = avgBase, direct, dot, hit, critMult
    c.expected = (direct * critMult + dot) * hit        -- dots don't crit (🔶)
    c.time = math.max(rank.cast or 0, R.gcd)
    c.mana = rank.mana
    c.dpm = c.expected / rank.mana
    c.dps = c.expected / c.time
    c.manaPct = profile.mana and profile.mana > 0 and rank.mana / profile.mana * 100 or nil
    c.castsPerBar = profile.mana and math.floor(profile.mana / rank.mana) or nil
    c.dmgPerBar = c.castsPerBar and c.castsPerBar * c.expected or nil
    return c
end

-- Lines of math for a tooltip. Each entry is { label, value } or a plain string.
function M.Explain(spell, rank, c)
    local f = ns.fmt
    local d = rank.dmg
    local lines = {}
    local base = d.min == d.max and f(d.min) or (f(d.min) .. " to " .. f(d.max))
    lines[#lines + 1] = { "Damage (tooltip)", base }
    if (c.inTip or 0) > 0 then
        lines[#lines + 1] = ("The tooltip already has your %s spell power in it, so %s is taken out first."):format(
            f(c.inTip), f(c.inTip * c.directC, 1))
    end
    local src = c.coefSource or {}
    local function tag(s) return s == "test" and " (your Forever test)" or " (old Classic rule)" end
    if c.sp > 0 and c.directC > 0 then
        lines[#lines + 1] = ("%s avg + %s spell power × %s%s = %s"):format(f(c.avgBase, 1), f(c.sp), f(c.directC, 3), tag(src.direct), f(c.direct, 1))
    end
    if d.dot then
        lines[#lines + 1] = { ("Over %s sec"):format(f(d.dotSec)), f(c.dot, 1) }
        if c.sp > 0 and c.dotC > 0 then
            lines[#lines + 1] = ("Over time: %s spell power × %s%s"):format(f(c.sp), f(c.dotC, 3), tag(src.dot))
        end
    end
    lines[#lines + 1] = ("× %s crit × %s%% hit = %s per cast"):format(f(c.critMult, 3), f(c.hit * 100), f(c.expected, 1))
    lines[#lines + 1] = ("%s ÷ %s mana = %s damage per mana"):format(f(c.expected, 1), f(c.mana), f(c.dpm, 2))
    lines[#lines + 1] = ("%s ÷ %s sec = %s DPS"):format(f(c.expected, 1), f(c.time, 1), f(c.dps, 1))
    if c.penalty < 1 then
        lines[#lines + 1] = ("Low rank: gets only %s%% of spell power (old Classic rule, not tested yet)"):format(f(c.penalty * 100))
    end
    if spell.aoe then lines[#lines + 1] = "Per enemy hit. 3 enemies = 3× the damage." end
    return lines
end

---------------------------------------------------------------------------
-- "Useful" ranks
---------------------------------------------------------------------------
-- A low rank can have great damage per mana but tiny DPS (nobody really casts
-- Lightning Bolt Rank 1). A rank only counts for "best per mana" when its
-- output per second is at least this share of the spell's best rank you have.
M.RULES.usefulShare = 0.5

-- Marks c.useful on every calc in a list of { spell, rank, c, locked }.
function M.MarkUseful(entries, field)
    field = field or "dps"
    local top = {}
    for _, e in ipairs(entries) do
        if e.c and not e.locked then
            local k = e.spell.key
            top[k] = math.max(top[k] or 0, e.c[field] or 0)
        end
    end
    for _, e in ipairs(entries) do
        if e.c then
            e.c.useful = not e.locked and (e.c[field] or 0) >= (top[e.spell.key] or 0) * M.RULES.usefulShare
        end
    end
end

---------------------------------------------------------------------------
-- Healing spells
---------------------------------------------------------------------------
M.RULES.healCritBonus = 0.5   -- 🔶 a heal crit heals +50%

function M.CalcHeal(spell, rank, p)
    if not rank or not rank.heal or not rank.mana or rank.mana <= 0 then return nil end
    local R, h = M.RULES, rank.heal
    local cast = math.max(rank.cast or 0, R.gcd)
    local coef = cast / R.directBase
    if rank.level and rank.level < R.lowLevelPenaltyStart then
        coef = coef * (1 - (R.lowLevelPenaltyStart - rank.level) * R.lowLevelPenaltyPerLevel)
    end
    local bonus = ns.db().tooltipIncludesSpellPower and 0 or (p.healing or 0)
    local c = { coef = coef, bonus = bonus, time = cast, mana = rank.mana }
    c.avgBase = (h.min + h.max) / 2
    c.expected = (c.avgBase + bonus * coef) * (1 + (p.spellCrit or 0) / 100 * R.healCritBonus) + (h.hot or 0)
    c.hpm = c.expected / rank.mana
    c.hps = c.expected / cast
    c.manaPct = p.mana and p.mana > 0 and rank.mana / p.mana * 100 or nil
    return c
end

---------------------------------------------------------------------------
-- Lightning Shield and Stormstrike
---------------------------------------------------------------------------
M.RULES.shieldCoef = 0.33     -- 🔶 share of spell power per Lightning Shield charge

function M.CalcShield(spell, rank, p)
    if not rank or not rank.shield or not rank.mana or rank.mana <= 0 then return nil end
    local R, sh = M.RULES, rank.shield
    local sp = ns.db().tooltipIncludesSpellPower and 0 or ((p.sp and p.sp.Nature) or 0)
    local c = { mana = rank.mana, charges = sh.charges }
    c.perCharge = (sh.dmg + sp * R.shieldCoef) * (1 + (p.spellCrit or 0) / 100 * R.spellCritBonus)
    c.expected = c.perCharge * sh.charges        -- all charges used before it ends
    c.dpm = c.expected / rank.mana
    c.time = R.gcd
    c.dps = c.expected / R.gcd                   -- damage per second of YOUR time spent casting it
    c.manaPct = p.mana and p.mana > 0 and rank.mana / p.mana * 100 or nil
    return c
end

-- Stormstrike weapon damage share. Used only if the tooltip doesn't give a %.
-- 1.0 = 100%. The Nov 2 beta notes raised it to 150%, but the 2026-11-10
-- hotfix put it back to 100% with an 8 sec cooldown (Angel, in game).
M.RULES.strikePct = 1.0

-- Stormstrike: one weapon hit. (Its +20% on your next shock or bolt is not added here.)
function M.CalcStrike(spell, rank, p)
    if not rank or not rank.mana or rank.mana <= 0 then return nil end
    local w = p.weapon
    if not (w and w.min and w.speed) then return nil end
    local IR = ns.ImbueMath.RULES
    local pct = rank.strikePct or M.RULES.strikePct
    local hit = ((w.min + w.max) / 2 + (p.ap or 0) / IR.apPerDps * w.speed) * pct
    local c = { mana = rank.mana, time = M.RULES.gcd, pct = pct, pctFromGame = rank.strikePct ~= nil }
    c.expected = hit * (1 + (p.meleeCrit or 0) / 100 * IR.meleeCritBonus)
    c.dpm = c.expected / rank.mana
    c.dps = c.expected / c.time
    c.manaPct = p.mana and p.mana > 0 and rank.mana / p.mana * 100 or nil
    return c
end

---------------------------------------------------------------------------
-- Reference numbers: "the best you'd get from a normal spell"
---------------------------------------------------------------------------

-- Best damage per mana from a useful single-target damage rank you have.
function M.BestDamageRef(p)
    local entries = {}
    for _, key in ipairs({ "LB", "CL", "ES", "FlS", "FrS", "LvB" }) do
        local spell = ns.RANKS_BY_KEY[key]
        for _, rank in ipairs(ns.SpellData.Ranks(key)) do
            local locked = rank.level and rank.level > p.level
            entries[#entries + 1] = { spell = spell, rank = rank, c = M.Calc(spell, rank, p), locked = locked }
        end
    end
    M.MarkUseful(entries, "dps")
    local best
    for _, e in ipairs(entries) do
        if e.c and e.c.useful and (not best or e.c.dpm > best.c.dpm) then best = e end
    end
    return best
end

-- Best healing per mana from a useful heal rank you have.
function M.BestHealRef(p)
    local entries = {}
    for _, key in ipairs({ "HW", "LHW", "CH", "RT" }) do
        local spell = ns.RANKS_BY_KEY[key]
        for _, rank in ipairs(ns.SpellData.Ranks(key)) do
            local locked = rank.level and rank.level > p.level
            entries[#entries + 1] = { spell = spell, rank = rank, c = M.CalcHeal(spell, rank, p), locked = locked }
        end
    end
    M.MarkUseful(entries, "hps")
    local best
    for _, e in ipairs(entries) do
        if e.c and e.c.useful and (not best or e.c.hpm > best.c.hpm) then best = e end
    end
    return best
end
