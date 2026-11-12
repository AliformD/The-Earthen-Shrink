-- The Earthen Shrink: talents that change your spell tooltips
--
-- The problem (Angel found it while inspecting someone, 2026-11-12):
-- the game writes YOUR talents into YOUR spell tooltips. With Elemental
-- Weapons, your Rockbiter tooltip already shows the bigger number. The addon
-- reads tooltips, so without this file it gave that bigger number to every
-- player you inspect, even a low level Shaman who doesn't have the talent.
--
-- The fix, in three steps:
--   1. Read every talent's own text (from the game) and find the ones that
--      say "makes <a spell we use> X% stronger" or "X% cheaper".
--   2. Take YOUR talents out of the tooltip number: 29 ÷ 1.14 = 25.4.
--      That's the number with no talents at all.
--   3. Put the talents of the character we're working out back in:
--        you            -> your real talents (so nothing changes for you)
--        Sim Lab "Try"  -> the talents you ticked on the left
--        inspected      -> their talents, if the game lets us read them;
--                          otherwise "unknown, counted as none" (shown)
--
-- C# picture: think of it as  value / myMultiplier * theirMultiplier.
--
-- 🔶 Unverified, to check in game:
--   * that a talent's text shows the total for the points you have (so
--     "14%" with 2 points = 7% per point). With 0 points we assume the text
--     shows 1 point.
--   * that two talents on the same spell add up (+14% and +10% = +24%).
--   * spell power inside a tooltip is multiplied by the talent too. We
--     divide the whole number, which is right if the talent works that way.

local _, ns = ...
local TM = {}
ns.TalentMods = TM

-- Words in talent text -> the addon's spell keys. Longer names first, so
-- "Flametongue Totem" isn't also read as "Flametongue" (Weapon).
TM.NAMES = {
    { "lesser healing wave", { "LHW" } },
    { "healing stream totem", { "HST" } },
    { "mana spring totem", { "MST" } },
    { "flametongue totem", { "FTT" } },
    { "windfury totem", { "WFT" } },
    { "searing totem", { "ST" } },
    { "magma totem", { "MT" } },
    { "lightning shield", { "LS" } },
    { "chain lightning", { "CL" } },
    { "lightning bolt", { "LB" } },
    { "healing wave", { "HW" } },
    { "earth shock", { "ES" } },
    { "flame shock", { "FlS" } },
    { "frost shock", { "FrS" } },
    { "chain heal", { "CH" } },
    { "fire nova", { "FN" } },
    { "stormstrike", { "SS" } },
    { "searing", { "ST" } },        -- "your Searing and Magma Totems"
    { "magma", { "MT" } },
    { "rockbiter", { "RB" } },
    { "flametongue", { "FT" } },
    { "frostbrand", { "FB" } },
    { "windfury", { "WF" } },
    { "weapon imbue", { "RB", "FT", "FB", "WF" } },
    { "weapon enchant", { "RB", "FT", "FB", "WF" } },
    { "shock", { "ES", "FlS", "FrS" } },
}

-- Words that mean the % is NOT about damage, attack power or mana cost
-- (so we leave it alone): crit chance, cooldowns, threat and so on.
local IGNORE = { "cooldown", "cast time", "duration", "threat", "range", "radius", "critical",
                 "chance", "parry", "dodge", "resist", "pushback", "interrupt", "slow" }
local POWER = { "damage", "attack power", "effect", "bonus", "heal", "increas", "improv" }

local function hasAny(s, words)
    for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end
    return false
end

local function cleanText(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    return s
end

-- Reads one talent's text. Returns a list of
--   { key = "RB", kind = "power" or "cost", pct = 14 }
-- and a list of spell keys it mentions without a % we could read.
function TM.ParseText(text)
    text = cleanText(text)
    local found, unread = {}, {}
    if not text then return found, unread end
    local lower = text:lower()
    for sentence in (lower .. ". "):gmatch("(.-)%.%s") do
        -- Find every spell name, longest first. Each found name is blanked
        -- out so a shorter name can't match the same words again.
        local work, hits = sentence, {}
        for _, pair in ipairs(TM.NAMES) do
            local start = 1
            while true do
                local a, b = work:find(pair[1], start, true)
                if not a then break end
                hits[#hits + 1] = { pos = a, stop = b, keys = pair[2] }
                work = work:sub(1, a - 1) .. ("#"):rep(b - a + 1) .. work:sub(b + 1)
                start = b + 1
            end
        end
        table.sort(hits, function(x, y) return x.pos < y.pos end)
        local segStart = 1
        for i, h in ipairs(hits) do
            -- The first "N%" after the name is its number ("... Rockbiter
            -- Weapon by 7%, your Flametongue Weapon by 5%").
            local pa, pb, num = sentence:find("(%d+%.?%d*)%%", h.stop + 1)
            if not pa then
                for _, k in ipairs(h.keys) do unread[#unread + 1] = k end
            else
                -- The words that describe this number: from the end of the
                -- last number to the end of this one.
                local seg = sentence:sub(segStart, pb)
                -- "Rockbiter and Flametongue by 10%": both names share the
                -- number, so the next name keeps the same words.
                local nextHit = hits[i + 1]
                if not nextHit or nextHit.pos > pb then segStart = pb + 1 end
                local kind
                if seg:find("cost", 1, true) then
                    kind = "cost"
                elseif not hasAny(seg, IGNORE) and hasAny(sentence, POWER) then
                    kind = "power"
                end
                if kind then
                    local pct = tonumber(num)
                    if kind == "power" and (seg:find("reduc", 1, true) or seg:find("decreas", 1, true)) then pct = -pct end
                    for _, k in ipairs(h.keys) do found[#found + 1] = { key = k, kind = kind, pct = pct } end
                end
            end
        end
    end
    return found, unread
end

---------------------------------------------------------------------------
-- Your talents (read once, again when talents or spells change)
---------------------------------------------------------------------------

TM.cache = nil

local function scan()
    local c = { mods = {}, unread = {}, real = nil }
    local TL = ns.Talents
    local list = TL and TL.List and TL.List("player")
    if not list then c.cantRead = true; return c end
    c.real = {}
    for _, t in ipairs(list) do
        c.real[t.name] = (c.real[t.name] or 0) + (t.rank or 0)
        local text = TL.Description(t.name)
        if text then
            local found, unread = TM.ParseText(text)
            -- 🔶 The text shows the total for the points you have (1 if none).
            local textPoints = math.max(1, t.rank or 0)
            for _, m in ipairs(found) do
                c.mods[m.key] = c.mods[m.key] or {}
                table.insert(c.mods[m.key], { talent = t.name, kind = m.kind, perPoint = m.pct / textPoints,
                    textPct = m.pct, textPoints = textPoints, max = t.max, text = text })
            end
            for _, k in ipairs(unread) do
                c.unread[k] = c.unread[k] or {}
                c.unread[k][t.name] = text
            end
        end
    end
    return c
end

function TM.Data()
    if not TM.cache then TM.cache = scan() end
    return TM.cache
end

function TM.Reset() TM.cache = nil end

-- Your real points: { [talent name] = points }, or nil if unreadable.
function TM.RealPoints()
    return TM.Data().real
end

-- Talents that change one spell: list of { talent, kind, perPoint, ... }.
function TM.ModsFor(key)
    return TM.Data().mods[key] or {}
end

-- Every talent the addon found that changes a spell or buff it uses.
-- Returns a sorted list of names.
function TM.TalentNames()
    local seen, out = {}, {}
    for _, list in pairs(TM.Data().mods) do
        for _, m in ipairs(list) do
            if not seen[m.talent] then seen[m.talent] = true; out[#out + 1] = m.talent end
        end
    end
    table.sort(out)
    return out
end

-- The talent points the math should use for profile p.
--   p.talentPoints = a map (inspected player, Sim Lab), else your own.
local function pointsFor(p)
    if p and p.talentPoints then return p.talentPoints end
    return TM.RealPoints() or {}
end

-- Multiplier for one spell and points map. kind "power" adds, "cost"
-- takes away (Convection-style "mana cost reduced by 8%").
function TM.Multiplier(key, kind, points)
    local sum = 0
    for _, m in ipairs(TM.ModsFor(key)) do
        if m.kind == kind then sum = sum + m.perPoint * (points[m.talent] or 0) end
    end
    if kind == "cost" then return math.max(0, 1 - sum / 100) end
    return math.max(0, 1 + sum / 100)
end

-- How profile p's numbers compare with your tooltip, for one spell.
-- Returns powerRatio, costRatio.
function TM.Ratio(key, p)
    local real = TM.RealPoints() or {}
    local them = pointsFor(p)
    local function r(kind)
        local mine = TM.Multiplier(key, kind, real)
        if mine <= 0 then return 1 end
        return TM.Multiplier(key, kind, them) / mine
    end
    return r("power"), r("cost")
end

local function describe(key, points)
    local parts = {}
    for _, m in ipairs(TM.ModsFor(key)) do
        local n = points[m.talent] or 0
        if n > 0 then
            parts[#parts + 1] = ("%s %d (%s%s%%%s)"):format(m.talent, n, m.perPoint >= 0 and "+" or "",
                ns.fmt(m.perPoint * n, 1), m.kind == "cost" and " mana" or "")
        end
    end
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

local function scaled(t, fields, by)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    for _, k in ipairs(fields) do
        if type(c[k]) == "number" then c[k] = c[k] * by end
    end
    return c
end

-- A copy of one spell rank with profile p's talents instead of yours.
-- Returns the same rank if no talent touches this spell.
function TM.AdjustRank(rank, p)
    if not rank or not p or rank.talent then return rank end
    local mods = TM.ModsFor(rank.key)
    local unread = TM.Data().unread[rank.key]
    if #mods == 0 and not unread and not p.talentsUnknown then return rank end
    local power, cost = TM.Ratio(rank.key, p)
    local c = {}
    for k, v in pairs(rank) do c[k] = v end
    c.imbue = scaled(rank.imbue, { "ap", "min", "max" }, power)
    c.dmg = scaled(rank.dmg, { "min", "max", "dot" }, power)
    c.totem = scaled(rank.totem, { "min", "max" }, power)
    c.shield = scaled(rank.shield, { "dmg" }, power)
    c.heal = scaled(rank.heal, { "min", "max", "hot" }, power)
    if rank.mana then c.mana = rank.mana * cost end

    local real = TM.RealPoints() or {}
    local them = pointsFor(p)
    local info = { power = power, cost = cost, unknown = p.talentsUnknown, lines = {} }
    local L = info.lines
    if #mods > 0 then
        L[#L + 1] = { "Your tooltip includes your talents", describe(rank.key, real) }
        local who = p.source == "inspect" and ((p.name or "Their") .. "'s talents")
            or p.source == "sim" and "Sim Lab talents" or "Talents used"
        L[#L + 1] = { who, p.talentsUnknown and "|cffff8000unknown, counted as none|r" or describe(rank.key, them) }
        if math.abs(power - 1) > 1e-9 then L[#L + 1] = { "So the numbers are multiplied by", ns.fmt(power, 3) } end
        if math.abs(cost - 1) > 1e-9 then L[#L + 1] = { "Mana cost multiplied by", ns.fmt(cost, 3) } end
        L[#L + 1] = "🔶 Read from the talent text. Assumes the text shows the total for your points."
    end
    if unread then
        local names = {}
        for n in pairs(unread) do names[#names + 1] = n end
        table.sort(names)
        L[#L + 1] = ("|cffff8000%s mentions this spell, but the addon couldn't read how much it changes it. The numbers may still include it.|r"):format(table.concat(names, ", "))
    end
    c.talent = info
    return c
end

-- One short line for the "Numbers used" lists: which talents the math uses.
function TM.Summary(p)
    local names = TM.TalentNames()
    if TM.Data().cantRead then return "couldn't read your talents", "warn" end
    if p.talentsUnknown then return "couldn't read their talents: counted as none", "warn" end
    local them = pointsFor(p)
    local parts = {}
    for _, n in ipairs(names) do
        if (them[n] or 0) > 0 then parts[#parts + 1] = n .. " " .. them[n] end
    end
    if #names == 0 then return "no talent found that changes these spells", "ok" end
    return #parts > 0 and table.concat(parts, ", ") or "none of: " .. table.concat(names, ", "), "ok"
end

-- /es talents: what the addon read from your talents, to check it.
function TM.Print()
    TM.Reset()
    local d = TM.Data()
    if d.cantRead then
        ns.say("|cffff8000couldn't read your talents|r, so tooltip numbers are used as they are (with your talents in them).")
        return
    end
    local any = false
    local keys = {}
    for key in pairs(d.mods) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local list = d.mods[key]
        local spell = ns.RANKS_BY_KEY[key]
        for _, m in ipairs(list) do
            any = true
            ns.say(("%s %d point(s): %s %s%s%% per point (text says %s%% for %d point(s))"):format(
                m.talent, (d.real or {})[m.talent] or 0, spell and spell.name or key,
                m.kind == "cost" and "mana cost -" or (m.perPoint >= 0 and "+" or ""),
                ns.fmt(math.abs(m.perPoint), 2), ns.fmt(m.textPct, 1), m.textPoints))
        end
    end
    for key, names in pairs(d.unread) do
        for name, text in pairs(names) do
            ns.say(("|cffff8000%s mentions %s but no %% was read:|r %s"):format(name, key, text))
        end
    end
    if not any then ns.say("no talent found that changes the spells or weapon buffs the addon uses.") end
    for _, name in ipairs({ "Elemental Weapons", "Spirit Weapons" }) do
        local text = ns.Talents.Description(name)
        ns.say(("%s text: |cffaaaaaa%s|r"):format(name, text or "(the game didn't give us its text)"))
    end
end

ns.on("SPELLS_CHANGED", TM.Reset)
ns.on("PLAYER_TALENT_UPDATE", TM.Reset)
ns.on("TRAIT_CONFIG_UPDATED", TM.Reset)
ns.on("CHARACTER_POINTS_CHANGED", TM.Reset)
