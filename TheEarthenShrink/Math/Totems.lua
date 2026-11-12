-- The Earthen Shrink: totem and breakpoint math
--
-- "Break-even" means: how long a totem has to stay down (or how many hits /
-- enemies it needs) before its mana was as well spent as casting your best
-- normal spell or heal instead.
--
-- Totem damage, healing, mana, timing and cost come from the game's tooltips.
-- Rules marked ✅ are from Blizzard's Forever posts; 🔶 are Classic placeholders.

local _, ns = ...
local M = {}
ns.TotemMath = M
local f = function(...) return ns.fmt(...) end

M.RULES = {
    totemGcd = 1.0,           -- ✅ totems use a 1.0 sec global cooldown in Forever
    callCast = 3.0,           -- ✅ Call of the Elements is a 3 sec cast (the game's value wins if it has one)
    recallRefund = 0.25,      -- ✅ Totemic Recall gives back 25% of the totems' mana
    searingInterval = 2.5,    -- 🔶 used only if the tooltip doesn't say how often it attacks
    magmaInterval = 2.0,      -- 🔶 used only if the tooltip doesn't say
    totemCoef = 0.08,         -- 🔶 share of spell power per totem hit
    partySize = 5,
}

local function totemPulse(spell, rank, p)
    rank = ns.TalentMods and ns.TalentMods.AdjustRank(rank, p) or rank
    local t = rank.totem
    local avg = (t.min + t.max) / 2
    if spell.totem == "dmg" or spell.totem == "aoe" then
        local sp = ns.db().tooltipIncludesSpellPower and 0 or ((p.sp and p.sp[spell.school or "Fire"]) or 0)
        avg = (avg + sp * M.RULES.totemCoef) * (1 + (p.spellCrit or 0) / 100 * ns.SpellMath.RULES.spellCritBonus)
    end
    return avg
end

-- Searing Totem damage per second at your level (nil if not learned or
-- its tooltip couldn't be read). Used to compare with Flametongue Totem.
function M.SearingDps(p)
    local spell = ns.RANKS_BY_KEY.ST
    local rank = ns.SpellData.Best("ST", p.level or 1, p)
    if not (rank and rank.totem and rank.totem.min) then return nil end
    return totemPulse(spell, rank, p) / (rank.totem.interval or M.RULES.searingInterval), rank
end

-- Works out one totem rank. Returns a table the Totems tab shows:
--   { cost, breakEven = "text for the column", verdict = "ok"/"mid"/"bad"/"info", lines = { tooltip math }, sub = "..." }
function M.Calc(spell, rank, p, refDmg, refHeal)
    rank = ns.TalentMods and ns.TalentMods.AdjustRank(rank, p) or rank
    local t, R = rank.totem, M.RULES
    local out = { lines = {}, mana = rank.mana }
    local L = out.lines
    if not rank.mana then out.breakEven, out.verdict, out.sub = "?", "info", "couldn't read the mana cost"; return out end
    out.manaPct = p.mana and p.mana > 0 and rank.mana / p.mana * 100 or nil
    if t and t.duration then out.sub = ("Lasts %s"):format(t.duration >= 60 and (f(t.duration / 60) .. " min") or (f(t.duration) .. " sec")) end

    if spell.totem == "buff" then
        out.breakEven, out.verdict = "-", "info"
        L[#L + 1] = "This totem gives a buff, so there's no mana to compare it with."
        if t and t.duration then
            L[#L + 1] = { "Mana per minute if you keep it up", f(rank.mana / t.duration * 60, 1) }
        end
        return out
    end
    if not t then out.breakEven, out.verdict = "?", "info"; L[#L + 1] = "Couldn't read the numbers from the tooltip."; return out end

    if spell.totem == "dmg" then
        if not refDmg then out.breakEven, out.verdict = "?", "info"; return out end
        local interval = t.interval or R.searingInterval
        local perHit = totemPulse(spell, rank, p)
        local need = rank.mana * refDmg.c.dpm
        local hits = math.ceil(need / perHit)
        local maxHits = t.duration and math.floor(t.duration / interval) or nil
        out.breakEven = ("%d hits / %ss"):format(hits, f(hits * interval))
        out.verdict = (maxHits and hits <= maxHits) and "ok" or "bad"
        L[#L + 1] = { "Damage per hit", f(perHit, 1) }
        L[#L + 1] = ("Same mana on %s R%d: %s × %s = %s damage"):format(refDmg.spell.name, refDmg.rank.rank, f(rank.mana), f(refDmg.c.dpm, 2), f(need))
        L[#L + 1] = ("%s ÷ %s per hit = %d hits"):format(f(need), f(perHit, 1), hits)
        L[#L + 1] = ("%d hits × %s sec = %s sec on the ground%s"):format(hits, f(interval, 1), f(hits * interval),
            t.interval and "" or " (attack speed is a guess)")
        if maxHits then L[#L + 1] = ("It can hit %d times before it ends."):format(maxHits) end

    elseif spell.totem == "aoe" then
        if not refDmg then out.breakEven, out.verdict = "?", "info"; return out end
        local interval = t.interval or R.magmaInterval
        local perPulse = totemPulse(spell, rank, p)
        local pulses = t.duration and math.floor(t.duration / interval) or 1
        local perEnemy = perPulse * pulses
        local need = rank.mana * refDmg.c.dpm
        local enemies = math.ceil(need / perEnemy)
        out.breakEven = ("%d+ enemies"):format(enemies)
        out.verdict = enemies <= 2 and "ok" or enemies <= 4 and "mid" or "bad"
        L[#L + 1] = { "Damage per pulse, each enemy", f(perPulse, 1) }
        L[#L + 1] = ("%d pulses × %s = %s per enemy (full duration)"):format(pulses, f(perPulse, 1), f(perEnemy))
        L[#L + 1] = ("Same mana on %s R%d = %s damage"):format(refDmg.spell.name, refDmg.rank.rank, f(need))
        L[#L + 1] = ("%s ÷ %s = worth it with %d or more enemies in range"):format(f(need), f(perEnemy), enemies)
        for n = 1, 5 do
            local sec = need / (perPulse * n) * interval
            L[#L + 1] = { ("%d enemies: pays off after"):format(n), sec <= (t.duration or 1e9) and (f(sec, 1) .. " sec") or "never" }
        end

    elseif spell.totem == "heal" then
        if not refHeal then out.breakEven, out.verdict = "?", "info"; L[#L + 1] = "No healing spell found to compare with."; return out end
        local interval = t.interval or 2
        local perTick = t.min
        local need = rank.mana * refHeal.c.hpm
        local sec1 = need / perTick * interval
        local secParty = sec1 / R.partySize
        out.breakEven = ("%ss (5: %ss)"):format(f(sec1), f(secParty))
        out.verdict = (not t.duration or sec1 <= t.duration) and "ok" or secParty <= t.duration and "mid" or "bad"
        L[#L + 1] = { "Heals each person", f(perTick) .. " every " .. f(interval, 1) .. " sec" }
        L[#L + 1] = ("Same mana on %s R%d: %s × %s = %s healing"):format(refHeal.spell.name, refHeal.rank.rank, f(rank.mana), f(refHeal.c.hpm, 2), f(need))
        L[#L + 1] = ("1 person hurt: %s ÷ %s × %s sec = %s sec"):format(f(need), f(perTick), f(interval, 1), f(sec1))
        L[#L + 1] = ("5 people hurt: %s ÷ 5 = %s sec"):format(f(sec1), f(secParty))

    elseif spell.totem == "mana" then
        local interval = t.interval or 2
        local perTick = t.manaIsPercent and (p.mana or 0) * t.mana / 100 or t.mana
        local sec = rank.mana / perTick * interval
        out.breakEven = f(sec) .. " sec"
        out.verdict = (not t.duration or sec <= t.duration) and "ok" or "bad"
        L[#L + 1] = { "Gives you", f(perTick, 1) .. " mana every " .. f(interval, 1) .. " sec" }
        L[#L + 1] = ("%s mana ÷ %s × %s sec = %s sec to pay for itself"):format(f(rank.mana), f(perTick, 1), f(interval, 1), f(sec))
        if t.duration then
            L[#L + 1] = { "Mana back over its full time", f(perTick * t.duration / interval) .. " (each party member too)" }
        end
    end
    return out
end

-- Fire Nova: how many enemies before it beats your best single-target spell.
function M.FireNovaBreakpoint(c, refDmg)
    if not c or not refDmg or c.dpm <= 0 then return nil end
    return math.ceil(refDmg.c.dpm / c.dpm)
end

-- Lightning Shield: how many charges must go off to match your best spell.
function M.ShieldBreakpoint(c, refDmg)
    if not c or not refDmg or c.perCharge <= 0 then return nil end
    return math.ceil(c.mana * refDmg.c.dpm / c.perCharge)
end
