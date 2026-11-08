-- The Earthen Shrink: weapon buff (imbue) math
--
-- Works out how much DPS Rockbiter, Flametongue and Windfury add for one
-- character, using the highest rank they can have at their level.
-- The imbue numbers (attack power, fire damage, proc chance) come from the
-- game's own tooltip. The rules marked 🔶 are Classic placeholders.

local _, ns = ...
local M = {}
ns.ImbueMath = M

M.RULES = {
    apPerDps = 14,          -- 🔶 14 attack power = +1 weapon DPS
    meleeMiss = 5,          -- 🔶 % miss chance vs a mob your level (hit gear lowers it)
    dodge = 5,              -- 🔶 % chance the mob dodges
    meleeCritBonus = 1.0,   -- 🔶 a melee crit does +100% damage
    spellCritBonus = 0.5,   -- 🔶 a fire crit does +50% damage
    ftRefSpeed = 4.0,       -- 🔶 Flametongue tooltip max = a 4.0 speed weapon
}

M.ORDER = { "RB", "FT", "WF" }

local function landChance(p)
    local R = M.RULES
    local miss = math.max(0, R.meleeMiss - (p.hit or 0))
    return math.max(0, 1 - (miss + R.dodge) / 100)
end

-- Returns { dps = number, math = { lines }, short = "one line formula" } or nil + reason.
function M.Calc(key, rank, p)
    local R, f = M.RULES, ns.fmt
    if not rank then return nil, "not learned at this level" end
    local im = rank.imbue
    if not im then return nil, "couldn't read the tooltip" end
    local w = p.weapon
    if not (w and w.min and w.speed) then return nil, "no weapon found" end

    local land = landChance(p)
    local meleeCrit = 1 + (p.meleeCrit or 0) / 100 * R.meleeCritBonus
    local out = { lines = {} }
    local L = out.lines

    if key == "RB" then
        -- Every hit does +AP÷14 × speed more damage, so per second it's AP÷14.
        out.dps = im.ap / R.apPerDps * land * meleeCrit
        L[#L + 1] = { "Attack power (tooltip)", "+" .. f(im.ap) }
        L[#L + 1] = ("%s ÷ %s × %s%% land × %s crit = %s DPS"):format(
            f(im.ap), f(R.apPerDps), f(land * 100), f(meleeCrit, 2), f(out.dps, 1))
        out.short = ("+%sAP/14 x%d%%land x%.2fcrit"):format(f(im.ap), land * 100, meleeCrit)

    elseif key == "FT" then
        -- 🔶 The tooltip shows a range for fast to slow weapons. We scale the
        -- top number by your weapon speed.
        local perHit = im.min == im.max and im.max or im.max * w.speed / R.ftRefSpeed
        local fireCrit = 1 + (p.spellCrit or 0) / 100 * R.spellCritBonus
        out.dps = perHit / w.speed * land * fireCrit
        out.perHit = perHit
        L[#L + 1] = { "Fire damage (tooltip)", f(im.min, 1) .. " to " .. f(im.max, 1) }
        if im.min ~= im.max then
            L[#L + 1] = ("%s × %s speed ÷ %s = %s per hit"):format(f(im.max, 1), f(w.speed, 2), f(R.ftRefSpeed, 1), f(perHit, 1))
        end
        L[#L + 1] = ("%s ÷ %s sec × %s%% land × %s crit = %s DPS"):format(
            f(perHit, 1), f(w.speed, 2), f(land * 100), f(fireCrit, 2), f(out.dps, 1))
        out.short = ("%.1f/hit / %.2fspd x%d%%land x%.2fcrit"):format(perHit, w.speed, land * 100, fireCrit)

    elseif key == "WF" then
        -- A hit that lands has a chance to give extra attacks with bonus AP.
        local avgW = (w.min + w.max) / 2
        local extra = avgW + ((p.ap or 0) + im.ap) / R.apPerDps * w.speed
        local procsPerSec = land * (im.chance / 100) / w.speed
        out.dps = procsPerSec * im.attacks * extra * land * meleeCrit
        L[#L + 1] = { "Proc chance (tooltip)", f(im.chance) .. "%" }
        L[#L + 1] = { "Extra attacks", f(im.attacks) .. (im.attacksGuessed and " (guess)" or "") }
        L[#L + 1] = ("One extra hit: %s weapon + (%s AP + %s) ÷ 14 × %s = %s"):format(
            f(avgW, 1), f(p.ap or 0), f(im.ap), f(w.speed, 2), f(extra, 1))
        L[#L + 1] = ("%s%% × %s%% ÷ %s sec × %d × %s × %s%% × %s crit = %s DPS"):format(
            f(land * 100), f(im.chance), f(w.speed, 2), im.attacks, f(extra, 1), f(land * 100), f(meleeCrit, 2), f(out.dps, 1))
        out.short = ("%d%%x%dx%.0f/%.2fspd x%d%%land x%.2fcrit"):format(im.chance, im.attacks, extra, w.speed, land * 100, meleeCrit)
    end
    return out
end

-- Calculates all three for a profile and sorts best first.
-- Returns a list of { key, name, rank, calc, reason }.
function M.Compare(p)
    local list = {}
    for _, key in ipairs(M.ORDER) do
        local spell = ns.RANKS_BY_KEY[key]
        local rank = ns.SpellData.Best(key, p.level or 1)
        local calc, reason = M.Calc(key, rank, p)
        list[#list + 1] = { key = key, name = spell.name, rank = rank, calc = calc, reason = reason }
    end
    table.sort(list, function(a, b)
        local da, db = a.calc and a.calc.dps or -1, b.calc and b.calc.dps or -1
        return da > db
    end)
    return list
end
