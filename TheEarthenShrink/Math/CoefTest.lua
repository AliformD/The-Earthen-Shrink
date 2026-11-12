-- The Earthen Shrink: spell power test math ("coefficient test")
--
-- A spell's "coefficient" is how much of your spell power it adds to each
-- hit. If Lightning Bolt has a coefficient of 0.7, then +10 spell power
-- makes every bolt hit 7 harder.
--
-- We don't trust the old Classic numbers for Forever, so this file lets you
-- MEASURE it yourself:
--   1. "Before": write down how hard the spell hits (many hits).
--   2. Put on gear with more spell power.
--   3. "After": write down how hard it hits now.
--   4. coefficient = (average after - average before) / spell power gained
--
-- The hard part is noise. Lightning Bolt hits for a random number between
-- two values (like 88 to 100), so a few hits can fool you. This file also
-- works out how sure we can be, and how many hits you'd need.
--
-- C# comparison: this is like a static class of pure functions. Nothing
-- here touches the game; it only does math on lists of numbers.

local _, ns = ...
local C = {}
ns.CoefMath = C

C.RULES = {
    minHits = 5,          -- fewer hits than this in a sample = no answer yet
    goodMargin = 0.05,    -- ± this or better = "Good"
    okMargin = 0.12,      -- ± this or better = "Okay"
    -- The game shows whole numbers. Even when a number never changes (like
    -- a Flame Shock tick) it can be up to 0.5 off from the "real" value.
    -- 0.29 is the usual size of that rounding error (1 ÷ √12).
    roundingError = 0.29,
    -- 🔶 OLD CLASSIC RULE, NOT TESTED IN FOREVER: damage over time ticks
    -- every 3 seconds. You can change the number of ticks on the tab.
    tickSeconds = 3,
}

---------------------------------------------------------------------------
-- Basic statistics
---------------------------------------------------------------------------

-- Takes a list of numbers. Returns n (how many), mean (average), sd
-- ("standard deviation" = how spread out the numbers are) and se
-- ("standard error" = how far off the average could be).
function C.Stats(values)
    local n = #values
    local out = { n = n, mean = nil, sd = 0, se = nil, low = nil, high = nil }
    if n == 0 then return out end
    local sum = 0
    for _, v in ipairs(values) do
        sum = sum + v
        if not out.low or v < out.low then out.low = v end
        if not out.high or v > out.high then out.high = v end
    end
    out.mean = sum / n
    if n > 1 then
        local sq = 0
        for _, v in ipairs(values) do sq = sq + (v - out.mean) ^ 2 end
        out.sd = math.sqrt(sq / (n - 1))
    end
    if out.sd < 0.5 then
        -- Every number (nearly) the same: more hits won't help, because the
        -- game rounds the same way every time. Only rounding is left.
        out.se = C.RULES.roundingError
        out.roundingLimited = true
    else
        out.se = out.sd / math.sqrt(n)
    end
    return out
end

---------------------------------------------------------------------------
-- The result
---------------------------------------------------------------------------

-- before / after = { sp = spell power, hits = { 91, 95, ... } }
-- ticks = for "over time" tests: ticks in one cast, so we can turn the
--         per-tick number into the whole-spell number the Sim Lab uses.
-- Returns a table with everything the tab shows.
function C.Estimate(before, after, ticks)
    local R = C.RULES
    local a, b = C.Stats(before and before.hits or {}), C.Stats(after and after.hits or {})
    local r = { before = a, after = b, ticks = ticks or 1 }
    r.dSP = (after and after.sp or 0) - (before and before.sp or 0)

    if a.n < R.minHits or b.n < R.minHits then
        r.verdict, r.why = "wait", ("Need at least %d hits in Before and in After."):format(R.minHits)
        return r
    end
    if r.dSP == 0 then
        r.verdict, r.why = "wait", "Before and After have the same spell power. Change your gear between them."
        return r
    end

    r.dMean = b.mean - a.mean
    r.coef = r.dMean / r.dSP                                      -- per hit (or per tick)
    r.se = math.sqrt(a.se ^ 2 + b.se ^ 2) / math.abs(r.dSP)
    r.margin = 2 * r.se                                           -- "± this" (about 95% sure)
    -- What the Sim Lab uses: the whole spell. For a tick, that's all ticks added up.
    r.total, r.totalMargin = r.coef * r.ticks, r.margin * r.ticks

    if r.totalMargin <= R.goodMargin then
        r.verdict = "good"
    elseif r.totalMargin <= R.okMargin then
        r.verdict = "ok"
    else
        r.verdict = "rough"
    end
    if r.coef < -r.margin then
        r.verdict, r.why = "rough", "The spell hit LESS with more spell power. A typo, a crit, or a resisted hit probably got in."
    end
    return r
end

---------------------------------------------------------------------------
-- Planning: how many hits do I need?
---------------------------------------------------------------------------

-- How spread out the hits of a spell are, from its tooltip range.
-- A random number between 88 and 100 has a spread of (100 - 88) ÷ √12.
function C.SpreadFromRange(min, max)
    if not (min and max) then return nil end
    return (max - min) / math.sqrt(12)
end

-- Hits needed in EACH sample (before and after) to get a result of ± margin.
-- From:  margin = 2 × spread × √(2 ÷ hits) ÷ spellPowerChange
-- Returns nil when more hits can't help (numbers that never change).
function C.HitsNeeded(spread, dSP, margin, ticks)
    margin = (margin or C.RULES.okMargin) / (ticks or 1)   -- per-hit margin we need
    dSP = math.abs(dSP or 0)
    if dSP == 0 then return nil end
    if not spread or spread < 0.5 then
        -- Fixed numbers: only rounding is left; more hits don't help.
        local best = 2 * math.sqrt(2) * C.RULES.roundingError / dSP
        return best <= margin and C.RULES.minHits or nil
    end
    local n = 8 * spread ^ 2 / (margin * dSP) ^ 2
    return math.max(C.RULES.minHits, math.ceil(n))
end

-- For fixed numbers (ticks), the smallest spell power change that can give
-- a ± margin answer, no matter how many ticks you write down.
function C.SpellPowerNeeded(margin, ticks)
    margin = (margin or C.RULES.okMargin) / (ticks or 1)
    return math.ceil(2 * math.sqrt(2) * C.RULES.roundingError / margin)
end

---------------------------------------------------------------------------
-- Checking a typed number (catches typos and crits)
---------------------------------------------------------------------------

-- low / high = the smallest and biggest normal hit we'd expect right now.
-- Returns ok, message.
function C.Check(value, low, high)
    if type(value) ~= "number" or value <= 0 then
        return false, "That isn't a damage number."
    end
    if high and value > high then
        return false, ("%s is too big for a normal hit (max about %s). A crit or a typo?"):format(
            ns.fmt(value), ns.fmt(high))
    end
    if low and value < low then
        return false, ("%s is too small for a normal hit (min about %s). Resisted, or a typo?"):format(
            ns.fmt(value), ns.fmt(low))
    end
    return true
end

-- Reads "88 92 95 100" (spaces or commas between)  -> { 88, 92, 95, 100 }. Anything that isn't a
-- number is returned in the second list so we can tell you about it.
function C.ParseNumbers(text)
    local nums, bad = {}, {}
    -- "1,131" is one number (one thousand one hundred ...), not two.
    text = tostring(text or ""):gsub("(%d),(%d%d%d)%f[%D]", "%1%2")
    for word in tostring(text or ""):gmatch("[^%s,;/]+") do
        local n = tonumber(word)
        if n then nums[#nums + 1] = n else bad[#bad + 1] = word end
    end
    return nums, bad
end
