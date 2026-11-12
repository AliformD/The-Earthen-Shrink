-- The Earthen Shrink: weapon buff (imbue) math
--
-- How it works (Angel's idea): pretend you swing your main-hand weapon 50
-- times with your real attack power, weapon and crit. Work out the damage
-- with no weapon buff, then with each buff, and see which adds the most.
--
-- We use the AVERAGE of those 50 swings (for example: 20% Windfury chance on
-- 50 swings = 10 procs). A random roll would give a different answer every
-- time you open the window, so the average is fairer for comparing.
--
-- The buff numbers (attack power, fire damage, proc chance) come from the
-- game's own tooltip. Rules marked 🔶 are old Classic rules, not yet
-- tested in Forever.

local _, ns = ...
local M = {}
ns.ImbueMath = M

M.RULES = {
    apPerDps = 14,          -- 🔶 14 attack power = +1 weapon DPS
    -- Miss, dodge and hit cap rules live in Math/HitCrit.lua now.
    meleeCritBonus = 1.0,   -- 🔶 a melee crit does +100% damage
    spellCritBonus = 0.5,   -- 🔶 a fire/frost crit does +50% damage
    ftRefSpeed = 4.0,       -- 🔶 Flametongue tooltip max = a 4.0 speed weapon
    fbPPM = 9,              -- 🔶 Frostbrand procs about 9 times a minute (if its tooltip has no %)
    fbCoef = 0,             -- 🔶 share of Frost spell power Frostbrand adds (unknown, so 0)
}

M.ORDER = { "RB", "FT", "FB", "WF" }
M.SHORT = { RB = "Rockbiter", FT = "Flametongue", FB = "Frostbrand", WF = "Windfury" }

local function db() return ns.db() end

local function landChance(p) return ns.HitCrit.LandChance(p) end

-- The numbers for one rank: from the tooltip, or the built-in list if the
-- tooltip couldn't be read. Returns data, fromFallback.
local function imbueData(key, rank)
    if not rank then return nil end
    if rank.imbue then return rank.imbue, false end
    local fb = ns.IMBUE_FALLBACK and ns.IMBUE_FALLBACK[key] and ns.IMBUE_FALLBACK[key][rank.rank]
    if fb and rank.talent and rank.talent.power ~= 1 then
        -- Built-in numbers were seen on Angel's tooltip, so they get the
        -- same talent change as a tooltip would.
        local c = {}
        for k, v in pairs(fb) do c[k] = v end
        for _, k in ipairs({ "ap", "min", "max" }) do if c[k] then c[k] = c[k] * rank.talent.power end end
        return c, true
    end
    if fb then return fb, true end
    return nil
end

-- Windfury Totem in your group: its proc numbers, or nil + why not.
function M.TotemProc(p)
    if not db().wfTotem then return nil, "off" end
    local rank = ns.SpellData.Best("WFT", p.level or 1, p)
    if not rank then return nil, "Windfury Totem isn't available at this level" end
    if not rank.imbue then return nil, "couldn't read the Windfury Totem tooltip" end
    return { chance = rank.imbue.chance, attacks = rank.imbue.attacks, ap = rank.imbue.ap, name = "Windfury Totem", rank = rank }
end

-- Flametongue: fire damage on each hit for one rank (weapon "FT" or totem
-- "FTT"). Takes the spell power already in the tooltip out, then adds
-- spell power back with your SP Test result (or the setting for the weapon).
-- Returns perHit (before crits), coef, tested, lines.
function M.FlametonguePerHit(key, im, p)
    local R, set, w, f = M.RULES, db(), p.weapon, ns.fmt
    -- 🔶 The tooltip shows a range for fast to slow weapons. We scale the
    -- top number by your weapon speed.
    local perHit = im.min == im.max and im.max or im.max * w.speed / R.ftRefSpeed
    local best = ns.SpellData.Best(key, p.level or 1)
    local tested = best and ns.CoefTest and ns.CoefTest.Saved(key, best.rank).proc
    local coef = tested and tested.coef or (key == "FT" and set.ftCoef) or 0
    local sp = p.sp and p.sp.Fire or 0
    local inTip = (set.tooltipIncludesSpellPower and best and best.spRead or 0) * coef
    local base = math.max(0, perHit - inTip)
    local L = {}
    L[#L + 1] = { "Fire damage (tooltip)", f(im.min, 1) .. " to " .. f(im.max, 1) }
    if im.min ~= im.max then
        L[#L + 1] = ("%s × %s speed ÷ %s = %s fire per hit"):format(f(im.max, 1), f(w.speed, 2), f(R.ftRefSpeed, 1), f(perHit, 1))
    end
    L[#L + 1] = { "Spell power bonus " .. (tested and "|cff1eff00(your SP Test)|r" or "|cffff8000(unverified)|r"),
        ("%s × %s%% = +%s"):format(f(sp), f(coef * 100, 1), f(sp * coef, 1)) }
    return base + sp * coef, coef, tested, L
end

-- Flametongue Totem in your group: fire per hit, or nil + why not.
function M.FtTotem(p)
    if not db().ftTotem then return nil, "off" end
    local rank = ns.SpellData.Best("FTT", p.level or 1, p)
    if not rank then return nil, "Flametongue Totem isn't available at this level" end
    if not (rank.imbue and rank.imbue.min) then return nil, "couldn't read the Flametongue Totem tooltip" end
    if not (p.weapon and p.weapon.speed) then return nil, "no weapon found" end
    local per, coef, tested, lines = M.FlametonguePerHit("FTT", rank.imbue, p)
    return { perHit = per, rank = rank, coef = coef, tested = tested, lines = lines }
end

---------------------------------------------------------------------------
-- One swing
---------------------------------------------------------------------------

-- Expected damage of ONE main-hand swing (including any extra attacks it
-- gives you), with a buff described as:
--   buff.ap     extra attack power (Rockbiter)
--   buff.onHit  extra damage on every hit that lands (Flametongue, Frostbrand)
--   buff.procs  list of { chance = %, attacks = n, ap = bonus AP } (Windfury)
function M.Swing(p, ctx, buff)
    local R, w = M.RULES, p.weapon
    local avgW = (w.min + w.max) / 2
    local land, crit = ctx.land, ctx.crit

    -- One hit, on average (counts misses and crits).
    local function hit(extraAP)
        local ap = ctx.ap + (buff.ap or 0) + (extraAP or 0)
        return land * ((avgW + ap / R.apPerDps * w.speed) * crit + (buff.onHit or 0))
    end

    local normal = hit(0)
    local extra = 0
    for _, pr in ipairs(buff.procs or {}) do
        -- 🔶 Only a hit that lands can proc. Extra attacks can't proc again.
        extra = extra + land * (pr.chance / 100) * pr.attacks * hit(pr.ap)
    end
    return normal + extra, normal, extra
end

-- "In 50 swings you'll usually get between 6 and 14 procs."
local function luckRange(swings, land, chance)
    local n, c = swings * land, chance / 100
    local mean, sd = n * c, math.sqrt(n * c * (1 - c))
    return math.max(0, math.floor(mean - 1.645 * sd)), math.ceil(mean + 1.645 * sd), mean
end

---------------------------------------------------------------------------
-- Compare all buffs
---------------------------------------------------------------------------

-- Returns a list of { key, name, rank, calc, reason }, best first.
-- calc = { dps, perSwing, total, lines, short, fromFallback }
function M.Compare(p)
    local R, f, set = M.RULES, ns.fmt, db()
    local w = p.weapon
    local list = {}
    local swings = set.swings or 50
    local haveWeapon = w and w.min and w.speed

    local ctx
    if haveWeapon then
        ctx = { land = landChance(p), crit = 1 + (p.meleeCrit or 0) / 100 * R.meleeCritBonus, ap = p.ap or 0 }
        ctx.fireCrit = 1 + (p.spellCrit or 0) / 100 * R.spellCritBonus
        ctx.seconds = swings * w.speed
        -- Rockbiter already on the weapon? Its attack power is inside your
        -- stats, so take it out or every buff would get it for free.
        -- We take out YOUR tooltip number (no profile given), because that's
        -- what the game added to your attack power. An inspected player's
        -- attack power is worked out from gear, so it has no Rockbiter in it.
        if p.imbueNow == "RB" and p.source ~= "inspect" then
            local rb = imbueData("RB", ns.SpellData.Best("RB", p.level or 1))
            if rb and rb.ap then ctx.ap = math.max(0, ctx.ap - rb.ap); ctx.removedRB = rb.ap end
        end
        ctx.totem, ctx.totemWhy = M.TotemProc(p)
        ctx.ftTotem, ctx.ftTotemWhy = M.FtTotem(p)
        ctx.ftTotemHit = ctx.ftTotem and ctx.ftTotem.perHit * ctx.fireCrit or 0
        local none = { procs = {}, onHit = ctx.ftTotemHit }
        if ctx.totem then none.procs[1] = ctx.totem end
        ctx.base = M.Swing(p, ctx, none)
    end
    M.lastCtx = ctx

    for _, key in ipairs(M.ORDER) do
        local spell = ns.RANKS_BY_KEY[key]
        -- With p's talents, not just yours (see Math/TalentMods.lua).
        local rank = ns.SpellData.Best(key, p.level or 1, p)
        local e = { key = key, name = spell.name, rank = rank }
        local data, fromFallback = imbueData(key, rank)
        if not rank then
            e.reason = "not learned at this level"
        elseif not data then
            e.reason = "couldn't read the numbers in its tooltip"
        elseif not haveWeapon then
            e.reason = "no weapon found"
        else
            e.calc = M.CalcOne(key, data, p, ctx)
            e.calc.fromFallback = fromFallback
            if rank.talent and #rank.talent.lines > 0 then
                if math.abs(rank.talent.power - 1) > 1e-9 then
                    for _, l in ipairs(e.calc.lines) do
                        if type(l) == "table" and type(l[1]) == "string" then l[1] = l[1]:gsub("%(tooltip%)", "(after talents)") end
                    end
                end
                for i, l in ipairs(rank.talent.lines) do table.insert(e.calc.lines, i, l) end
                e.calc.talent = rank.talent
            end
        end
        list[#list + 1] = e
    end
    table.sort(list, function(a, b)
        local da, db_ = a.calc and a.calc.dps or -1, b.calc and b.calc.dps or -1
        return da > db_
    end)
    return list
end

-- Builds the buff, runs the swing math and writes the explanation lines.
function M.CalcOne(key, im, p, ctx)
    local R, f, set, w = M.RULES, ns.fmt, db(), p.weapon
    local swings = set.swings or 50
    local buff = { procs = {} }
    local L = {}
    local short

    if key == "RB" then
        buff.ap = im.ap
        L[#L + 1] = { "Attack power (tooltip)", "+" .. f(im.ap) }
        short = ("+%sAP"):format(f(im.ap))

    elseif key == "FT" then
        local perHit, coef, tested, lines = M.FlametonguePerHit("FT", im, p)
        buff.onHit = perHit * ctx.fireCrit
        for _, l in ipairs(lines) do L[#L + 1] = l end
        if im.sp then L[#L + 1] = { "Also gives spell power (spells only)", "+" .. f(im.sp) } end
        short = ("%.1f fire/hit"):format(perHit)

    elseif key == "FB" then
        local chance = im.chance or (R.fbPPM * w.speed / 60 * 100)
        local per = (im.min + im.max) / 2 + (p.sp and p.sp.Frost or 0) * R.fbCoef
        buff.onHit = chance / 100 * per * ctx.fireCrit
        L[#L + 1] = { "Frost damage (tooltip)", f(im.min, 1) .. (im.min ~= im.max and (" to " .. f(im.max, 1)) or "") }
        L[#L + 1] = { "Proc chance" .. (im.chance and " (tooltip)" or " |cffff8000(guess)|r"), f(chance, 1) .. "%" }
        short = ("%.0f%% x %.0f frost"):format(chance, per)
    end

    if key == "WF" then
        buff.procs[#buff.procs + 1] = { chance = im.chance, attacks = im.attacks, ap = im.ap }
        L[#L + 1] = { "Proc chance (tooltip)", f(im.chance) .. "%" }
        L[#L + 1] = { "Extra attacks", f(im.attacks) .. (im.attacksGuessed and " (guess)" or "") }
        L[#L + 1] = { "Bonus AP on extra attacks", "+" .. f(im.ap) }
        short = ("%d%% x%d +%dAP"):format(im.chance, im.attacks, im.ap)
    end

    -- Flametongue Totem: adds its fire to every buff, except maybe
    -- Flametongue Weapon (🔶 unverified whether the two stack).
    if ctx.ftTotem then
        if key ~= "FT" or set.ftStacks then
            buff.onHit = (buff.onHit or 0) + ctx.ftTotemHit
            if key == "FT" then L[#L + 1] = { "Flametongue Totem", "stacks (setting) +" .. f(ctx.ftTotem.perHit, 1) .. " fire" } end
        else
            L[#L + 1] = { "Flametongue Totem", "|cffff4a3areplaced by the weapon buff (setting)|r" }
        end
    end

    -- Windfury Totem: works with every buff except (maybe) Windfury Weapon.
    if ctx.totem then
        if key ~= "WF" or set.wfStacks then
            buff.procs[#buff.procs + 1] = ctx.totem
            if key == "WF" then L[#L + 1] = { "Windfury Totem", "stacks (setting)" } end
        else
            L[#L + 1] = { "Windfury Totem", "|cffff4a3aturned off by this buff|r" }
        end
    end

    local per = M.Swing(p, ctx, buff)
    local c = { lines = L }
    c.perSwing = per - ctx.base
    c.total = c.perSwing * swings
    c.dps = c.perSwing / w.speed
    c.short = short

    L[#L + 1] = ("%d swings (%s sec): no buff %s dmg, with %s %s dmg"):format(
        swings, f(ctx.seconds), f(ctx.base * swings), M.SHORT[key], f(per * swings))
    L[#L + 1] = { "Extra damage over " .. swings .. " swings", "+" .. f(c.total) }
    L[#L + 1] = { "Extra per swing", "+" .. f(c.perSwing, 1) }
    if key == "WF" then
        local lo, hi, mean = luckRange(swings, ctx.land, im.chance)
        L[#L + 1] = ("Average %s procs in %d swings. Real fights: usually %d to %d, so luck matters."):format(
            f(mean, 1), swings, lo, hi)
    end
    return c
end

---------------------------------------------------------------------------
-- Settings: /es wftotem, /es wfstack, /es ftcoef, /es swings
---------------------------------------------------------------------------

M.FT_COEF_STEPS = { 0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4 }

function M.CycleFtCoef()
    local set, steps = db(), M.FT_COEF_STEPS
    local now = set.ftCoef or 0
    for i, v in ipairs(steps) do
        if v > now + 0.0001 then set.ftCoef = v; ns.refresh("settings"); return end
    end
    set.ftCoef = steps[1]
    ns.refresh("settings")
end

local function onOff(arg, current)
    if arg == "on" or arg == "yes" then return true end
    if arg == "off" or arg == "no" then return false end
    return not current
end

function M.Slash(msg)
    local set = db()
    local cmd, arg = msg:match("^(%a+)%s*(.-)$")
    if cmd == "wftotem" then
        set.wfTotem = onOff(arg, set.wfTotem)
        ns.say("Windfury Totem in your group: " .. (set.wfTotem and "|cff1eff00on|r" or "|cffff4a3aoff|r"))
    elseif cmd == "wfstack" then
        set.wfStacks = onOff(arg, set.wfStacks)
        ns.say("Windfury Totem stacks with Windfury Weapon: " .. (set.wfStacks and "|cff1eff00yes|r" or "|cffff4a3ano|r"))
    elseif cmd == "fttotem" then
        set.ftTotem = onOff(arg, set.ftTotem)
        ns.say("Flametongue Totem in your group: " .. (set.ftTotem and "|cff1eff00on|r" or "|cffff4a3aoff|r"))
    elseif cmd == "ftstack" then
        set.ftStacks = onOff(arg, set.ftStacks)
        ns.say("Flametongue Totem stacks with Flametongue Weapon: " .. (set.ftStacks and "|cff1eff00yes|r" or "|cffff4a3ano|r") .. " (unverified)")
    elseif cmd == "ftcoef" then
        local v = tonumber(arg)
        if v and v >= 0 and v <= 2 then set.ftCoef = v end
        ns.say(("Flametongue spell power bonus: %s%% of Fire spell power (unverified). Example: /es ftcoef 0.1 = 10%%."):format(ns.fmt((set.ftCoef or 0) * 100, 1)))
    elseif cmd == "swings" then
        local v = tonumber(arg)
        if v and v >= 10 and v <= 1000 then set.swings = math.floor(v) end
        ns.say("swings simulated: " .. (set.swings or 50))
    end
    ns.refresh("settings")
end
