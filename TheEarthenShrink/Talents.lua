-- The Earthen Shrink: reading your talents
--
-- We try two ways to find how many points you have in a talent, by name:
--   1. GetTalentInfo (the old Classic way), if this client has it.
--   2. C_Traits (the new retail way), which Forever's client is based on.
-- If neither works, we return nil and the Sim Lab uses the setting you pick.
-- Nothing here is tested in Forever yet.

local _, ns = ...
local TL = {}
ns.Talents = TL

local function viaClassic(name)
    if not (GetNumTalentTabs and GetNumTalents and GetTalentInfo) then return nil end
    for tab = 1, (ns.try(GetNumTalentTabs) or 0) do
        for i = 1, (ns.try(GetNumTalents, tab) or 0) do
            local tName, _, _, _, rank, maxRank = ns.try(GetTalentInfo, tab, i)
            if tName == name then return rank or 0, maxRank end
        end
    end
    return nil
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then return ns.try(C_Spell.GetSpellName, id) end
    local info = C_Spell and ns.try(C_Spell.GetSpellInfo, id)
    return type(info) == "table" and info.name or nil
end

-- The talent trees to look through. For YOUR talents that's your active
-- set. For a player you just inspected the game uses a special set number
-- (the same one Blizzard's own inspect window uses). 🔶 Untested in Forever.
local INSPECT_CONFIG = Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1

local function configAndTrees(unit)
    if not (C_Traits and C_Traits.GetConfigInfo) then return nil end
    local config
    if unit and unit ~= "player" then
        if C_Traits.HasValidInspectData and not ns.try(C_Traits.HasValidInspectData) then return nil end
        config = INSPECT_CONFIG
    else
        config = C_ClassTalents and ns.try(C_ClassTalents.GetActiveConfigID)
    end
    if not config then return nil end
    local info = ns.try(C_Traits.GetConfigInfo, config)
    local trees = type(info) == "table" and type(info.treeIDs) == "table" and info.treeIDs or nil
    -- Inspected players: if the set has no tree list, ask for their spec's tree.
    if not trees and unit and unit ~= "player" and GetInspectSpecialization and C_ClassTalents and C_ClassTalents.GetTraitTreeForSpec then
        local spec = ns.try(GetInspectSpecialization, unit)
        local tree = spec and ns.try(C_ClassTalents.GetTraitTreeForSpec, spec)
        if tree then trees = { tree } end
    end
    if not trees then return nil end
    return config, trees
end

local function viaTraits(name, unit)
    local config, trees = configAndTrees(unit)
    if not config then return nil end
    for _, tree in ipairs(trees) do
        for _, node in ipairs(ns.try(C_Traits.GetTreeNodes, tree) or {}) do
            local n = ns.try(C_Traits.GetNodeInfo, config, node)
            if type(n) == "table" and type(n.entryIDs) == "table" then
                for _, entry in ipairs(n.entryIDs) do
                    local e = ns.try(C_Traits.GetEntryInfo, config, entry)
                    local def = e and e.definitionID and ns.try(C_Traits.GetDefinitionInfo, e.definitionID)
                    if def and def.spellID and spellName(def.spellID) == name then
                        local active = n.activeEntry and n.activeEntry.entryID == entry
                        return active and (n.activeRank or n.currentRank or 0) or 0, n.maxRanks, def.spellID
                    end
                end
            end
        end
    end
    return nil
end

-- The talent's tooltip text, or nil if the addon can't find it.
function TL.Description(name)
    local _, _, id = viaTraits(name)
    if not id and C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
        id = ns.try(C_Spell.GetSpellIDForSpellIdentifier, name)
    end
    if not id then return nil end
    local text = C_Spell and ns.try(C_Spell.GetSpellDescription, id)
    return ns.clean(text)
end

-- Points you have in a talent, or nil if the addon can't tell.
-- unit = nil for you, or an inspected player's unit (only works right after
-- the game sends their inspect data).
function TL.Rank(name, unit)
    if unit and unit ~= "player" then return viaTraits(name, unit) end
    local r, max = viaClassic(name)
    if r == nil then r, max = viaTraits(name) end
    return r, max
end
