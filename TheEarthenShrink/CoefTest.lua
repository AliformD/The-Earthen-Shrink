-- The Earthen Shrink: Spell Power Test (keeps your test numbers)
--
-- This file holds the "Before" and "After" hit lists for each spell, checks
-- every number you add, and saves finished results so the Spells tab and
-- the Sim Lab use YOUR measured coefficient instead of the old Classic rule.
--
-- How numbers get in:
--   * You type them (always works). Look at the damage number that pops up
--     over the mob, or the game's damage meter, and type it in.
--   * Automatically, ONLY if this client lets addons read the combat log.
--     Our research says Forever hides it (like the newest retail WoW), so
--     this is switched off unless the game really has it.
--
-- The math is in Math/CoefTest.lua. The window page is UI/CoefTab.lua.

local _, ns = ...
local T = {}
ns.CoefTest = T
local f = function(...) return ns.fmt(...) end

-- Damage spells you can test, in list order.
T.KEYS = { "LB", "CL", "ES", "FlS", "FrS", "FN", "LvB" }
-- Weapon buffs and totems that do fire damage you can see and type.
T.EXTRA_KEYS = { "FT", "FTT", "ST", "MT" }

T.PART_NAMES = { direct = "hit", tick = "over time", proc = "fire per swing", totem = "totem hit" }

-- 🔶 OLD CLASSIC RULES used to guess "how often you use it" for the stat
-- weight. Not tested in Forever.
T.SHOCK_COOLDOWN = 6        -- Earth / Frost Shock: one every 6 sec
T.SEARING_INTERVAL = 2.5    -- Searing Totem attacks every 2.5 sec (if its tooltip doesn't say)

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
-- db.coefTests[id] = { before = { sp, hits = {} }, after = { sp, hits = {} } }
-- db.coefSaved[key][rank][part] = { coef, total, margin, totalMargin, ... }
-- db.coefTicks[id] = ticks in one cast (for "over time" tests)
-- db.coefActive = "before" or "after" (where typed numbers go)
-- id looks like "LB:4:direct".

local function db() return ns.db() end

function T.Id(key, rank, part) return key .. ":" .. rank .. ":" .. part end

-- One thing you can test. Fields the page uses:
--   low, high  = smallest and biggest normal hit with 0 spell power
--   spread     = how much the hits jump around (0 = always the same number)
--   avg        = the average hit with 0 spell power
--   what       = what to type, in words
--   every      = 🔶 how many seconds between uses (for the stat weight)
local function target(spell, rank, part, fields)
    local t = { spell = spell, rank = rank, part = part, id = T.Id(spell.key, rank.rank, part),
                school = spell.school or "Fire" }
    for k, v in pairs(fields) do t[k] = v end
    t.avg = t.avg or (t.low + t.high) / 2
    return t
end

local function castTime(rank) return math.max(rank.cast or 0, ns.SpellMath.RULES.gcd) end

-- Flametongue (weapon or totem): fire damage on each of your swings.
local function flametongue(spell, rank, weapon)
    local im = rank.imbue
    if not (im and im.min and weapon and weapon.speed) then return nil end
    -- 🔶 The tooltip range is for slow to fast weapons; we scale by speed.
    local per = im.min == im.max and im.max or im.max * weapon.speed / ns.ImbueMath.RULES.ftRefSpeed
    return target(spell, rank, "proc", {
        low = im.min, high = im.max, spread = 0, avg = per, fixed = true, school = "Fire",
        what = "each " .. spell.name .. " fire hit on your swings (not crits)",
        every = weapon.speed,
    })
end

-- Everything you can test right now (your highest rank of each).
function T.Targets(level)
    local list = {}
    local C = ns.CoefMath
    for _, key in ipairs(T.KEYS) do
        local spell = ns.RANKS_BY_KEY[key]
        local rank = spell and ns.SpellData.Best(key, level)
        local d = rank and rank.dmg
        if d then
            local isShock = key == "ES" or key == "FrS" or key == "FlS"
            if d.max and d.max > 0 then
                list[#list + 1] = target(spell, rank, "direct", {
                    low = d.min, high = d.max, spread = C.SpreadFromRange(d.min, d.max),
                    what = "each normal hit (not crits)",
                    every = isShock and (d.dotSec or T.SHOCK_COOLDOWN) or castTime(rank),
                })
            end
            if d.dot then
                local t = target(spell, rank, "tick", { low = 0, high = 0, spread = 0, fixed = true,
                    what = "each tick", every = d.dotSec or 12 })
                local tick = d.dot / T.Ticks(t)
                t.low, t.high, t.avg = tick, tick, tick
                list[#list + 1] = t
            end
        end
    end

    local weapon = ns.Profile.Player().weapon
    for _, key in ipairs(T.EXTRA_KEYS) do
        local spell = ns.RANKS_BY_KEY[key]
        local rank = spell and ns.SpellData.Best(key, level)
        if rank then
            if key == "FT" or key == "FTT" then
                list[#list + 1] = flametongue(spell, rank, weapon)
            elseif rank.totem and rank.totem.min then
                local tm = rank.totem
                list[#list + 1] = target(spell, rank, "totem", {
                    low = tm.min, high = tm.max, spread = C.SpreadFromRange(tm.min, tm.max),
                    what = "each hit from the totem (not crits)",
                    every = tm.interval or (key == "ST" and T.SEARING_INTERVAL) or 2,
                })
            end
        end
    end
    return list
end

function T.Test(t)
    local tests = db().coefTests
    tests[t.id] = tests[t.id] or { before = { hits = {} }, after = { hits = {} } }
    return tests[t.id]
end

function T.Active()
    local a = db().coefActive
    return (a == "after") and "after" or "before"
end
function T.SetActive(which) db().coefActive = which; ns.refresh("coef") end

-- Ticks in one cast. 🔶 Default = duration ÷ 3 sec (old Classic rule).
function T.Ticks(t)
    if t.part ~= "tick" then return 1 end
    local saved = db().coefTicks[t.id]
    if saved then return saved end
    local d = t.rank.dmg
    return math.max(1, math.floor((d.dotSec or 12) / ns.CoefMath.RULES.tickSeconds + 0.5))
end
function T.SetTicks(t, n) db().coefTicks[t.id] = math.max(1, math.min(20, n)); ns.refresh("coef") end

-- Your spell power for this school (nil if the game hides it).
function T.CurrentSP(t)
    local p = ns.Profile.Player()
    return p.sp and ns.clean(p.sp[t.school or "Nature"])
end

-- What the old Classic rule says, for this hit or ONE tick.
-- nil = there is no rule we know of (weapon buffs and totems).
function T.RuleCoef(t)
    if t.part == "proc" then
        local c = ns.db().ftCoef
        return (c and c > 0) and c or nil
    end
    if t.part == "totem" then return nil end
    local directC, dotC = ns.SpellMath.RuleCoefficients(t.spell, t.rank)
    if t.part == "tick" then return dotC / T.Ticks(t) end
    return directC
end

-- The smallest and biggest normal (non-crit) hit we'd expect. Used to catch
-- typos and crits. It's on purpose a bit wide, because the real coefficient
-- in Forever may be different from the rule.
function T.Range(t, sp)
    sp = sp or 0
    local rc = T.RuleCoef(t) or 0.3
    local extra = sp * (rc * 2 + 0.2)
    if t.part == "tick" then
        local tick = t.rank.dmg.dot / T.Ticks(t)
        return math.floor(tick * 0.85), math.ceil((tick + extra) * 1.1 + 1)
    end
    return math.floor(t.low * 0.9), math.ceil((t.high + extra) * 1.05 + 1)
end

---------------------------------------------------------------------------
-- Adding numbers
---------------------------------------------------------------------------

-- Adds a list of numbers to the active sample.
-- Returns how many were added and a message to show (or nil).
function T.Add(t, values, which, spNow)
    which = which or T.Active()
    local sample = T.Test(t)[which]
    if spNow == nil then spNow = T.CurrentSP(t) end

    if #sample.hits == 0 then
        if not spNow then
            return 0, "The game is hiding your spell power right now (in combat?). Try again after the fight."
        end
        sample.sp = spNow
    elseif spNow and spNow ~= sample.sp then
        -- Gear changed in the middle of a sample. Mixing them would ruin it.
        local other = which == "before" and "After" or "Before"
        return 0, ("Your spell power changed (%s when this sample started, %s now). Click %s, or Clear this sample."):format(
            f(sample.sp), f(spNow), other)
    end

    local low, high = T.Range(t, sample.sp)
    local added, problems = 0, {}
    for _, v in ipairs(values) do
        local ok, why = ns.CoefMath.Check(v, low, high)
        if ok then
            sample.hits[#sample.hits + 1] = v
            added = added + 1
        else
            problems[#problems + 1] = why
        end
    end
    ns.refresh("coef")
    if #problems > 0 then
        local msg = problems[1]
        if #problems > 1 then msg = msg .. (" (and %d more left out)"):format(#problems - 1) end
        return added, msg
    end
    return added, nil
end

function T.Undo(t, which)
    local sample = T.Test(t)[which or T.Active()]
    local v = table.remove(sample.hits)
    if #sample.hits == 0 then sample.sp = nil end
    ns.refresh("coef")
    return v
end

function T.Clear(t, which)
    T.Test(t)[which] = { hits = {} }
    T.Test(t)["tip_" .. which] = nil
    ns.refresh("coef")
end

function T.Result(t)
    local test = T.Test(t)
    return ns.CoefMath.Estimate(test.before, test.after, T.Ticks(t))
end

---------------------------------------------------------------------------
-- Tooltip method: Forever's tooltips change with your spell power, so the
-- change in the tooltip numbers IS the coefficient. No typing, no crits,
-- no random rolls. The only noise is that tooltips round to whole numbers.
---------------------------------------------------------------------------

-- The damage numbers in the tooltip right now, for this test.
-- Returns { min, max } (for ticks: the whole damage over time), or nil.
function T.ReadTooltip(t)
    local rec = ns.SpellData.ReadRank(t.spell, t.rank)
    if not rec then return nil end
    if t.part == "direct" and rec.dmg and rec.dmg.max and rec.dmg.max > 0 then
        return { min = rec.dmg.min, max = rec.dmg.max }
    elseif t.part == "tick" and rec.dmg and rec.dmg.dot then
        return { min = rec.dmg.dot, max = rec.dmg.dot }
    elseif t.part == "proc" and rec.imbue and rec.imbue.min then
        return { min = rec.imbue.min, max = rec.imbue.max }
    elseif t.part == "totem" and rec.totem and rec.totem.min then
        return { min = rec.totem.min, max = rec.totem.max }
    end
    return nil
end

-- Saves the tooltip numbers and your spell power into Before or After.
-- Returns the numbers, or nil + a message.
function T.SnapshotTooltip(t, which)
    which = which or T.Active()
    local sp = T.CurrentSP(t)
    if not sp then return nil, "The game is hiding your spell power right now (in combat?). Try after the fight." end
    local tip = T.ReadTooltip(t)
    if not tip then return nil, "Couldn't read damage numbers from this tooltip." end
    tip.sp = sp
    T.Test(t)["tip_" .. which] = tip
    ns.refresh("coef")
    return tip
end

local function isWhole(v) return math.abs(v - math.floor(v + 0.5)) < 1e-6 end

-- Coefficient from the two tooltip readings. Same fields as CoefMath.Estimate.
function T.TooltipResult(t)
    local test = T.Test(t)
    local a, b = test.tip_before, test.tip_after
    local R = ns.CoefMath.RULES
    local r = { method = "tooltip", tipBefore = a, tipAfter = b, ticks = T.Ticks(t) }
    if not (a and b) then r.verdict = "wait"; return r end
    r.dSP = b.sp - a.sp
    if r.dSP == 0 then
        r.verdict, r.why = "wait", "Both tooltip readings have the same spell power. Change your gear between them."
        return r
    end
    r.dMean = ((b.min + b.max) - (a.min + a.max)) / 2
    -- Each tooltip number can be rounded by up to 0.5, so a change can be
    -- off by up to 1. Numbers with decimals are much more exact.
    local err = (isWhole(a.min) and isWhole(a.max) and isWhole(b.min) and isWhole(b.max)) and 1 or 0.02
    local perUse = r.dMean / r.dSP
    r.margin = err / math.abs(r.dSP)
    if t.part == "tick" then
        r.total, r.totalMargin = perUse, r.margin           -- the whole damage over time
        r.coef = perUse / r.ticks
    else
        r.coef, r.total, r.totalMargin = perUse, perUse, r.margin
    end
    if r.totalMargin <= R.goodMargin then r.verdict = "good"
    elseif r.totalMargin <= R.okMargin then r.verdict = "ok"
    else r.verdict = "rough" end
    -- Proof that tooltips include spell power: switch the setting on once.
    local db = ns.db()
    if r.dMean ~= 0 and not db.tooltipIncludesSpellPower then
        db.tooltipIncludesSpellPower = true
        ns.say("your tooltips change with spell power, so the addon now knows they already include it (/es sptooltip).")
    end
    return r
end

-- The better of the two methods (smaller ±), and the other one.
function T.BestResult(t)
    local hits, tip = T.Result(t), T.TooltipResult(t)
    hits.method = "hits"
    local hitsOk, tipOk = hits.verdict ~= "wait", tip.verdict ~= "wait"
    if tipOk and (not hitsOk or tip.totalMargin <= hits.totalMargin) then return tip, hits end
    return hits, tip
end

---------------------------------------------------------------------------
-- Saving a result for the Spells tab and Sim Lab
---------------------------------------------------------------------------

-- Results measured in Forever that ship with the addon. Your own saved
-- result for the same spell and rank always wins over these.
T.SEEDS = {
    LB = { [6] = { direct = {
        coef = 17 / 24, total = 17 / 24, margin = 1 / 24, totalMargin = 1 / 24, dSP = 24,
        method = "tooltip", verdict = "good", date = "2026-11-12", seed = true,
        -- Angel's Forever tooltip, no Wizard Oil: 150 to 169 at 13 spell
        -- power, 167 to 186 at 37. Both ends +17. Tooltips round to whole
        -- numbers, so the true answer is somewhere in 0.67 to 0.75.
        note = "Angel's Forever tooltip: 150-169 at 13 SP, 167-186 at 37 SP",
    } } },
}

-- Your saved results for one rank, with the shipped ones filled in.
-- Returns a table like { direct = {...}, tick = {...} }.
function T.Saved(key, rank)
    local s = db().coefSaved[key]
    local mine = s and s[rank] or {}
    local seed = T.SEEDS[key] and T.SEEDS[key][rank]
    if not seed then return mine end
    local out = {}
    for part, v in pairs(seed) do out[part] = v end
    for part, v in pairs(mine) do out[part] = v end
    return out
end

function T.Save(t)
    local r = T.BestResult(t)
    if not (r.verdict == "good" or r.verdict == "ok") then return false end
    local saved = db().coefSaved
    local key, rank = t.spell.key, t.rank.rank
    saved[key] = saved[key] or {}
    saved[key][rank] = saved[key][rank] or {}
    saved[key][rank][t.part] = {
        coef = r.coef, total = r.total, margin = r.margin, totalMargin = r.totalMargin,
        ticks = r.ticks, dSP = r.dSP, method = r.method,
        hitsBefore = r.before and r.before.n or 0, hitsAfter = r.after and r.after.n or 0,
        verdict = r.verdict, date = date and date("%Y-%m-%d") or nil,
    }
    ns.say(("saved: %s rank %d %s = %s ± %s. The Spells tab and Sim Lab use it now."):format(
        t.spell.name, rank, T.PART_NAMES[t.part] or t.part, f(r.total, 3), f(r.totalMargin, 3)))
    ns.refresh("coef")
    return true
end

function T.Forget(t)
    local s = db().coefSaved[t.spell.key]
    if s and s[t.rank.rank] then s[t.rank.rank][t.part] = nil end
    ns.refresh("coef")
end

---------------------------------------------------------------------------
-- Stat weight: how much is 1 spell power worth, next to 1 Strength?
---------------------------------------------------------------------------

-- Melee DPS you get from +1 Strength (your weapon, attack power rules).
function T.StrengthDps(p)
    p = p or ns.Profile.Player()
    local S = ns.SimMath
    local now = S.Melee(p)
    local plus = S.Melee((S.Apply(p, { str = 1 })))
    if not (now and plus) then return nil end
    return plus.dps - now.dps, now.land
end

-- coef = damage per spell power for ONE use (for ticks: the whole spell).
-- Returns { dps = DPS from 1 spell power, strEq = how many Strength that is }.
-- 🔶 Leaves out crits and misses on spells, and assumes you use it every
-- t.every seconds.
function T.Weight(t, coef, p)
    if not (coef and t.every and t.every > 0) then return nil end
    local strDps, land = T.StrengthDps(p)
    local perUse = coef
    -- Flametongue only adds fire when the swing lands.
    if t.part == "proc" then perUse = coef * (land or 1) end
    local w = { dps = perUse / t.every, strDps = strDps }
    if strDps and strDps > 0 then w.strEq = w.dps / strDps end
    return w
end

-- 1 Intellect, from the talents: spell power (Mental Quickness, valued with
-- your best saved test) + attack power (Mental Dexterity). Mana and crit
-- from Intellect are left out.
function T.IntellectValue(p, opts, weights)
    local S = ns.SimMath
    local strDps = T.StrengthDps(p)
    local int = { sp = S.RULES.mentalQuickSpPerIntPerRank * (opts.mentalQuick or 0), ap = 0, apDps = 0, spDps = 0 }
    if opts.mentalDex then
        int.ap = S.MentalDexRatio()
        local now = S.Melee(p)
        local plus = S.Melee((S.Apply(p, { ap = int.ap })))
        if now and plus then int.apDps = plus.dps - now.dps end
    end
    for _, w in ipairs(weights or T.Weights(p)) do
        if not int.best or w.dps > int.best.dps then int.best = w end
    end
    if int.best then int.spDps = int.sp * int.best.dps end
    int.dps = int.apDps + int.spDps
    if strDps and strDps > 0 then int.strEq = int.dps / strDps end
    return int
end

-- Every saved result you can use now, with its stat weight.
function T.Weights(p)
    p = p or ns.Profile.Player()
    local out = {}
    for _, t in ipairs(T.Targets(p.level or UnitLevel("player") or 1)) do
        local saved = T.Saved(t.spell.key, t.rank.rank)[t.part]
        if saved then
            local w = T.Weight(t, saved.total, p)
            if w then w.t, w.saved = t, saved; out[#out + 1] = w end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Automatic recording (only if the game lets addons read the combat log)
---------------------------------------------------------------------------

T.autoAvailable = type(CombatLogGetCurrentEventInfo) == "function"
T.autoOn = false

local function onCombatLog()
    if not T.autoOn then return end
    local info = { CombatLogGetCurrentEventInfo() }
    local sub, srcGUID = ns.clean(info[2]), ns.clean(info[4])
    if srcGUID == nil or srcGUID ~= UnitGUID("player") then return end
    local part = (sub == "SPELL_DAMAGE" and "direct") or (sub == "SPELL_PERIODIC_DAMAGE" and "tick") or nil
    if not part then return end
    local spellId, spellName = ns.clean(info[12]), ns.clean(info[13])
    local amount, overkill = ns.clean(info[15]), ns.clean(info[16])
    local resisted, blocked, absorbed, crit = ns.clean(info[18]), ns.clean(info[19]), ns.clean(info[20]), ns.clean(info[21])
    if type(amount) ~= "number" or crit then return end
    -- A partly resisted, blocked or absorbed hit, or a killing blow that was
    -- cut short, isn't a normal hit. Leave it out.
    if (resisted or 0) > 0 or (blocked or 0) > 0 or (absorbed or 0) > 0 or (overkill or 0) > 0 then return end
    for _, t in ipairs(T.Targets(UnitLevel("player") or 1)) do
        -- Some clients give spell ID 0; then the name has to do (your best rank).
        local same
        if spellId and spellId ~= 0 then same = t.rank.id == spellId else same = t.spell.name == spellName end
        if t.part == part and same then
            local sample = T.Test(t)[T.Active()]
            -- In combat the game may hide spell power, so we use the number
            -- from when the sample started.
            T.Add(t, { amount }, nil, sample.sp or T.CurrentSP(t))
            return
        end
    end
end

if T.autoAvailable then
    ns.on("COMBAT_LOG_EVENT_UNFILTERED", onCombatLog)
end

---------------------------------------------------------------------------
-- /es meter: shows what the game's own damage meter gives addons.
-- We don't know its shape in Forever yet. A screenshot of this output lets
-- us read hits from the meter later, so you'd type less.
---------------------------------------------------------------------------

local function dumpTable(t, indent, lines, depth)
    if #lines > 40 then return end
    for k, v in pairs(t) do
        if issecretvalue and issecretvalue(v) then
            lines[#lines + 1] = indent .. tostring(k) .. " = (hidden by the game)"
        elseif type(v) == "table" and depth < 3 then
            lines[#lines + 1] = indent .. tostring(k) .. " = {"
            dumpTable(v, indent .. "  ", lines, depth + 1)
            lines[#lines + 1] = indent .. "}"
        else
            lines[#lines + 1] = indent .. tostring(k) .. " = " .. tostring(v)
        end
        if #lines > 40 then lines[#lines + 1] = indent .. "..."; return end
    end
end

function T.DumpMeter()
    local DM = C_DamageMeter
    if not DM then ns.say("this client has no damage meter for addons."); return end
    ns.say("damage meter available: " .. tostring(ns.try(DM.IsDamageMeterAvailable)))
    local sessions = ns.try(DM.GetAvailableCombatSessions)
    if type(sessions) ~= "table" then ns.say("no fights saved by the meter (or hidden)."); return end
    local lines = {}
    dumpTable(sessions, "  ", lines, 1)
    ns.say(("the meter has %d fight(s). What it gives addons:"):format(#sessions))
    for _, l in ipairs(lines) do print(l) end
    ns.say("please send a screenshot of this to the addon thread.")
end

ns.on("PLAYER_REGEN_ENABLED", function() ns.refresh("coef") end)
