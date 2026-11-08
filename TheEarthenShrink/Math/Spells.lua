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

-- Works out the spell power coefficient for one rank.
function M.Coefficients(spell, rank)
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

-- Everything about one spell rank for one character.
-- Returns nil if the game didn't give us enough to calculate.
function M.Calc(spell, rank, profile)
    if not rank or not rank.dmg or not rank.mana or rank.mana <= 0 then return nil end
    local R, d = M.RULES, rank.dmg
    local sp = (profile.sp and profile.sp[spell.school or "Nature"]) or 0
    if ns.db().tooltipIncludesSpellPower then sp = 0 end
    local directC, dotC, penalty = M.Coefficients(spell, rank)

    local avgBase = (d.min + d.max) / 2
    local direct = avgBase + sp * directC
    local dot = (d.dot or 0) + (d.dot and sp * dotC or 0)
    local hit = math.min(R.maxSpellHit, R.baseSpellHit + (profile.spellHit or 0)) / 100
    local critMult = 1 + (profile.spellCrit or 0) / 100 * R.spellCritBonus

    local c = {}
    c.sp, c.directC, c.dotC, c.penalty = sp, directC, dotC, penalty
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
    lines[#lines + 1] = { "Base damage (tooltip)", base }
    if c.sp > 0 and c.directC > 0 then
        lines[#lines + 1] = ("%s avg + %s spell power × %s = %s"):format(f(c.avgBase, 1), f(c.sp), f(c.directC, 3), f(c.direct, 1))
    end
    if d.dot then
        lines[#lines + 1] = { ("Over %s sec"):format(f(d.dotSec)), f(c.dot, 1) }
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
