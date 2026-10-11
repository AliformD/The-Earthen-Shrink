-- Earthen Shrink Export
-- A helper addon that reads everything The Earthen Shrink needs from the game
-- (spells, ranks, talents, stats, gear, weapon buffs, totems and their tooltip
-- text) and saves it to a SavedVariables file that can be uploaded to Claude.
--
-- It only reads. It never casts, buys or changes anything.
--
-- Commands:
--   /esx            export everything (label "default")
--   /esx <label>    export under a name, e.g. /esx nogear
--   /esx status     show what has been saved this session
--
-- The file is written when you type /reload or log out:
--   World of Warcraft\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables\EarthenShrinkExport.lua

local ADDON = ...
local VERSION = "0.1.0"

local errors        -- list of problems hit during the current export
local missingText   -- how many spells had no tooltip text yet (data still loading)

local function say(msg)
    print("|cff3fc7ebEarthen Shrink Export:|r " .. msg)
end

local function getDB()
    EarthenShrinkExportDB = EarthenShrinkExportDB or {}
    local db = EarthenShrinkExportDB
    db.exports = db.exports or {}
    db.trainers = db.trainers or {}
    return db
end

-- Values can be "secret" on this client. A secret value can't be stored or
-- compared, so swap it for a marker.
local function clean(v)
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    return v
end

local function stripCodes(s)
    if type(s) ~= "string" then return s end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return s
end

local function pack(...)
    return { n = select("#", ...), ... }
end

-- Calls a game function safely. If the function is missing or throws, the
-- problem is written down in `errors` instead of stopping the export.
local function try(label, fn, ...)
    if type(fn) ~= "function" then
        errors[#errors + 1] = label .. ": function missing"
        return nil
    end
    local r = pack(pcall(fn, ...))
    if not r[1] then
        errors[#errors + 1] = label .. ": " .. tostring(r[2])
        return nil
    end
    return unpack(r, 2, r.n)
end

-- Same as try(), but returns every result as a list, e.g. {10, 12, 0}.
local function values(label, fn, ...)
    if type(fn) ~= "function" then
        errors[#errors + 1] = label .. ": function missing"
        return nil
    end
    local r = pack(pcall(fn, ...))
    if not r[1] then
        errors[#errors + 1] = label .. ": " .. tostring(r[2])
        return nil
    end
    local out = {}
    for i = 2, r.n do
        local v = clean(r[i])
        if v == nil then v = "nil" end
        out[#out + 1] = v
    end
    return out
end

-- Tooltip data from C_TooltipInfo comes back as { lines = { {leftText, rightText}, ... } }.
-- This turns it into plain text lines, e.g. "Lightning Bolt  |  Rank 4".
local function tooltipLines(data)
    if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local out = {}
    for _, line in ipairs(data.lines) do
        local left, right = stripCodes(clean(line.leftText)), stripCodes(clean(line.rightText))
        if type(left) == "string" and left ~= "" then
            if type(right) == "string" and right ~= "" then
                out[#out + 1] = left .. "  |  " .. right
            else
                out[#out + 1] = left
            end
        end
    end
    if #out == 0 then return nil end
    return out
end

local function tooltip(label, fn, ...)
    if not C_TooltipInfo then return nil end
    return tooltipLines(try(label, fn, ...))
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------

local function spellRecord(spellID)
    local rec = { id = spellID }
    if C_Spell then
        local info = try("C_Spell.GetSpellInfo " .. spellID, C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" then
            rec.name = clean(info.name)
            rec.castTimeMs = clean(info.castTime)
            rec.minRange = clean(info.minRange)
            rec.maxRange = clean(info.maxRange)
        end
        rec.rank = clean(try("C_Spell.GetSpellSubtext " .. spellID, C_Spell.GetSpellSubtext, spellID))
        rec.description = stripCodes(clean(try("C_Spell.GetSpellDescription " .. spellID, C_Spell.GetSpellDescription, spellID)))

        local costs = try("C_Spell.GetSpellPowerCost " .. spellID, C_Spell.GetSpellPowerCost, spellID)
        if type(costs) == "table" then
            rec.costs = {}
            for _, c in ipairs(costs) do
                rec.costs[#rec.costs + 1] = {
                    type = clean(c.name), cost = clean(c.cost), minCost = clean(c.minCost),
                    costPercent = clean(c.costPercent), costPerSec = clean(c.costPerSec),
                }
            end
        end

        local cd = try("C_Spell.GetSpellCooldown " .. spellID, C_Spell.GetSpellCooldown, spellID)
        if type(cd) == "table" then rec.cooldownNow = clean(cd.duration) end
    end
    rec.tooltip = tooltip("tooltip spell " .. spellID, C_TooltipInfo and C_TooltipInfo.GetSpellByID, spellID)

    -- Spell text loads from the server in the background. If it isn't here
    -- yet, ask for it; the automatic second pass picks it up.
    if not rec.tooltip and (rec.description == nil or rec.description == "") then
        missingText = missingText + 1
        if C_Spell and C_Spell.RequestLoadSpellData then
            pcall(C_Spell.RequestLoadSpellData, spellID)
        end
    end
    return rec
end

local function exportSpellbook()
    local list = {}
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
        errors[#errors + 1] = "spellbook: C_SpellBook missing"
        return list
    end
    local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
    local numLines = try("GetNumSpellBookSkillLines", C_SpellBook.GetNumSpellBookSkillLines) or 0
    for line = 1, numLines do
        local lineInfo = try("GetSpellBookSkillLineInfo " .. line, C_SpellBook.GetSpellBookSkillLineInfo, line)
        if type(lineInfo) == "table" and lineInfo.itemIndexOffset and lineInfo.numSpellBookItems then
            for i = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
                local item = try("GetSpellBookItemInfo " .. i, C_SpellBook.GetSpellBookItemInfo, i, bank)
                if type(item) == "table" and item.spellID then
                    local rec = spellRecord(item.spellID)
                    rec.tab = clean(lineInfo.name)
                    rec.bookName = clean(item.name)
                    rec.bookSubName = clean(item.subName)
                    rec.isPassive = clean(item.isPassive)
                    rec.isOffSpec = clean(item.isOffSpec)
                    if C_SpellBook.IsSpellBookItemLowRank then
                        rec.isLowRank = clean(try("IsSpellBookItemLowRank " .. i, C_SpellBook.IsSpellBookItemLowRank, i, bank))
                    end
                    list[#list + 1] = rec
                end
            end
        end
    end
    return list
end

---------------------------------------------------------------------------
-- Talents (Forever uses the retail "trait" system for its talent trees)
---------------------------------------------------------------------------

local function exportTalents()
    local out = {}
    if not (C_Traits and C_Traits.GetConfigInfo and C_ClassTalents) then
        errors[#errors + 1] = "talents: C_Traits or C_ClassTalents missing"
        return out
    end
    local configID = try("GetActiveConfigID", C_ClassTalents.GetActiveConfigID)
    if not configID then
        errors[#errors + 1] = "talents: no active talent config"
        return out
    end
    out.configID = configID
    local config = try("GetConfigInfo", C_Traits.GetConfigInfo, configID)
    if type(config) ~= "table" then return out end
    out.name = clean(config.name)
    out.trees = {}

    for _, treeID in ipairs(config.treeIDs or {}) do
        local tree = { id = treeID, nodes = {} }
        tree.currency = try("GetTreeCurrencyInfo", C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
        local nodeIDs = try("GetTreeNodes " .. treeID, C_Traits.GetTreeNodes, treeID) or {}
        for _, nodeID in ipairs(nodeIDs) do
            local node = try("GetNodeInfo " .. nodeID, C_Traits.GetNodeInfo, configID, nodeID)
            if type(node) == "table" and node.ID and node.ID ~= 0 then
                local n = {
                    id = nodeID, x = clean(node.posX), y = clean(node.posY),
                    currentRank = clean(node.currentRank), ranksPurchased = clean(node.ranksPurchased),
                    maxRanks = clean(node.maxRanks), isAvailable = clean(node.isAvailable),
                    isVisible = clean(node.isVisible), entries = {},
                }
                for _, entryID in ipairs(node.entryIDs or {}) do
                    local e = { id = entryID }
                    local entry = try("GetEntryInfo " .. entryID, C_Traits.GetEntryInfo, configID, entryID)
                    if type(entry) == "table" then
                        e.maxRanks = clean(entry.maxRanks)
                        local def = entry.definitionID and try("GetDefinitionInfo", C_Traits.GetDefinitionInfo, entry.definitionID)
                        if type(def) == "table" then
                            e.overrideName = clean(def.overrideName)
                            e.overrideDescription = stripCodes(clean(def.overrideDescription))
                            if def.spellID then e.spell = spellRecord(def.spellID) end
                        end
                    end
                    -- One tooltip per rank, so we can see e.g. 3% / 6% / 10%.
                    local maxRanks = tonumber(e.maxRanks) or tonumber(n.maxRanks) or 1
                    e.rankTooltips = {}
                    for rank = 1, maxRanks do
                        e.rankTooltips[rank] = tooltip("tooltip talent " .. entryID .. " rank " .. rank,
                            C_TooltipInfo and C_TooltipInfo.GetTraitEntry, entryID, rank)
                    end
                    n.entries[#n.entries + 1] = e
                end
                tree.nodes[#tree.nodes + 1] = n
            end
        end
        out.trees[#out.trees + 1] = tree
    end
    return out
end

---------------------------------------------------------------------------
-- Stats
---------------------------------------------------------------------------

local SCHOOLS = { "Physical", "Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane" }
local PRIMARY = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }

local function exportStats()
    local s = {}
    if C_Secrets and C_Secrets.ShouldUnitStatsBeSecret then
        s.statsAreSecret = clean(try("ShouldUnitStatsBeSecret", C_Secrets.ShouldUnitStatsBeSecret, "player"))
    end

    -- UnitStat returns: base, total, bonus, penalty
    s.primary = {}
    for i, name in ipairs(PRIMARY) do
        s.primary[name] = values("UnitStat " .. name, UnitStat, "player", i)
    end

    s.health = values("UnitHealthMax", UnitHealthMax, "player")
    s.mana = values("UnitPowerMax mana", UnitPowerMax, "player", 0)
    s.manaRegen = values("GetManaRegen", GetManaRegen)          -- not casting, casting
    s.powerRegen = values("GetPowerRegen", GetPowerRegen)

    s.spellDamage, s.spellCrit = {}, {}
    for i, name in ipairs(SCHOOLS) do
        s.spellDamage[name] = values("GetSpellBonusDamage " .. name, GetSpellBonusDamage, i)
        s.spellCrit[name] = values("GetSpellCritChance " .. name, GetSpellCritChance, i)
    end
    s.healing = values("GetSpellBonusHealing", GetSpellBonusHealing)

    s.meleeCrit = values("GetCritChance", GetCritChance)
    s.rangedCrit = values("GetRangedCritChance", GetRangedCritChance)
    s.meleeHit = values("GetHitModifier", GetHitModifier)
    s.spellHit = values("GetSpellHitModifier", GetSpellHitModifier)
    s.expertise = values("GetExpertise", GetExpertise)
    s.spellPenetration = values("GetSpellPenetration", GetSpellPenetration)

    s.haste = values("GetHaste", GetHaste)
    s.meleeHaste = values("GetMeleeHaste", GetMeleeHaste)
    s.rangedHaste = values("GetRangedHaste", GetRangedHaste)
    s.spellHaste = values("UnitSpellHaste", UnitSpellHaste, "player")

    s.attackPower = values("UnitAttackPower", UnitAttackPower, "player")    -- base, bonus, penalty
    s.weaponDamage = values("UnitDamage", UnitDamage, "player")            -- min, max, offMin, offMax, bonus, penalty, percent
    s.attackSpeed = values("UnitAttackSpeed", UnitAttackSpeed, "player")    -- main hand, off hand

    s.armor = values("UnitArmor", UnitArmor, "player")
    s.dodge = values("GetDodgeChance", GetDodgeChance)
    s.parry = values("GetParryChance", GetParryChance)
    s.block = values("GetBlockChance", GetBlockChance)
    s.resistances = {}
    for i = 2, 6 do
        s.resistances[SCHOOLS[i + 1] or tostring(i)] = values("UnitResistance " .. i, UnitResistance, "player", i)
    end
    return s
end

---------------------------------------------------------------------------
-- Gear, weapon buffs, totems, buffs on you
---------------------------------------------------------------------------

local function exportGear()
    local gear = {}
    for slot = 1, 19 do
        local link = try("GetInventoryItemLink " .. slot, GetInventoryItemLink, "player", slot)
        if link then
            local g = { slot = slot, link = clean(link) }
            g.itemID = clean(try("GetInventoryItemID " .. slot, GetInventoryItemID, "player", slot))
            if C_Item and C_Item.GetItemStats then
                g.stats = try("GetItemStats " .. slot, C_Item.GetItemStats, link)
            end
            g.tooltip = tooltip("tooltip gear " .. slot, C_TooltipInfo and C_TooltipInfo.GetInventoryItem, "player", slot)
            gear[#gear + 1] = g
        end
    end
    return gear
end

local function exportTotems()
    local totems = {}
    for slot = 1, 4 do
        totems[slot] = values("GetTotemInfo " .. slot, GetTotemInfo, slot)  -- haveTotem, name, start, duration, icon
    end
    return totems
end

local function exportAuras()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local secret = try("ShouldAurasBeSecret", C_Secrets.ShouldAurasBeSecret)
        if secret then return { skipped = "auras are secret right now" } end
    end
    local auras = {}
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return auras end
    for i = 1, 40 do
        local a = try("GetAuraDataByIndex " .. i, C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if type(a) ~= "table" then break end
        auras[#auras + 1] = {
            name = clean(a.name), spellID = clean(a.spellId), duration = clean(a.duration),
            stacks = clean(a.applications),
            tooltip = tooltip("tooltip aura " .. i, C_TooltipInfo and C_TooltipInfo.GetUnitAura, "player", i, "HELPFUL"),
        }
    end
    return auras
end

---------------------------------------------------------------------------
-- Class trainer: saved automatically every time you open the trainer
---------------------------------------------------------------------------

local function exportTrainer()
    if not GetNumTrainerServices then return end
    errors = {}
    missingText = 0
    -- Show every service, including ones you already know or can't learn yet.
    if SetTrainerServiceTypeFilter then
        pcall(SetTrainerServiceTypeFilter, "available", 1)
        pcall(SetTrainerServiceTypeFilter, "unavailable", 1)
        pcall(SetTrainerServiceTypeFilter, "used", 1)
    end
    local services = {}
    local num = try("GetNumTrainerServices", GetNumTrainerServices) or 0
    for i = 1, num do
        local name, rank, category = try("GetTrainerServiceInfo " .. i, GetTrainerServiceInfo, i)
        if name then
            services[#services + 1] = {
                name = clean(name), rank = clean(rank), status = clean(category),
                cost = clean(try("GetTrainerServiceCost " .. i, GetTrainerServiceCost, i)),
                levelReq = clean(try("GetTrainerServiceLevelReq " .. i, GetTrainerServiceLevelReq, i)),
                tooltip = tooltip("tooltip trainer " .. i, C_TooltipInfo and C_TooltipInfo.GetTrainerService, i),
            }
        end
    end
    local db = getDB()
    local npc = clean(try("UnitName npc", UnitName, "npc")) or "trainer"
    if type(npc) ~= "string" then npc = "trainer" end
    db.trainers[npc] = { savedAt = date("%Y-%m-%d %H:%M:%S"), services = services, errors = errors }
    say(("saved %d trainer entries from %s. Type /reload when you're done to write the file."):format(#services, npc))
end

---------------------------------------------------------------------------
-- Main export
---------------------------------------------------------------------------

local function exportAll(label, quiet)
    errors = {}
    missingText = 0
    local version, build, buildDate, interface = GetBuildInfo()
    local _, classFile = UnitClass("player")
    local data = {
        exporterVersion = VERSION,
        savedAt = date("%Y-%m-%d %H:%M:%S"),
        game = { version = version, build = build, buildDate = buildDate, interface = interface,
                 locale = GetLocale and GetLocale() },
        player = {
            name = clean(UnitName("player")), realm = GetRealmName and clean(GetRealmName()),
            race = clean((UnitRace("player"))), class = classFile, level = UnitLevel("player"),
        },
    }
    data.stats = exportStats()
    data.weaponBuffs = values("GetWeaponEnchantInfo", GetWeaponEnchantInfo)
    data.totems = exportTotems()
    data.buffs = exportAuras()
    data.gear = exportGear()
    data.spellbook = exportSpellbook()
    data.talents = exportTalents()
    data.missingTooltipText = missingText
    data.errors = errors

    getDB().exports[label] = data
    if not quiet then
        say(("saved '%s': %d spells, %d gear items, %d problems noted."):format(
            label, #data.spellbook, #data.gear, #errors))
    end
    return data
end

local function startExport(label)
    if InCombatLockdown and InCombatLockdown() then
        say("please leave combat first, then try again.")
        return
    end
    say("reading your character...")
    exportAll(label, true)
    -- Tooltip text loads in the background, so do a second pass a moment later.
    C_Timer.After(3, function()
        local data = exportAll(label, false)
        if data.missingTooltipText > 0 then
            say(("%d spells had no text yet. Wait a few seconds and type /esx %s again."):format(
                data.missingTooltipText, label))
        else
            say("all done! Type /reload to write the file.")
        end
    end)
end

SLASH_EARTHENSHRINKEXPORT1 = "/esx"
SlashCmdList.EARTHENSHRINKEXPORT = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "status" then
        local db = getDB()
        local n = 0
        for label, data in pairs(db.exports) do
            n = n + 1
            say(("'%s' saved at %s"):format(label, data.savedAt or "?"))
        end
        for npc in pairs(db.trainers) do say("trainer: " .. npc) end
        if n == 0 then say("nothing saved yet. Type /esx to start.") end
        return
    end
    startExport(msg ~= "" and msg or "default")
end

local frame = CreateFrame("Frame")
local function listen(event)
    -- Registering an event this client doesn't know throws an error.
    pcall(frame.RegisterEvent, frame, event)
end
listen("ADDON_LOADED")
listen("TRAINER_SHOW")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        getDB()
        say("loaded. Type /esx to save your character's data.")
    elseif event == "TRAINER_SHOW" then
        -- Give the trainer window a moment to fill in.
        C_Timer.After(1, exportTrainer)
    end
end)
