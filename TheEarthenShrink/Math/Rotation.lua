-- The Earthen Shrink: your whole damage (or healing) in one number
--
-- Angel's idea: when you fight you use a MIX of things: weapon swings, your
-- weapon buff, Stormstrike, shocks, a fire totem, Lightning Shield, maybe
-- Lightning Bolt. A stat is only "good" if it raises the TOTAL of that mix.
--
-- So this file:
--   1. Works out the DPS of each part of your mix ("Rotation").
--   2. Adds them up into one total.
--   3. Stat weights: adds a little of one stat, sees how much the TOTAL goes
--      up, and compares that with what Strength does.
--
-- What is a stat weight? It's "how much 1 point of this stat is worth,
-- counted in Strength". If Agility = 0.8, then 10 Agility does about the
-- same for your total damage as 8 Strength. It is ONE number per stat
-- because it already counts everything that stat does (Intellect: spell
-- power from Mental Quickness, attack power from Mental Dexterity, spell
-- crit, and mana).
--
-- C# comparison: like a static class of pure functions. Profile in, numbers
-- out. Nothing here touches the game except the saved settings.
--
-- Rules marked 🔶 are OLD CLASSIC rules or our own guesses, not tested in
-- Forever yet. They're all in RULES so they're easy to change.

local _, ns = ...
local R = {}
ns.Rotation = R

R.RULES = {
    -- Earth / Frost / Flame Shock share one 6 sec cooldown (Angel, in game
    -- 2026-11-12): one shock OR the other every 6 sec, never both.
    shockCooldown = 6,
    -- Stormstrike cooldown if its tooltip doesn't say. Angel saw 6 sec in
    -- game on 2026-11-12 (the hotfix to 8 sec hadn't happened yet).
    strikeCooldown = 6,
    -- Lightning Shield (Angel, in game 2026-11-12): one cast puts up 3 balls
    -- (charges). Each time something hits you, one ball strikes it and goes
    -- away (at most one every few seconds). When all 3 are gone you recast
    -- it and pay the mana again. 🔶 Our guess: one ball goes off every 15
    -- sec in a fight, so you recast every 45 sec. It depends on how often
    -- mobs hit you.
    shieldSecondsPerCharge = 15,
    -- 🔶 How long your fire totem lasts, if its tooltip doesn't say.
    totemDuration = 55,
    -- Stamina gives no damage, so it can't be measured like the others.
    -- Our estimate: worth a quarter of your main stat. Low enough that it
    -- never beats a damage stat, high enough to pick the tougher item when
    -- two items are close. This is a judgement call, not game data.
    staminaShare = 0.25,
}

-- Play styles: what's in the mix, and which stat counts as 1.0.
R.STYLES = {
    { id = "enh",   name = "Melee (Enhancement)",   short = "Melee",  base = "str",  unit = "DPS" },
    { id = "ele",   name = "Caster (Elemental)",    short = "Caster", base = "sp",   unit = "DPS" },
    { id = "resto", name = "Healer (Restoration)",  short = "Healer", base = "heal", unit = "HPS" },
}
R.STYLE_BY_ID = {}
for _, s in ipairs(R.STYLES) do R.STYLE_BY_ID[s.id] = s end

function R.Style()
    local id = ns.db().simStyle
    return R.STYLE_BY_ID[id] or R.STYLES[1]
end

-- How long a fight lasts, in seconds. Longer fights = mana matters more.
function R.FightSeconds() return ns.db().simFight or 60 end

---------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------

local f = function(...) return ns.fmt(...) end

local function gcd() return ns.SpellMath.RULES.gcd end

-- The tooltip number already has your spell power in it (Forever does
-- that). Take that part out, then add the spell power of the profile we're
-- testing, so the sliders change it.
local function withSpellPower(avg, rank, coef, sp)
    local inTip = ns.db().tooltipIncludesSpellPower and (rank.spRead or 0) or 0
    return math.max(0, avg - inTip * coef) + (sp or 0) * coef
end

local function spellHitChance(q) return ns.HitCrit.SpellHitChance(q) end

local function spellCritMult(q)
    return 1 + (q.spellCrit or 0) / 100 * ns.SpellMath.RULES.spellCritBonus
end

-- A coefficient from your SP Test if you saved one, else a rule.
local function testedCoef(key, rank, part, rule)
    local saved = ns.CoefTest and ns.CoefTest.Saved(key, rank.rank)[part]
    if saved then return saved.coef, true end
    return rule, false
end

local function best(key, q) return ns.SpellData.Best(key, q.level or 1) end

---------------------------------------------------------------------------
-- The parts of your mix
---------------------------------------------------------------------------
-- Each part: { key, name, icon, dps, mana = mana per second, usesMana,
--              every = seconds between uses, lines = math for the tooltip,
--              kind = "melee" / "spell" / "heal" }

-- Weapon swings and the weapon buff. imbueKey = the buff to use (so a
-- stat that changes which buff is best doesn't jump the numbers).
local function meleeParts(q, opts, out)
    local IM = ns.ImbueMath
    if not (q.weapon and q.weapon.min and q.weapon.speed and q.weapon.speed > 0) then return end
    local list = IM.Compare(q)
    local ctx = IM.lastCtx
    if not ctx then return end
    -- Flurry (if you have it): crits make your next swings faster, so crit
    -- also means MORE swings. 1 = no Flurry.
    local flurry, fl = ns.HitCrit.FlurryFactor(q)
    local swingDps = ctx.base / q.weapon.speed * flurry
    out[#out + 1] = {
        key = "melee", name = "Weapon swings", kind = "melee",
        icon = ns.try(GetInventoryItemTexture, "player", 16) or "Interface\\Icons\\INV_Axe_04",
        dps = swingDps, mana = 0, every = q.weapon.speed,
        lines = {
            ("One swing every %s sec, %s%% land, crits counted"):format(f(q.weapon.speed, 2), f(ctx.land * 100)),
            ctx.totem and "Includes Windfury Totem in your group" or "",
            ctx.ftTotem and "Includes Flametongue Totem fire on each hit" or "",
            fl and ("Flurry %d: +%s%% speed, on %s%% of the time = %s× swings%s"):format(fl.points, f(fl.pct),
                f(fl.uptime * 100), f(flurry, 3), fl.fromText and "" or " 🔶") or "",
            { "DPS", f(swingDps, 1) },
        },
    }
    local pick
    for _, e in ipairs(list) do
        if e.calc and (e.key == opts.imbueKey or (not opts.imbueKey and not pick)) then pick = e end
    end
    if pick then
        out[#out + 1] = {
            key = "imbue", name = pick.name, kind = "melee", imbueKey = pick.key,
            icon = pick.rank and pick.rank.icon, dps = pick.calc.dps * flurry, mana = 0, every = q.weapon.speed,
            lines = pick.calc.lines,
            sub = pick.key == "FT" and "weapon buff · fire uses spell crit" or "weapon buff",
        }
    end
end

-- Stormstrike: a weapon hit every cooldown.
local function strikePart(q, out)
    local spell, rank = ns.RANKS_BY_KEY.SS, best("SS", q)
    if not rank then return end
    local c = ns.SpellMath.CalcStrike(spell, rank, q)
    local melee = ns.SimMath.Melee(q)
    if not (c and melee) then return end
    local cd = rank.cooldown or R.RULES.strikeCooldown
    local per = c.expected * melee.land
    out[#out + 1] = {
        key = "SS", name = "Stormstrike", kind = "melee", icon = rank.icon,
        dps = per / cd, mana = rank.mana / cd, usesMana = true, every = cd, gcd = true,
        lines = {
            ("%s%% weapon damage, %s%% land = %s per use"):format(f(c.pct * 100), f(melee.land * 100), f(per, 1)),
            ("Every %s sec%s"):format(f(cd), rank.cooldown and "" or " 🔶 (tooltip didn't say)"),
            { "DPS", f(per / cd, 1) },
        },
    }
end

-- Shocks share one cooldown. Flame Shock goes out once per its duration
-- (you don't reapply it early); the other shock casts are Earth Shock.
local function shockParts(q, out)
    local M = ns.SpellMath
    local es, esRank = ns.RANKS_BY_KEY.ES, best("ES", q)
    local fs, fsRank = ns.RANKS_BY_KEY.FlS, best("FlS", q)
    local cd = (esRank and esRank.cooldown) or (fsRank and fsRank.cooldown) or R.RULES.shockCooldown
    local useFS = ns.db().simUseFlameShock ~= false
    local fsEvery
    local fsc = useFS and fsRank and M.Calc(fs, fsRank, q)
    if fsc then
        fsEvery = math.max(cd, (fsRank.dmg and fsRank.dmg.dotSec) or 12)
        out[#out + 1] = {
            key = "FlS", name = "Flame Shock", kind = "spell", icon = fsRank.icon,
            dps = fsc.expected / fsEvery, mana = fsRank.mana / fsEvery, usesMana = true, every = fsEvery, gcd = true,
            sub = ("once every %s sec (hit + over time)"):format(f(fsEvery)),
            lines = {
                ("Hit + over time = %s per cast (crits and misses counted)"):format(f(fsc.expected, 1)),
                ("Cast once every %s sec, when it runs out"):format(f(fsEvery)),
                { "DPS", f(fsc.expected / fsEvery, 1) },
            },
        }
    end
    local esc = esRank and M.Calc(es, esRank, q)
    if esc then
        local rate = 1 / cd - (fsEvery and 1 / fsEvery or 0)
        if rate > 0 then
            out[#out + 1] = {
                key = "ES", name = "Earth Shock", kind = "spell", icon = esRank.icon,
                dps = esc.expected * rate, mana = esRank.mana * rate, usesMana = true, every = 1 / rate, gcd = true,
                sub = ("every %s sec (the shock cooldown%s)"):format(f(1 / rate, 1), fsEvery and " not used by Flame Shock" or ""),
                lines = {
                    ("%s per cast (crits and misses counted)"):format(f(esc.expected, 1)),
                    ("All shocks share one %s sec cooldown"):format(f(cd)),
                    { "DPS", f(esc.expected * rate, 1) },
                },
            }
        end
    end
end

-- Lightning Shield: charges go off when mobs hit you.
local function shieldPart(q, out)
    local rank = best("LS", q)
    local sh = rank and rank.shield
    if not (sh and rank.mana) then return end
    local coef, tested = testedCoef("LS", rank, "direct", ns.SpellMath.RULES.shieldCoef)
    local per = withSpellPower(sh.dmg, rank, coef, q.sp and q.sp.Nature) * spellCritMult(q)
    local every = R.RULES.shieldSecondsPerCharge
    local charges = sh.charges or 3
    local castEvery = charges * every
    out[#out + 1] = {
        key = "LS", name = "Lightning Shield", kind = "spell", icon = rank.icon,
        dps = per / every, mana = rank.mana / castEvery, usesMana = true, every = castEvery, gcd = true,
        sub = ("%d balls, recast every %s sec 🔶"):format(charges, f(castEvery)),
        lines = {
            ("One cast: %d balls × %s = %s damage for %s mana"):format(charges, f(per, 1), f(per * charges), f(rank.mana)),
            ("Spell power share per ball %s%s"):format(f(coef, 2), tested and " (your test)" or " 🔶"),
            ("🔶 We guess a mob hits you (and pops a ball) every %s sec, so you recast every %s sec."):format(f(every), f(castEvery)),
            { "DPS", f(per / every, 1) },
        },
    }
end

-- Searing Totem (left out if Flametongue Totem is your fire totem: that one
-- is already in your weapon swings).
local function totemPart(q, out)
    if ns.db().ftTotem then return end
    local rank = best("ST", q)
    local t = rank and rank.totem
    if not (t and t.min and rank.mana) then return end
    local coef, tested = testedCoef("ST", rank, "totem", ns.TotemMath and ns.TotemMath.RULES.totemCoef or 0.08)
    local interval = t.interval or (ns.TotemMath and ns.TotemMath.RULES.searingInterval) or 2.5
    local per = withSpellPower((t.min + t.max) / 2, rank, coef, q.sp and q.sp.Fire) * spellCritMult(q) * spellHitChance(q)
    local dur = t.duration or R.RULES.totemDuration
    out[#out + 1] = {
        key = "ST", name = "Searing Totem", kind = "spell", icon = rank.icon,
        dps = per / interval, mana = rank.mana / dur, usesMana = true, every = interval,
        sub = ("attacks every %s sec"):format(f(interval, 1)),
        lines = {
            ("%s per attack (spell power share %s%s)"):format(f(per, 1), f(coef, 2), tested and ", your test" or " 🔶"),
            ("Recast every %s sec for %s mana"):format(f(dur), f(rank.mana)),
            { "DPS", f(per / interval, 1) },
        },
    }
end

-- Lightning Bolt in all the time the other spells leave free.
local function boltPart(q, out)
    local spell, rank = ns.RANKS_BY_KEY.LB, best("LB", q)
    local c = rank and ns.SpellMath.Calc(spell, rank, q)
    if not c then return end
    local busy = 0
    for _, p in ipairs(out) do if p.gcd and p.every then busy = busy + gcd() / p.every end end
    local free = math.max(0, 1 - busy)
    local rate = free / c.time
    out[#out + 1] = {
        key = "LB", name = "Lightning Bolt", kind = "spell", icon = rank.icon,
        dps = c.expected * rate, mana = rank.mana * rate, usesMana = true, every = rate > 0 and 1 / rate or nil,
        sub = ("in the %s%% of time shocks leave free"):format(f(free * 100)),
        lines = {
            ("%s per cast, %s sec cast"):format(f(c.expected, 1), f(c.time, 1)),
            ("Cast in %s%% of your time"):format(f(free * 100)),
            { "DPS", f(c.expected * rate, 1) },
        },
    }
end

-- Healing Wave all the time (your highest rank).
local function healPart(q, out)
    local spell, rank = ns.RANKS_BY_KEY.HW, best("HW", q)
    local c = rank and ns.SpellMath.CalcHeal(spell, rank, q)
    if not c then return end
    out[#out + 1] = {
        key = "HW", name = "Healing Wave", kind = "heal", icon = rank.icon,
        dps = c.hps, mana = rank.mana / c.time, usesMana = true, every = c.time,
        sub = "cast over and over",
        lines = {
            ("%s healing per cast (crits counted), %s sec cast"):format(f(c.expected, 1), f(c.time, 1)),
            { "HPS", f(c.hps, 1) },
        },
    }
end

---------------------------------------------------------------------------
-- The total
---------------------------------------------------------------------------

-- q = a profile (your real one, or one with the Sim Lab changes).
-- opts.imbueKey = which weapon buff to count (nil = the best one).
-- Returns { total, parts, unit, manaNeed, manaHave, manaFactor, style }.
function R.Total(q, opts)
    opts = opts or {}
    local style = opts.style or R.Style()
    local parts = {}
    if style.id == "enh" then
        meleeParts(q, opts, parts)
        strikePart(q, parts)
        shockParts(q, parts)
        shieldPart(q, parts)
        totemPart(q, parts)
    elseif style.id == "ele" then
        shockParts(q, parts)
        shieldPart(q, parts)
        totemPart(q, parts)
        boltPart(q, parts)
    else
        healPart(q, parts)
    end

    -- Mana: can you keep this up for the whole fight? If not, every part
    -- that costs mana gets cut down to what your mana bar pays for.
    -- 🔶 Mana coming back during the fight (Spirit, Mana Spring) isn't counted.
    local fight = opts.fight or R.FightSeconds()
    local perSec = 0
    for _, p in ipairs(parts) do perSec = perSec + (p.mana or 0) end
    local res = { parts = parts, unit = style.unit, style = style, fight = fight }
    res.manaNeed = perSec * fight
    res.manaHave = q.mana or 0
    res.manaFactor = res.manaNeed > 0 and math.min(1, res.manaHave / res.manaNeed) or 1
    local total = 0
    for _, p in ipairs(parts) do
        p.fullDps = p.dps
        if p.usesMana then p.dps = p.dps * res.manaFactor end
        total = total + p.dps
    end
    res.total = total
    return res
end

---------------------------------------------------------------------------
-- Stat weights
---------------------------------------------------------------------------
-- step = how much we add to measure it (bigger steps smooth out rounding).
-- pawn = the stat name Pawn uses in its scale strings. 🔶 Taken from Pawn's
-- Classic-era scale format; not checked in Forever (we don't know if Pawn
-- even runs there yet).
R.WEIGHTS = {
    { key = "str",  label = "Strength",        step = 10, pawn = "Strength",
      icon = "Interface\\Icons\\Spell_Nature_Strength" },
    { key = "agi",  label = "Agility",         step = 10, pawn = "Agility",
      icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
    { key = "int",  label = "Intellect",       step = 10, pawn = "Intellect",
      icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { key = "sp",   label = "Spell Power",     step = 10, pawn = "SpellDamage",
      icon = "Interface\\Icons\\Spell_Nature_StarFall" },
    { key = "heal", label = "Healing",         step = 10, pawn = "Healing",
      icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
    { key = "ap",   label = "Attack Power",    step = 20, pawn = "Ap",
      icon = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    { key = "crit", label = "Crit chance (per 1%)", step = 1,  pawn = "CritRating", percent = true,
      icon = "Interface\\Icons\\Ability_CriticalStrike" },
    { key = "hit",  label = "Hit chance (per 1%)",  step = 1,  pawn = "HitRating", percent = true,
      icon = "Interface\\Icons\\Ability_Marksmanship" },
    { key = "wdps", label = "Weapon DPS",      step = 2,  pawn = "Dps",
      icon = "Interface\\Icons\\INV_Sword_04" },
    { key = "sta",  label = "Stamina",         pawn = "Stamina", estimate = true,
      icon = "Interface\\Icons\\Spell_Holy_WordFortitude" },
}

-- Adds "amount" of stat "key" to profile p (with the Sim Lab's rules).
local function plus(p, baseAdd, key, amount, opts)
    local a = {}
    for k, v in pairs(baseAdd or {}) do a[k] = v end
    a[key] = (a[key] or 0) + amount
    return (ns.SimMath.Apply(p, a, opts))
end

-- How much the total goes up for 1 point of each stat, and that number in
-- "main stat" units (Strength for melee, Spell Power for casters, Healing
-- for healers).
-- p = your real profile, add = the Sim Lab sliders (weights are measured
-- WITH your changes), opts = Sim Lab options (talents, tried weapon).
-- Returns { rows = { [key] = { gain, weight, ... } }, base, style, total }.
function R.Weights(p, add, opts)
    local style = R.Style()
    local q = ns.SimMath.Apply(p, add or {}, opts)
    local now = R.Total(q, { style = style })
    -- Keep the same weapon buff for every test, so a buff switch doesn't
    -- make one stat look huge.
    local imbueKey
    for _, part in ipairs(now.parts) do if part.imbueKey then imbueKey = part.imbueKey end end
    local topts = { style = style, imbueKey = imbueKey }
    local base = R.Total(q, topts).total

    local out = { rows = {}, style = style, total = base, now = now }
    for _, w in ipairs(R.WEIGHTS) do
        if w.step then
            local t = R.Total(plus(p, add, w.key, w.step, opts), topts)
            local gain = (t.total - base) / w.step
            -- Where the gain comes from, part by part (for the tooltip).
            local byPart = {}
            for i, part in ipairs(t.parts) do
                local before = now.parts[i] and now.parts[i].key == part.key and now.parts[i].dps or 0
                local d = (part.dps - before) / w.step
                if math.abs(d) > 1e-6 then byPart[#byPart + 1] = { name = part.name, gain = d } end
            end
            out.rows[w.key] = { def = w, gain = gain, byPart = byPart, manaFactor = t.manaFactor }
        end
    end
    -- Melee crit only and spell crit only, for the detail tooltip.
    for _, k in ipairs({ "mcrit", "scrit" }) do
        local t = R.Total(plus(p, add, k, 1, opts), topts)
        out.rows[k] = { gain = t.total - base }
    end

    local unit = out.rows[style.base] and out.rows[style.base].gain or 0
    out.unitGain = unit
    for _, r in pairs(out.rows) do
        r.weight = unit > 1e-9 and r.gain / unit or nil
    end
    -- Stamina: no damage, so our estimate (see RULES.staminaShare).
    out.rows.sta = { def = R.WEIGHTS[#R.WEIGHTS], weight = unit > 1e-9 and R.RULES.staminaShare or nil, estimate = true }
    return out
end

---------------------------------------------------------------------------
-- Copy-ready text
---------------------------------------------------------------------------

local function round2(x) return math.floor(x * 100 + 0.5) / 100 end

-- A Pawn scale string, like:
--   ( Pawn: v1: "Earthen Shrink Melee": Strength=1, Agility=0.62, ... )
-- Stats worth 0 are left out.
function R.PawnString(w)
    local parts = {}
    for _, def in ipairs(R.WEIGHTS) do
        local r = w.rows[def.key]
        local v = r and r.weight and round2(r.weight)
        if v and v > 0 then parts[#parts + 1] = ("%s=%s"):format(def.pawn, ns.fmt(v, 2)) end
    end
    return ('( Pawn: v1: "Earthen Shrink %s": %s )'):format(w.style.short, table.concat(parts, ", "))
end

-- A plain list for any other addon, or for writing down.
function R.PlainList(w)
    local parts = {}
    for _, def in ipairs(R.WEIGHTS) do
        local r = w.rows[def.key]
        if r and r.weight then parts[#parts + 1] = ("%s %s"):format(def.label, ns.fmt(round2(r.weight), 2)) end
    end
    return table.concat(parts, ", ")
end
