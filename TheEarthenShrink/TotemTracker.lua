-- The Earthen Shrink: totem timer and log
--
-- Every time you put a totem down, this file starts its own stopwatch and
-- writes down what happened to that totem:
--   * how long it really stayed down before it ran out, was replaced by
--     another totem of the same element, was destroyed, or you died/zoned,
--   * for Mana Spring Totem: how many mana ticks you really got (so you can
--     see if you stayed in range), and if it paid back its own mana cost.
--
-- How the game tells us things (all of these exist in Forever's function
-- list, build 69893; whether they give real numbers IN COMBAT is untested):
--   1. "UNIT_SPELLCAST_SUCCEEDED": you cast a spell. If it's a totem, the
--      stopwatch starts. (The same event the Windfury sound uses.)
--   2. "PLAYER_TOTEM_UPDATE" + GetTotemInfo(slot): the game's own totem
--      timer (the little icons under your portrait). It tells us when a
--      totem appears or disappears, and how long it lasts.
--   3. "UNIT_POWER_UPDATE" + UnitPower: your mana went up. If it went up by
--      exactly the amount Mana Spring gives, we count that as one tick.
--   4. C_UnitAuras.GetAuraDataBySpellName: is there a "Mana Spring" buff on
--      you? (We don't know yet if Forever shows one. If yes, we time it.)
-- Forever can hide numbers in combat ("secret values"). When that happens
-- we just skip that piece of information instead of guessing.
--
-- C# comparison: T is like a static class. "active" is a Dictionary<string,
-- Record> from element ("Water") to the totem that is down right now.

local _, ns = ...
local T = {}
ns.TotemTracker = T

T.debug = false          -- /es totemtest switches on chat messages for every step
T.KEEP = 50              -- how many drops we remember per totem

local active = {}        -- active["Water"] = the record of the totem down right now
local slotOf = {}        -- slotOf["Water"] = 3 (learned from the game, not assumed)
local lastMana           -- your mana the last time we looked (to see how much it went up)

local function note(msg)
    if T.debug then ns.say("|cff9d9d9d[totem test]|r " .. msg) end
end

-- Saved history: db.totemLog["MST"] = { record, record, ... } newest last.
local function log(key)
    local db = ns.db()
    db.totemLog = db.totemLog or {}
    db.totemLog[key] = db.totemLog[key] or {}
    return db.totemLog[key]
end

---------------------------------------------------------------------------
-- Which totem is it?
---------------------------------------------------------------------------

-- "Mana Spring Totem III" -> the Mana Spring Totem spell from Data/Ranks.lua.
-- The game may add the rank to the name, so we check how the name STARTS.
local function totemSpellFromName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local best
    for _, s in ipairs(ns.RANKS) do
        if s.kind == "totem" and name:sub(1, #s.name) == s.name then
            if not best or #s.name > #best.name then best = s end
        end
    end
    return best
end
T.SpellFromName = totemSpellFromName

-- The rank you cast: the one with this spell ID, or else your best rank.
local function rankFor(spell, spellID)
    for _, r in ipairs(ns.SpellData.Ranks(spell.key)) do
        if spellID and r.id == spellID then return r end
    end
    return ns.SpellData.Best(spell.key, UnitLevel("player") or 1)
end

-- Your mana right now, or nil if the game hides it.
local function mana()
    return ns.clean(ns.try(UnitPower, "player", 0))
end
local function maxMana()
    return ns.clean(ns.try(UnitPowerMax, "player", 0))
end

---------------------------------------------------------------------------
-- Start and stop the stopwatch
---------------------------------------------------------------------------

-- How a drop ended, in words for the window.
T.REASONS = {
    ranout = "ran its full time",
    replaced = "replaced by another totem",
    gone = "disappeared early (killed, or you went far away)",
    recalled = "Totemic Recall",
    died = "you died",
    zoned = "you changed zone",
}

local function finish(el, reason)
    local rec = active[el]
    if not rec then return end
    active[el] = nil
    rec.lived = math.max(0, GetTime() - rec.start)
    if rec.duration and rec.lived > rec.duration then rec.lived = rec.duration end
    rec.reason = reason
    rec.start = nil   -- GetTime() means nothing after a restart, so don't save it
    rec.paidByTime = rec.payoffSec and rec.lived >= rec.payoffSec or nil
    rec.paidByTicks = rec.payoffTicks and rec.ticks >= rec.payoffTicks or nil
    local list = log(rec.key)
    list[#list + 1] = rec
    while #list > T.KEEP do table.remove(list, 1) end
    note(("%s ended: %s after %.1f sec, %d ticks, +%d mana"):format(rec.name, reason, rec.lived, rec.ticks, rec.gained))
    ns.refresh("totemlog")
end

local function start(spell, rank, how, gameStart, gameDuration)
    local el = spell.element
    local old = active[el]
    if old then finish(el, "replaced") end
    local t = rank and rank.totem or {}
    local rec = {
        key = spell.key, name = spell.name, rank = rank and rank.rank,
        start = GetTime(), when = time and time() or nil,
        gameStart = gameStart,
        -- Duration: the game's totem timer first, then the tooltip ("Lasts ...").
        duration = gameDuration or t.duration,
        durationFrom = gameDuration and "game timer" or (t.duration and "tooltip") or nil,
        cost = rank and rank.mana,
        ticks = 0, gained = 0, auraSec = 0, fullSec = 0,
        how = how,
    }
    if spell.totem == "mana" and t.mana then
        rec.perTick = t.manaIsPercent and (maxMana() or 0) * t.mana / 100 or t.mana
        rec.interval = t.interval   -- nil if the tooltip doesn't say; we don't guess here
        if rec.cost and rec.perTick and rec.perTick > 0 then
            rec.payoffTicks = math.ceil(rec.cost / rec.perTick)
            if rec.interval then rec.payoffSec = rec.payoffTicks * rec.interval end
        end
    end
    active[el] = rec
    lastMana = mana()
    note(("%s started (found by: %s). Lasts %s sec (%s)."):format(spell.name, how,
        tostring(rec.duration or "?"), rec.durationFrom or "unknown"))
    T.EnsureTicker()
    ns.refresh("totemlog")
    return rec
end

---------------------------------------------------------------------------
-- 1. You cast a spell
---------------------------------------------------------------------------

ns.on("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
    if unit ~= "player" then return end
    local id = ns.clean(spellID)
    if not id then return end
    local name = ns.clean(ns.try(C_Spell and C_Spell.GetSpellName, id))
    if not name then return end
    if name == "Totemic Recall" then
        for el in pairs(active) do finish(el, "recalled") end
        return
    end
    local spell = totemSpellFromName(name)
    if not spell then return end
    -- The game's totem timer may have told us a moment before the cast did.
    local rec = active[spell.element]
    if rec and rec.key == spell.key and rec.how == "totem timer" and GetTime() - rec.start < 1 then
        rec.how = "totem timer + your cast"
        return
    end
    start(spell, rankFor(spell, id), "your cast")
end)

---------------------------------------------------------------------------
-- 2. The game's own totem timer
---------------------------------------------------------------------------

-- Reads one totem slot. Returns nil if the game hides it (secret value).
local function readSlot(slot)
    local have, name, startTime, duration = ns.try(GetTotemInfo, slot)
    have, name = ns.clean(have), ns.clean(name)
    startTime, duration = ns.clean(startTime), ns.clean(duration)
    if have == nil and name == nil then return nil end
    return { have = have and name ~= nil and name ~= "", name = name, start = startTime, duration = duration }
end

ns.on("PLAYER_TOTEM_UPDATE", function(slot)
    slot = ns.clean(slot)
    if type(slot) ~= "number" then return end
    local info = readSlot(slot)
    if not info then note("totem slot " .. slot .. " changed, but the game hid the details.") return end
    note(("totem slot %d: %s"):format(slot, info.have and (tostring(info.name) .. ", " .. tostring(info.duration) .. " sec") or "empty"))

    if info.have then
        local spell = totemSpellFromName(info.name)
        if not spell then return end
        slotOf[spell.element] = slot
        local rec = active[spell.element]
        local dur = (type(info.duration) == "number" and info.duration > 0) and info.duration or nil
        if rec and rec.key == spell.key and (not rec.gameStart or not info.start or math.abs(rec.gameStart - info.start) < 0.5) then
            -- Same totem we already started from your cast: take the game's numbers.
            rec.gameStart = info.start
            if dur then rec.duration, rec.durationFrom = dur, "game timer" end
            return
        end
        -- A totem we didn't see you cast (or a new one on top of the old one).
        start(spell, rankFor(spell), "totem timer", info.start, dur)
    else
        -- The slot is empty now: whatever was there is gone.
        for el, s in pairs(slotOf) do
            if s == slot and active[el] then
                local rec = active[el]
                local age = GetTime() - rec.start
                if age < 0.3 then return end   -- the old totem leaving as the new one lands
                finish(el, (rec.duration and age >= rec.duration - 1) and "ranout" or "gone")
            end
        end
    end
end)

ns.on("PLAYER_DEAD", function() for el in pairs(active) do finish(el, "died") end end)
ns.on("PLAYER_ENTERING_WORLD", function() for el in pairs(active) do finish(el, "zoned") end end)

---------------------------------------------------------------------------
-- 3. Mana ticks
---------------------------------------------------------------------------

local function onPower(unit, powerType)
    if unit ~= "player" then return end
    if powerType and ns.clean(powerType) and ns.clean(powerType) ~= "MANA" then return end
    local now = mana()
    if not now then lastMana = nil return end
    local before = lastMana
    lastMana = now
    if not before then return end
    local up = now - before
    if up <= 0 then return end
    for _, rec in pairs(active) do
        if rec.perTick and rec.perTick > 0 then
            -- "Exactly the Mana Spring amount" (a little slack for rounding,
            -- or for the last tick topping you up to full mana).
            local full = maxMana()
            local exact = math.abs(up - rec.perTick) <= math.max(1, rec.perTick * 0.05)
            local toppedUp = full and now >= full and up < rec.perTick
            if exact or toppedUp then
                rec.ticks = rec.ticks + 1
                rec.gained = rec.gained + up
                note(("%s tick %d: +%d mana"):format(rec.name, rec.ticks, up))
            end
        end
    end
end
ns.on("UNIT_POWER_UPDATE", onPower)
ns.on("UNIT_POWER_FREQUENT", onPower)

---------------------------------------------------------------------------
-- Stopwatch: runs only while a totem is down. Ends totems that ran out,
-- checks for the Mana Spring buff, and moves the bars in the window.
---------------------------------------------------------------------------

local ticker = CreateFrame("Frame")
T.ticker = ticker   -- so the test file can run it by hand
local acc, step = 0, 0.1
local function onUpdate(_, elapsed)
    acc = acc + (elapsed or step)
    if acc < step then return end
    local dt = acc
    acc = 0
    local now = GetTime()
    local any = false
    local full = maxMana()
    local cur = mana()
    for el, rec in pairs(active) do
        any = true
        local age = now - rec.start
        if rec.perTick then
            -- 4. Is there a "Mana Spring" buff on you? (We only count it if the game shows one.)
            local aura = C_UnitAuras and ns.try(C_UnitAuras.GetAuraDataBySpellName, "player", "Mana Spring", "HELPFUL")
            if aura then rec.auraSec = rec.auraSec + dt; rec.auraSeen = true end
            if full and cur and cur >= full then rec.fullSec = rec.fullSec + dt end
        end
        if rec.duration and age >= rec.duration + 0.5 then
            finish(el, "ranout")
        elseif not rec.duration and age > 600 then
            finish(el, "gone")   -- safety: never keep one forever
        end
    end
    if T.onTick then pcall(T.onTick) end
    if not any then ticker:SetScript("OnUpdate", nil) end
end

function T.EnsureTicker()
    ticker:SetScript("OnUpdate", onUpdate)
end

---------------------------------------------------------------------------
-- For the window
---------------------------------------------------------------------------

-- The totem down right now for an element, with time used and time left.
function T.Active(el)
    local rec = active[el]
    if not rec then return nil end
    local age = GetTime() - rec.start
    return rec, age, rec.duration and math.max(0, rec.duration - age) or nil
end

-- Averages over the saved drops of one totem (nil if none yet).
function T.Summary(key)
    local list = log(key)
    if #list == 0 then return nil end
    local s = { n = #list, lived = 0, full = 0, paidTime = 0, paidTicks = 0, withPayoff = 0,
                ticks = 0, gained = 0, spent = 0, tickDrops = 0, reasons = {}, list = list }
    for _, r in ipairs(list) do
        s.lived = s.lived + (r.lived or 0)
        if r.reason == "ranout" then s.full = s.full + 1 end
        s.reasons[r.reason or "?"] = (s.reasons[r.reason or "?"] or 0) + 1
        if r.payoffTicks then
            s.withPayoff = s.withPayoff + 1
            if r.paidByTime then s.paidTime = s.paidTime + 1 end
            if r.paidByTicks then s.paidTicks = s.paidTicks + 1 end
            s.ticks = s.ticks + (r.ticks or 0)
            s.gained = s.gained + (r.gained or 0)
            s.spent = s.spent + (r.cost or 0)
            if (r.ticks or 0) > 0 then s.tickDrops = s.tickDrops + 1 end
        end
        s.duration = r.duration or s.duration
        s.payoffSec, s.payoffTicks, s.perTick, s.interval, s.cost =
            r.payoffSec or s.payoffSec, r.payoffTicks or s.payoffTicks, r.perTick or s.perTick, r.interval or s.interval, r.cost or s.cost
    end
    s.avgLived = s.lived / s.n
    -- If we never saw a single tick, tick counting probably doesn't work
    -- (hidden mana, always full mana, or ticks merged with normal regen).
    s.ticksWork = s.tickDrops > 0
    return s
end

local function pct(a, b) return b > 0 and math.floor(a / b * 100 + 0.5) or 0 end

-- One short line for the window, like:
-- "12 drops: up 17.3 sec on average (of 22) · paid off 7 of 12 (58%) · +412 mana back for 360 spent"
function T.ShortLine(key)
    local s = T.Summary(key)
    if not s then return nil end
    local f = ns.fmt
    local out = ("%d drop%s: up %s sec on average"):format(s.n, s.n == 1 and "" or "s", f(s.avgLived, 1))
    if s.duration then out = out .. " (of " .. f(s.duration) .. ")" end
    if s.withPayoff > 0 then
        local paid = s.ticksWork and s.paidTicks or s.paidTime
        out = out .. (" · paid off %d of %d (%d%%)"):format(paid, s.withPayoff, pct(paid, s.withPayoff))
        if s.ticksWork then out = out .. (" · +%s mana back for %s spent"):format(f(s.gained), f(s.spent)) end
    else
        out = out .. (" · ran full time %d of %d (%d%%)"):format(s.full, s.n, pct(s.full, s.n))
    end
    return out
end

-- Lines for a tooltip (W.AddMath style: strings, or { left, right } pairs).
function T.TooltipLines(key)
    local s = T.Summary(key)
    if not s then return { "No drops logged yet. Put this totem down and the addon starts its own timer." } end
    local f = ns.fmt
    local L = {}
    L[#L + 1] = { "Drops logged", tostring(s.n) .. (s.n >= T.KEEP and (" (last " .. T.KEEP .. ")") or "") }
    L[#L + 1] = { "Average time it stayed down", f(s.avgLived, 1) .. " sec" .. (s.duration and (" of " .. f(s.duration)) or "") }
    L[#L + 1] = { "Ran its full time", ("%d of %d (%d%%)"):format(s.full, s.n, pct(s.full, s.n)) }
    if s.withPayoff > 0 then
        L[#L + 1] = " "
        L[#L + 1] = { "Mana cost", f(s.cost) }
        L[#L + 1] = { "Mana per tick", f(s.perTick, 1) .. (s.interval and (" every " .. f(s.interval, 1) .. " sec") or " (tooltip didn't say how often)") }
        L[#L + 1] = { "Pays off after", ("%d ticks%s"):format(s.payoffTicks, s.payoffSec and (" = " .. f(s.payoffSec, 1) .. " sec") or "") }
        L[#L + 1] = { "Stayed down long enough", ("%d of %d (%d%%)"):format(s.paidTime, s.withPayoff, pct(s.paidTime, s.withPayoff)) }
        if s.ticksWork then
            L[#L + 1] = { "You really got enough ticks", ("%d of %d (%d%%)"):format(s.paidTicks, s.withPayoff, pct(s.paidTicks, s.withPayoff)) }
            L[#L + 1] = { "Mana back / mana spent", f(s.gained) .. " / " .. f(s.spent) }
            L[#L + 1] = "Fewer ticks than time means you walked out of range, or you were at full mana (a tick on full mana gives nothing and can't be seen)."
        else
            L[#L + 1] = "|cffff8000No mana ticks seen yet.|r Either you were at full mana, the game hid your mana in combat, or tick counting doesn't work in Forever. Type /es totemtest to check."
        end
    end
    L[#L + 1] = " "
    L[#L + 1] = "Last drops (newest first):"
    for i = #s.list, math.max(1, #s.list - 7), -1 do
        local r = s.list[i]
        local right = f(r.lived or 0, 1) .. " sec"
        if r.payoffTicks then
            right = right .. (" · %d ticks"):format(r.ticks or 0)
            local paid = (s.ticksWork and r.paidByTicks) or (not s.ticksWork and r.paidByTime)
            right = right .. (paid and " |cff1eff00paid|r" or " |cffff4a3anot paid|r")
        end
        L[#L + 1] = { T.REASONS[r.reason] or tostring(r.reason), right }
    end
    return L
end

function T.Clear(key)
    local db = ns.db()
    if key then (db.totemLog or {})[key] = nil else db.totemLog = {} end
    ns.refresh("totemlog")
end

function T.Slash(arg)
    if arg == "clear" then
        T.Clear()
        ns.say("totem log cleared.")
        return
    end
    T.debug = not T.debug
    ns.say("totem test mode " .. (T.debug and "|cff1eff00on|r. Drop a totem and watch the chat. Type /es totemtest again to stop." or "|cffff4a3aoff|r."))
    if T.debug then
        ns.say("  totem timer (GetTotemInfo): " .. (type(GetTotemInfo) == "function" and "found" or "|cffff4a3amissing|r")
            .. ", buff check: " .. ((C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) and "found" or "|cffff4a3amissing|r")
            .. ", mana now: " .. tostring(mana() or "hidden"))
    end
end
