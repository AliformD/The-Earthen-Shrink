-- The Earthen Shrink: reads real spell data from the game
--
-- For every spell rank we ask the game for:
--   name       (to check the ID really is that spell in Forever)
--   level      (when you can learn it)
--   mana cost, cast time
--   tooltip text, which we read the damage numbers out of
--
-- Nothing here is copied from a website. If the game doesn't answer, the
-- rank is marked as unknown instead of guessed.

local _, ns = ...
local SD = {}
ns.SpellData = SD

SD.byKey = {}       -- SD.byKey.LB = { {rank record}, {rank record}, ... }
SD.discarded = {}   -- IDs whose name didn't match (so we know the guess was wrong)

---------------------------------------------------------------------------
-- Reading text
---------------------------------------------------------------------------

local function stripCodes(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    -- "1,234" -> "1234" so the number patterns below work
    s = s:gsub("(%d),(%d%d%d)", "%1%2")
    return s
end

local NUM = "(%d+%.?%d*)"

-- Reads damage numbers out of a spell description.
-- Returns a table like { min = 28, max = 33, dot = 12, dotSec = 12 }.
function SD.ParseDamage(text)
    text = stripCodes(text)
    if not text then return nil end
    local out = {}
    local lower = text:lower()

    -- Damage over time: "28 Fire damage over 12 sec"
    local dot, sec = lower:match(NUM .. " %a+ damage over " .. NUM .. " sec")
    if dot then
        out.dot, out.dotSec = tonumber(dot), tonumber(sec)
        lower = lower:gsub(NUM .. " %a+ damage over " .. NUM .. " sec", "", 1)
    end

    -- Direct damage: "15 to 17 Nature damage" or "25 Fire damage"
    local a, b = lower:match(NUM .. " to " .. NUM .. " %a+ damage")
    if a then
        out.min, out.max = tonumber(a), tonumber(b)
    else
        local one = lower:match(NUM .. " %a+ damage")
        if one then out.min, out.max = tonumber(one), tonumber(one) end
    end

    if not out.min and not out.dot then return nil end
    out.min, out.max = out.min or 0, out.max or 0
    return out
end

-- Reads the numbers out of a weapon imbue description.
function SD.ParseImbue(key, text)
    text = stripCodes(text)
    if not text then return nil end
    local lower = text:lower()
    local out = {}
    if key == "RB" then
        out.ap = tonumber(lower:match("attack power by " .. NUM) or lower:match(NUM .. " attack power"))
        if not out.ap then return nil end
    elseif key == "FT" then
        local a, b = lower:match(NUM .. " to " .. NUM)
        if not a then
            a = lower:match(NUM .. " additional %a+ damage") or lower:match(NUM .. " %a+ damage")
            b = a
        end
        if not a then return nil end
        out.min, out.max = tonumber(a), tonumber(b)
    elseif key == "WF" then
        out.chance = tonumber(lower:match(NUM .. "%% chance"))
        out.ap = tonumber(lower:match(NUM .. " extra attack power") or lower:match(NUM .. " attack power"))
        local n = lower:match(NUM .. " extra attacks") or lower:match("(%a+) extra attacks")
        local words = { one = 1, two = 2, three = 3, an = 1 }
        out.attacks = tonumber(n) or words[n or ""] or 2
        out.attacksGuessed = not (tonumber(n) or words[n or ""])
        if not out.chance or not out.ap then return nil end
    end
    return out
end

-- "Heals a friendly target for 34 to 44." -> { min = 34, max = 44 }
function SD.ParseHeal(text)
    text = stripCodes(text)
    if not text then return nil end
    local lower = text:lower()
    local a, b = lower:match("for " .. NUM .. " to " .. NUM)
    if not a then a, b = lower:match(NUM .. " to " .. NUM) end
    if not a then a = lower:match("for " .. NUM); b = a end
    if not a then return nil end
    local out = { min = tonumber(a), max = tonumber(b) }
    local hot, sec = lower:match(NUM .. " over " .. NUM .. " sec")
    if hot then out.hot, out.hotSec = tonumber(hot), tonumber(sec) end
    return out
end

-- Reads the time in seconds from "lasts 2 min" or "lasts 30 sec".
local function lasts(lower)
    local m = lower:match("lasts " .. NUM .. " min")
    if m then return tonumber(m) * 60 end
    local s = lower:match("lasts " .. NUM .. " sec")
    if s then return tonumber(s) end
    return nil
end

-- Totems: amount per pulse, how often it pulses, how long it lasts.
function SD.ParseTotem(kind, text)
    text = stripCodes(text)
    if not text then return nil end
    local lower = text:lower()
    local out = { duration = lasts(lower) }
    out.interval = tonumber(lower:match("every " .. NUM .. " sec")) or (lower:match("every second") and 1) or nil
    if kind == "dmg" or kind == "aoe" then
        local a, b = lower:match(NUM .. " to " .. NUM .. " %a+ damage")
        if not a then a = lower:match(NUM .. " %a+ damage"); b = a end
        if not a then return nil end
        out.min, out.max = tonumber(a), tonumber(b)
    elseif kind == "heal" then
        local h = lower:match("for " .. NUM) or lower:match(NUM .. " health")
        if not h then return nil end
        out.min, out.max = tonumber(h), tonumber(h)
    elseif kind == "mana" then
        local m = lower:match(NUM .. " mana") or lower:match(NUM .. "%% of")
        if not m then return nil end
        out.mana = tonumber(m)
        out.manaIsPercent = lower:match(NUM .. "%% of") ~= nil and not lower:match(NUM .. " mana")
    end
    return out
end

-- Lightning Shield: "...causing 13 Nature damage. 3 charges."
function SD.ParseShield(text)
    text = stripCodes(text)
    if not text then return nil end
    local lower = text:lower()
    local d = lower:match(NUM .. " %a+ damage")
    if not d then return nil end
    local charges = tonumber(lower:match(NUM .. " charges"))
    return { dmg = tonumber(d), charges = charges or 3, chargesGuessed = charges == nil, duration = lasts(lower) }
end

---------------------------------------------------------------------------
-- Asking the game about one spell ID
---------------------------------------------------------------------------

local function tooltipLines(id)
    if not (C_TooltipInfo and C_TooltipInfo.GetSpellByID) then return {} end
    local data = ns.try(C_TooltipInfo.GetSpellByID, id)
    local lines = {}
    if type(data) == "table" and type(data.lines) == "table" then
        for _, l in ipairs(data.lines) do
            local left, right = stripCodes(ns.clean(l.leftText)), stripCodes(ns.clean(l.rightText))
            if left then lines[#lines + 1] = left end
            if right then lines[#lines + 1] = right end
        end
    end
    return lines
end

local function manaCost(id, lines)
    if C_Spell and C_Spell.GetSpellPowerCost then
        local costs = ns.try(C_Spell.GetSpellPowerCost, id)
        if type(costs) == "table" then
            for _, c in ipairs(costs) do
                local isMana = c.type == 0 or c.name == "MANA" or c.name == "Mana"
                local cost = ns.clean(c.cost) or ns.clean(c.minCost)
                if isMana and type(cost) == "number" and cost > 0 then return cost, "game" end
            end
        end
    end
    for _, l in ipairs(lines) do
        local m = l:match("^" .. NUM .. " [Mm]ana$")
        if m then return tonumber(m), "tooltip" end
    end
    return nil
end

local function castSeconds(info, lines)
    if type(info) == "table" and type(ns.clean(info.castTime)) == "number" then
        return info.castTime / 1000
    end
    for _, l in ipairs(lines) do
        if l == "Instant" or l == "Instant cast" then return 0 end
        local s = l:match(NUM .. " sec cast")
        if s then return tonumber(s) end
    end
    return nil
end

local function levelFor(name, rank, id, guess)
    local db = ns.db()
    local t = db.trainer[name]
    if t and t[rank] and t[rank].level then return t[rank].level, "trainer" end
    if C_Spell and C_Spell.GetSpellLevelLearned then
        local lv = ns.try(C_Spell.GetSpellLevelLearned, id)
        if type(lv) == "number" and lv > 0 then return lv, "game" end
    end
    return guess, "guess"
end

local function isKnown(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return ns.try(C_SpellBook.IsSpellKnown, id) and true or false
    end
    if IsSpellKnown then return ns.try(IsSpellKnown, id) and true or false end
    return false
end

local pending = {}   -- spell IDs whose text hasn't loaded yet

-- Builds (or rebuilds) the record for one rank.
local function readRank(spell, id, rank, guessLevel)
    local rec = { id = id, rank = rank, key = spell.key, name = spell.name }
    local info = C_Spell and ns.try(C_Spell.GetSpellInfo, id)
    local gameName = type(info) == "table" and ns.clean(info.name) or nil
    if gameName ~= spell.name then
        -- The game says this ID is something else (or doesn't exist), so our
        -- Classic guess was wrong for Forever. Skip it.
        SD.discarded[#SD.discarded + 1] = ("%s rank %d (ID %d is %s in this game)"):format(
            spell.name, rank, id, gameName and ("'" .. gameName .. "'") or "unknown")
        return nil
    end
    rec.nameOK = true
    rec.icon = type(info) == "table" and ns.clean(info.iconID) or nil

    local lines = tooltipLines(id)
    rec.mana, rec.manaSource = manaCost(id, lines)
    rec.cast = castSeconds(info, lines)
    rec.level, rec.levelSource = levelFor(spell.name, rank, id, guessLevel)
    rec.known = isKnown(id)

    local desc = C_Spell and ns.try(C_Spell.GetSpellDescription, id)
    desc = ns.clean(desc)
    if (not desc or desc == "") and #lines > 0 then
        -- the description is usually the last long line of the tooltip
        for i = #lines, 1, -1 do
            if #lines[i] > 30 then desc = lines[i]; break end
        end
    end
    rec.desc = stripCodes(desc)
    local k = spell.kind
    if k == "imbue" then
        rec.imbue = SD.ParseImbue(spell.key, rec.desc)
        rec.parsed = rec.imbue ~= nil
    elseif k == "spell" then
        rec.dmg = SD.ParseDamage(rec.desc)
        rec.parsed = rec.dmg ~= nil
    elseif k == "heal" then
        rec.heal = SD.ParseHeal(rec.desc)
        rec.parsed = rec.heal ~= nil
    elseif k == "totem" then
        rec.totem = SD.ParseTotem(spell.totem, rec.desc)
        rec.parsed = rec.totem ~= nil
    elseif k == "shield" then
        rec.shield = SD.ParseShield(rec.desc)
        rec.parsed = rec.shield ~= nil
    else
        rec.parsed = rec.desc ~= nil
    end

    if not rec.desc or rec.desc == "" then
        pending[id] = true
        if C_Spell and C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, id) end
    end
    return rec
end

---------------------------------------------------------------------------
-- Building the full list
---------------------------------------------------------------------------

-- Spells in your spellbook that match one of our spell names.
local function spellbookRanks()
    local found = {}
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return found end
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
    local numLines = ns.try(C_SpellBook.GetNumSpellBookSkillLines) or 0
    for line = 1, numLines do
        local li = ns.try(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if type(li) == "table" and li.itemIndexOffset and li.numSpellBookItems then
            for i = li.itemIndexOffset + 1, li.itemIndexOffset + li.numSpellBookItems do
                local item = ns.try(C_SpellBook.GetSpellBookItemInfo, i, bank)
                if type(item) == "table" and item.spellID and ns.RANKS_BY_NAME[item.name or ""] then
                    local sub = item.subName or (C_Spell and ns.try(C_Spell.GetSpellSubtext, item.spellID)) or ""
                    local rank = tonumber(tostring(sub):match("(%d+)")) or 1
                    found[#found + 1] = { name = item.name, id = item.spellID, rank = rank }
                end
            end
        end
    end
    return found
end

function SD.Rebuild()
    SD.discarded = {}
    -- 1. Gather candidate IDs: our guess list, then the trainer, then the spellbook.
    --    Later sources replace earlier ones for the same rank.
    local candidates = {}   -- candidates[key][rank] = { id, level }
    for _, s in ipairs(ns.RANKS) do
        candidates[s.key] = {}
        for _, r in ipairs(s.ranks) do candidates[s.key][r.rank] = { id = r.id, level = r.level } end
    end
    for name, ranks in pairs(ns.db().trainer) do
        local s = ns.RANKS_BY_NAME[name]
        if s then
            for rank, t in pairs(ranks) do
                if t.id then
                    local c = candidates[s.key][rank] or {}
                    c.id, c.level = t.id, t.level or c.level
                    candidates[s.key][rank] = c
                end
            end
        end
    end
    for _, b in ipairs(spellbookRanks()) do
        local s = ns.RANKS_BY_NAME[b.name]
        local c = candidates[s.key][b.rank] or {}
        c.id = b.id
        candidates[s.key][b.rank] = c
    end

    -- 2. Ask the game about each one.
    for _, s in ipairs(ns.RANKS) do
        local list = {}
        for rank, c in pairs(candidates[s.key]) do
            local rec = c.id and readRank(s, c.id, rank, c.level)
            if rec then list[#list + 1] = rec end
        end
        table.sort(list, function(a, b) return a.rank < b.rank end)
        SD.byKey[s.key] = list
    end
    ns.refresh("spelldata")
end

-- Every rank of a spell, lowest first.
function SD.Ranks(key)
    return SD.byKey[key] or {}
end

-- The highest rank you can have at this level (we assume you bought it).
function SD.Best(key, level)
    local best
    for _, r in ipairs(SD.Ranks(key)) do
        if r.level and r.level <= level and (not best or r.rank > best.rank) then best = r end
    end
    return best
end

---------------------------------------------------------------------------
-- Class trainer: saves the real Forever level for every rank
---------------------------------------------------------------------------

local function readTrainer()
    if not GetNumTrainerServices then return end
    if SetTrainerServiceTypeFilter then
        pcall(SetTrainerServiceTypeFilter, "available", 1)
        pcall(SetTrainerServiceTypeFilter, "unavailable", 1)
        pcall(SetTrainerServiceTypeFilter, "used", 1)
    end
    local db, saved = ns.db(), 0
    for i = 1, (ns.try(GetNumTrainerServices) or 0) do
        local name, rankText = ns.try(GetTrainerServiceInfo, i)
        if name and ns.RANKS_BY_NAME[name] then
            local rank = tonumber(tostring(rankText or ""):match("(%d+)")) or 1
            local level = ns.try(GetTrainerServiceLevelReq, i)
            local id
            if C_TooltipInfo and C_TooltipInfo.GetTrainerService then
                local data = ns.try(C_TooltipInfo.GetTrainerService, i)
                if type(data) == "table" and type(data.id) == "number" then id = data.id end
            end
            db.trainer[name] = db.trainer[name] or {}
            db.trainer[name][rank] = { level = level, id = id }
            saved = saved + 1
        end
    end
    if saved > 0 then
        ns.say(("saved %d spell ranks from your trainer. Levels now come from the trainer."):format(saved))
        SD.Rebuild()
    end
end

---------------------------------------------------------------------------
-- Start up and keep up to date
---------------------------------------------------------------------------

local rebuildQueued = false
local function queueRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    C_Timer.After(0.5, function() rebuildQueued = false; SD.Rebuild() end)
end

function SD.Init()
    SD.Rebuild()
    -- Spell text loads in the background. Try again a few seconds later.
    C_Timer.After(3, SD.Rebuild)
end

ns.on("SPELL_DATA_LOAD_RESULT", function(id)
    if pending[id] then pending[id] = nil; queueRebuild() end
end)
ns.on("SPELLS_CHANGED", queueRebuild)
ns.on("TRAINER_SHOW", function() C_Timer.After(1, readTrainer) end)

-- /es check: shows what the addon could read, so we can spot problems.
function SD.PrintCheck()
    for _, s in ipairs(ns.RANKS) do
        local list, parsed, fromGame = SD.Ranks(s.key), 0, 0
        for _, r in ipairs(list) do
            if r.parsed then parsed = parsed + 1 end
            if r.levelSource ~= "guess" then fromGame = fromGame + 1 end
        end
        ns.say(("%s: %d ranks found, %d tooltips read, %d levels from the game/trainer"):format(
            s.name, #list, parsed, fromGame))
    end
    for _, d in ipairs(SD.discarded) do ns.say("|cffff8000skipped:|r " .. d) end
    local lb = SD.Best("LB", UnitLevel("player") or 1)
    if lb then ns.say(("Lightning Bolt rank %d tooltip: %s"):format(lb.rank, lb.desc or "(empty)")) end
end
