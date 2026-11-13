-- The Earthen Shrink: character profiles
--
-- A "profile" is one table with everything the math needs about a character:
-- level, mana, spell power, crit, hit, attack power and weapon.
--
--   ns.Profile.Player()   -> YOUR character, read straight from the game (exact)
--   ns.Inspect.profile    -> another player you inspected (built from their gear,
--                            so some numbers are estimates and are marked as such)

local _, ns = ...
local P = {}
ns.Profile = P

local SLOT_MAIN_HAND = 16
local SCHOOL_INDEX = { Physical = 1, Holy = 2, Fire = 3, Nature = 4, Frost = 5, Shadow = 6, Arcane = 7 }
P.SCHOOL_INDEX = SCHOOL_INDEX

---------------------------------------------------------------------------
-- Reading an item tooltip (works for your gear and for inspected gear)
---------------------------------------------------------------------------

local function linesOf(data)
    local out = {}
    if type(data) == "table" and type(data.lines) == "table" then
        for _, l in ipairs(data.lines) do
            for _, t in ipairs({ ns.clean(l.leftText), ns.clean(l.rightText) }) do
                if type(t) == "string" and t ~= "" then
                    out[#out + 1] = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                end
            end
        end
    end
    return out
end

local function itemLines(unit, slot, link)
    if not C_TooltipInfo then return {} end
    local data
    if C_TooltipInfo.GetInventoryItem then data = ns.try(C_TooltipInfo.GetInventoryItem, unit, slot) end
    if (not data or not data.lines) and link and C_TooltipInfo.GetHyperlink then
        data = ns.try(C_TooltipInfo.GetHyperlink, link)
    end
    return linesOf(data)
end

-- "Windfury Totem" must be checked before "Windfury".
local IMBUE_NAMES = { { "Rockbiter", "RB" }, { "Flametongue", "FT" }, { "Frostbrand", "FB" },
                      { "Windfury Totem", "WFT" }, { "Windfury", "WF" } }

local PRIMARY = { Strength = "str", Agility = "agi", Stamina = "sta", Intellect = "int", Spirit = "spi" }

-- Adds up the stats on one item. Returns a table like { str = 5, sp = 12 }.
function P.ReadItemLines(lines, into)
    into = into or {}
    local function add(k, v) if v then into[k] = (into[k] or 0) + tonumber(v) end end
    for _, l in ipairs(lines) do
        local low = l:lower()
        local n, stat = l:match("^%+(%d+) (%a+)$")
        if n and PRIMARY[stat] then add(PRIMARY[stat], n) end
        add("sp", low:match("spell power by (%d+)") or low:match("^%+(%d+) spell power")
            or low:match("magical spells and effects by up to (%d+)") or low:match("spell damage by up to (%d+)"))
        -- Healing-only lines ("Increases healing done by spells and effects by up to 22.")
        add("heal", low:match("healing done by spells and effects by up to (%d+)") or low:match("^%+(%d+) healing")
            or low:match("increases healing done by up to (%d+)"))
        add("ap", low:match("attack power by (%d+)") or low:match("^%+(%d+) attack power"))
        -- Crit and hit as a %: "...critical strike by 1%" or "...critical
        -- strike with spells by 1%". Forever combines melee and spell crit
        -- (and hit), so both kinds count as one.
        add("crit", low:match("critical strike[%a ]-by (%d+)%%"))
        add("hit", low:match("chance to hit[%a ]-by (%d+)%%"))
        -- 🔶 Or as a rating, in case Forever gear says "+14 Critical Strike
        -- Rating" (sites disagree). Turned into % by the Sim Lab when the
        -- game tells us how much rating = 1%.
        add("critRating", low:match("critical strike rating by (%d+)") or low:match("^%+(%d+) critical strike rating")
            or low:match("^%+(%d+) crit rating"))
        add("hitRating", low:match("hit rating by (%d+)") or low:match("^%+(%d+) hit rating"))
        -- Weapon damage and speed: "35 - 66 Damage", "Speed 2.60"
        local a, b = l:match("^(%d+) %- (%d+)%s+%a*%s*Damage")
        if a and not into.wMin then into.wMin, into.wMax = tonumber(a), tonumber(b) end
        -- A weapon buff shows on the weapon as a green line like "Rockbiter 3 (60 min)".
        if not into.imbueNow then
            for _, pair in ipairs(IMBUE_NAMES) do
                if l:find("^" .. pair[1] .. " ?%d*%s*%(") then into.imbueNow = pair[2]; break end
            end
        end
        local sp = l:match("Speed (%d+%.%d+)")
        if sp and not into.wSpeed then into.wSpeed = tonumber(sp) end
    end
    return into
end

function P.ReadWeapon(unit)
    local link = ns.try(GetInventoryItemLink, unit, SLOT_MAIN_HAND)
    if not link then return nil end
    local s = P.ReadItemLines(itemLines(unit, SLOT_MAIN_HAND, link))
    if not s.wMin then return { link = link, imbueNow = s.imbueNow } end
    return { link = link, min = s.wMin, max = s.wMax, speed = s.wSpeed, name = link:match("%[(.-)%]"),
             imbueNow = s.imbueNow }
end

-- The game's own stat list for an item. Only used to fill in Strength,
-- Agility, Stamina, Intellect, Spirit, spell power and attack power when
-- the tooltip text didn't give them.
local STAT_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "str", ITEM_MOD_AGILITY_SHORT = "agi", ITEM_MOD_STAMINA_SHORT = "sta",
    ITEM_MOD_INTELLECT_SHORT = "int", ITEM_MOD_SPIRIT_SHORT = "spi",
    ITEM_MOD_SPELL_POWER_SHORT = "sp", ITEM_MOD_ATTACK_POWER_SHORT = "ap",
}

local function fillFromGameStats(link, s)
    if not (C_Item and C_Item.GetItemStats) then return end
    local t = ns.try(C_Item.GetItemStats, link)
    if type(t) ~= "table" then return end
    for key, k in pairs(STAT_KEYS) do
        local v = tonumber(ns.clean(t[key]))
        if v and not s[k] then s[k] = v end
    end
end

-- Stats of any item link (an item you don't own, from chat or a loot list).
-- Returns the stats, and false if the game hasn't loaded the item yet.
function P.LinkStats(link)
    local data = C_TooltipInfo and C_TooltipInfo.GetHyperlink and ns.try(C_TooltipInfo.GetHyperlink, link)
    local lines = linesOf(data)
    local s = P.ReadItemLines(lines)
    fillFromGameStats(link, s)
    return s, #lines > 0
end

-- Stats of the item you are wearing in one slot ({} if the slot is empty).
function P.ItemStats(unit, slot)
    local link = ns.try(GetInventoryItemLink, unit, slot)
    if not link then return {}, nil end
    local s = P.ReadItemLines(itemLines(unit, slot, link))
    fillFromGameStats(link, s)
    return s, link
end

---------------------------------------------------------------------------
-- YOUR character (exact numbers from the game)
---------------------------------------------------------------------------

function P.Player()
    local p = { unit = "player", source = "you", estimated = {} }
    p.name = UnitName("player")
    p.level = UnitLevel("player") or 1
    local _, classFile = UnitClass("player")
    p.classFile = classFile
    p.isShaman = classFile == "SHAMAN"
    p.mana = ns.clean(UnitPowerMax("player", 0)) or 0
    p.manaNow = ns.clean(UnitPower("player", 0))

    p.sp = {}
    for school, i in pairs(SCHOOL_INDEX) do
        p.sp[school] = ns.clean(ns.try(GetSpellBonusDamage, i)) or 0
    end
    p.healing = ns.clean(ns.try(GetSpellBonusHealing)) or 0
    p.healingNow = p.healing   -- stays the same in Sim Lab copies (what tooltips include)
    -- Forever uses one crit chance and one hit chance for everything.
    p.spellCrit = ns.clean(ns.try(GetSpellCritChance, SCHOOL_INDEX.Nature)) or 0
    p.meleeCrit = ns.clean(ns.try(GetCritChance)) or p.spellCrit
    -- Hit: the game's own total. GetHitModifier = hit from gear lines,
    -- talents and racials (anything that's an "aura" on you). If Forever
    -- gear uses hit RATING, that part is separate, so we add it.
    p.hitParts = { mod = ns.clean(ns.try(GetHitModifier)) or 0 }
    local hitRating = ns.HitCrit and ns.HitCrit.RatingBonus("hit") or 0
    p.hitParts.rating = hitRating
    p.hit = p.hitParts.mod + hitRating
    p.spellHit = ns.clean(ns.try(GetSpellHitModifier)) or p.hit
    if p.spellHit > 30 then p.spellHit = p.hit end      -- not a sane % (some clients); use melee hit
    if p.spellHit < p.hit then p.spellHit = p.hit end   -- Forever: one combined hit

    local base, pos, neg = ns.try(UnitAttackPower, "player")
    p.ap = (ns.clean(base) or 0) + (ns.clean(pos) or 0) + (ns.clean(neg) or 0)
    p.weapon = P.ReadWeapon("player")
    if p.weapon and not p.weapon.speed then
        p.weapon.speed = ns.clean(ns.try(UnitAttackSpeed, "player"))
    end

    -- Is a weapon buff on right now? If it's Rockbiter, its attack power is
    -- already inside p.ap, so the math would count it twice.
    local hasMH = ns.try(GetWeaponEnchantInfo)
    p.hasImbueNow = hasMH and true or false
    p.imbueNow = p.weapon and p.weapon.imbueNow
    p.secret = ns.inCombat() and C_Secrets and C_Secrets.ShouldUnitStatsBeSecret
        and ns.try(C_Secrets.ShouldUnitStatsBeSecret, "player") or false
    return p
end

---------------------------------------------------------------------------
-- Someone else (built from their gear)
---------------------------------------------------------------------------

-- 🔶 Classic rules used as placeholders. Not verified for Forever. We can't
-- read another player's base stats, so we estimate them from their level.
P.ESTIMATE = {
    baseStr = function(L) return 22 + (L - 1) * 1.1 end,
    baseAgi = function(L) return 16 + (L - 1) * 0.5 end,
    baseInt = function(L) return 22 + (L - 1) * 0.9 end,
    apFromStr = function(L, str) return L * 2 + str * 2 - 20 end,   -- Shaman attack power
    meleeCrit = function(agi) return 1.7 + agi / 20 end,
    spellCrit = function(L, int) return 2.2 + int / (10 + 49.5 * (L / 60)) end,
}

function P.FromGear(unit, info)
    local p = { unit = unit, source = "inspect", estimated = {} }
    p.name, p.level, p.classFile = info.name, info.level, info.classFile
    p.isShaman = p.classFile == "SHAMAN"
    p.mana = ns.clean(ns.try(UnitPowerMax, unit, 0))
    if not p.mana or p.mana == 0 then p.mana = nil; p.estimated.mana = true end

    local g = {}
    for slot = 1, 19 do
        local link = ns.try(GetInventoryItemLink, unit, slot)
        if link then P.ReadItemLines(itemLines(unit, slot, link), g) end
    end
    p.gear = g
    local L, E = p.level, P.ESTIMATE
    local str = E.baseStr(L) + (g.str or 0)
    local agi = E.baseAgi(L) + (g.agi or 0)
    local int = E.baseInt(L) + (g.int or 0)
    p.ap = E.apFromStr(L, str) + (g.ap or 0)
    p.meleeCrit = E.meleeCrit(agi) + (g.crit or 0)
    p.spellCrit = E.spellCrit(L, int) + (g.crit or 0)
    p.hit, p.spellHit = g.hit or 0, g.hit or 0
    -- Spell power: the game has no way to ask for another player's spell
    -- power (that function only answers for you), so we add up the spell
    -- power written on their gear. Mental Quickness (Intellect gives spell
    -- power) is added if their talents can be read. 🔶 Untested in Forever.
    local spGear = g.sp or 0
    local mq = p.isShaman and ns.Talents and ns.Talents.Rank("Mental Quickness", unit) or nil
    local spInt = 0
    if mq and mq > 0 then
        spInt = int * ns.SimMath.MentalQuickRatio() * mq
        p.estimated.sp = true   -- their total Intellect is an estimate
    end
    p.mentalQuick, p.spFromGear, p.spFromInt = mq, spGear, spInt
    -- Their talent points, so buffs and spells use THEIR talents and not
    -- the ones inside your tooltips (Math/TalentMods.lua). If the game
    -- won't tell us, we count no talents and say so on the Inspect tab.
    if p.isShaman then
        p.talentPoints = ns.Talents and ns.Talents.Points(unit, p.level)
        if not p.talentPoints then p.talentPoints, p.talentsUnknown = {}, true end
    else
        p.talentPoints = {}   -- not a Shaman: no Shaman talents
    end
    -- Mental Dexterity: their Intellect also gives attack power.
    local md = p.talentPoints["Mental Dexterity"] or 0
    if md > 0 and ns.SimMath then
        p.apFromInt = int * ns.SimMath.MentalDexRatio() * md
        p.ap = p.ap + p.apFromInt
    end
    p.mentalDex = md
    p.sp = {}
    for school in pairs(SCHOOL_INDEX) do p.sp[school] = spGear + spInt end
    p.healing = spGear + spInt
    if not p.mana then p.mana = math.floor(55 + 18.5 * L + 15 * math.max(0, int - 20)) end
    p.estimated.ap, p.estimated.meleeCrit, p.estimated.spellCrit = true, true, true

    if g.wMin then
        p.weapon = { min = g.wMin, max = g.wMax, speed = g.wSpeed }
        local link = ns.try(GetInventoryItemLink, unit, SLOT_MAIN_HAND)
        p.weapon.name = link and link:match("%[(.-)%]")
    end
    return p
end

---------------------------------------------------------------------------
-- Inspecting another player
---------------------------------------------------------------------------

local I = {}
ns.Inspect = I
I.profile = nil      -- the last player you inspected
I.status = "Target a player and press Inspect."

local waitingFor     -- the GUID we asked the game to inspect

local function setStatus(s) I.status = s; ns.refresh("inspect") end

function I.Start(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return setStatus("Target a player first, then press Inspect.")
    end
    if UnitIsUnit and UnitIsUnit(unit, "player") then
        return setStatus("That's you! Your own numbers are on the Weapon Buffs tab.")
    end
    if CanInspect and not CanInspect(unit) then
        return setStatus("This player can't be inspected right now.")
    end
    if CheckInteractDistance and not CheckInteractDistance(unit, 1) then
        return setStatus("Get a bit closer to inspect them.")
    end
    local _, classFile = UnitClass(unit)
    I.info = { name = UnitName(unit), level = UnitLevel(unit), classFile = classFile, guid = UnitGUID(unit) }
    waitingFor = I.info.guid
    setStatus("Inspecting " .. (I.info.name or "?") .. "...")
    NotifyInspect(unit)
    -- If the game never answers (too far away, they logged off), say so.
    C_Timer.After(4, function()
        if waitingFor == I.info.guid then
            waitingFor = nil
            setStatus("No answer from the game. Get closer and try again.")
        end
    end)
end

-- Item text can take a moment to load, so read a few times.
local function readWhenLoaded(unit, tries)
    local missing = 0
    for slot = 1, 19 do
        local link = ns.try(GetInventoryItemLink, unit, slot)
        local id = ns.try(GetInventoryItemID, unit, slot)
        if id and not link then missing = missing + 1 end
        if id and C_Item and C_Item.IsItemDataCachedByID and not ns.try(C_Item.IsItemDataCachedByID, id) then
            missing = missing + 1
            if C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
        end
    end
    if missing > 0 and tries > 0 then
        C_Timer.After(0.4, function() readWhenLoaded(unit, tries - 1) end)
        return
    end
    I.profile = P.FromGear(unit, I.info)
    if ClearInspectPlayer then pcall(ClearInspectPlayer) end
    local who = I.profile.name or "?"
    if not I.profile.isShaman then
        setStatus(who .. " isn't a Shaman. Showing what each Shaman weapon buff would do with their weapon.")
    elseif not I.profile.weapon then
        setStatus(who .. " has no weapon we could read.")
    else
        setStatus("Inspected " .. who .. ".")
    end
end

ns.on("INSPECT_READY", function(guid)
    if not waitingFor or guid ~= waitingFor then return end
    waitingFor = nil
    -- The target may have changed, so find the unit that has this GUID.
    local unit = "target"
    for _, u in ipairs({ "target", "mouseover", "focus", "party1", "party2", "party3", "party4" }) do
        if UnitGUID(u) == guid then unit = u; break end
    end
    readWhenLoaded(unit, 6)
end)
