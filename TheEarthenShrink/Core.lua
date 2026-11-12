-- The Earthen Shrink: Core
-- Starts the addon, holds shared helpers, listens for game events and
-- handles the /es slash command.
--
-- Every file in this addon gets the same "ns" table (short for namespace).
-- Think of it like a static class in C# that every file can add methods to.

local ADDON, ns = ...
ns.VERSION = "0.11.1"

---------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------

function ns.say(msg)
    print("|cff3fc7ebThe Earthen Shrink:|r " .. tostring(msg))
end

-- Numbers can be "secret" in combat on this client. A secret number can be
-- shown but not used in math, so we treat it as missing.
function ns.clean(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

-- Calls a game function safely. Returns nil instead of throwing an error
-- if the function is missing or fails (like a try/catch in C#).
function ns.try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g
end

-- Formats a number with a fixed number of decimals: ns.fmt(3.14159, 2) -> "3.14"
function ns.fmt(v, decimals)
    if type(v) ~= "number" then return "?" end
    decimals = decimals or 0
    local s = string.format("%." .. decimals .. "f", v)
    -- add thousands separators: 12345 -> 12,345
    local int, rest = s:match("^(-?%d+)(.*)$")
    if int then
        int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^(-?),", "%1")
        s = int .. rest
    end
    return s
end

function ns.inCombat()
    return InCombatLockdown and InCombatLockdown()
end

---------------------------------------------------------------------------
-- Saved settings
---------------------------------------------------------------------------

local DEFAULTS = {
    -- True when spell tooltips already include your spell power. Angel saw
    -- this in Forever (2026-11-12), so it's on. See "/es sptooltip".
    tooltipIncludesSpellPower = true,
    -- Ranks and levels learned from the class trainer window (real Forever data).
    trainer = {},
    -- Play a sound when Windfury procs. Switch with /es sound.
    windfurySound = true,
    -- Sim Lab (v0.9 and older): Mental Dexterity tick and Mental Quickness
    -- points. Only read once, to carry them over into simTalents.
    simMentalDex = false,
    simMentalQuick = nil,
    -- Sim Lab talents you changed: simTalents.MD = { points = 2, off = true }.
    -- Empty = use the talents your character really has.
    simTalents = {},
    -- Sim Lab: how you play ("enh", "ele" or "resto"), fight length in
    -- seconds, and whether Flame Shock is part of your mix.
    simStyle = "enh",
    -- Fight length in seconds (10 to 30: solo questing, Angel 2026-11-12).
    simFight = 20,
    -- Who the Sim Lab fights: "same" (a mob your level) or "boss" (+3 levels).
    simTarget = "same",
    simUseFlameShock = true,

    -- Weapon buff comparison settings (change them on the Weapon Buffs tab).
    -- Is a Shaman putting down Windfury Totem in your group?
    wfTotem = false,
    -- Do Windfury Totem and Windfury Weapon both work at once? The tooltip
    -- says no, but a hotfix (Nov 2026) is changing it so they stack.
    wfStacks = true,
    -- Is Flametongue Totem down in your group? And does it stack with
    -- Flametongue Weapon? 🔶 Blizzard's notes say weapon buffs stack with
    -- totems (Windfury was the example); not tested for Flametongue.
    ftTotem = false,
    ftStacks = true,
    -- 🔶 UNVERIFIED: how much of your Fire spell power Flametongue adds to
    -- each hit (0.1 = 10%). 0 until someone tests it in Forever.
    ftCoef = 0,
    -- How many main-hand swings the comparison simulates.
    swings = 50,

    -- Spell Power Test tab: your Before/After hit lists, saved results,
    -- ticks per cast, and which box typed numbers go into.
    coefTests = {},
    coefSaved = {},
    coefTicks = {},
    coefActive = "before",

    -- Minimap button: where it sits (angle), and if it's hidden or locked.
    -- Change it by right-clicking the button, or with /es minimap.
    minimap = {},

    -- Window size from the corner grip (1 = normal).
    windowScale = 1,
    -- Spells and Healing tabs: which spells are folded up, like
    -- collapsed.spells.LB = true.
    collapsed = {},
    -- Sim Lab: which view is open ("total", "weights", "spells", "weapon", "stats").
    simView = "total",
}

function ns.db()
    EarthenShrinkDB = EarthenShrinkDB or {}
    for k, v in pairs(DEFAULTS) do
        if EarthenShrinkDB[k] == nil then
            EarthenShrinkDB[k] = type(v) == "table" and {} or v
        end
    end
    return EarthenShrinkDB
end

---------------------------------------------------------------------------
-- Events: other files call ns.on("EVENT_NAME", function(...) end)
---------------------------------------------------------------------------

local handlers = {}
local eventFrame = CreateFrame("Frame")

function ns.on(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        -- Registering an event this client doesn't know throws an error.
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
    table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    for _, fn in ipairs(handlers[event] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then ns.say("|cffff4a3aerror in " .. event .. ":|r " .. tostring(err)) end
    end
end)

-- "Something changed, redraw the window" signal. The window listens to it.
local listeners = {}
function ns.onRefresh(fn) table.insert(listeners, fn) end
function ns.refresh(reason)
    for _, fn in ipairs(listeners) do pcall(fn, reason) end
end

ns.on("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    local db = ns.db()
    -- v0.7.0: Angel saw Forever's tooltips (Lightning Bolt, Flametongue) go
    -- up with spell power, so switch this on once. /es sptooltip off undoes it.
    if not db.migratedSpTooltip07 then
        db.tooltipIncludesSpellPower = true
        db.migratedSpTooltip07 = true
    end
    if ns.SpellData then ns.SpellData.Init() end
    ns.say("loaded. Type |cffffd100/es|r to open.")
end)

-- Stats change when you level, change gear, or learn spells.
for _, ev in ipairs({ "PLAYER_LEVEL_UP", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED",
                      "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_REGEN_ENABLED",
                      "UNIT_MAXPOWER" }) do
    ns.on(ev, function(unit)
        if (ev == "UNIT_INVENTORY_CHANGED" or ev == "UNIT_MAXPOWER") and unit ~= "player" then return end
        ns.refresh(ev)
    end)
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

SLASH_THEEARTHENSHRINK1 = "/es"
SLASH_THEEARTHENSHRINK2 = "/shrink"
SlashCmdList.THEEARTHENSHRINK = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        ns.UI.Toggle()
    elseif msg == "sim" or msg == "simlab" then
        ns.UI.Show("simlab")
    elseif msg == "test" or msg == "sptest" or msg == "coef" then
        ns.UI.Show("coef")
    elseif msg == "changes" then
        ns.GameCheck.Print()
    elseif msg == "meter" then
        ns.CoefTest.DumpMeter()
    elseif msg == "spells" or msg == "weapon" or msg == "inspect" or msg == "totems" or msg == "healing" then
        ns.UI.Show(msg)
        if msg == "inspect" then ns.Inspect.Start("target") end
    elseif msg:match("^sptooltip") then
        local db = ns.db()
        local arg = msg:match("^sptooltip%s+(%a+)")
        if arg == "on" then db.tooltipIncludesSpellPower = true
        elseif arg == "off" then db.tooltipIncludesSpellPower = false end
        ns.say("spell tooltips include spell power: " .. (db.tooltipIncludesSpellPower and "|cff1eff00yes|r" or "|cffff4a3ano|r")
            .. ". Change with /es sptooltip on or /es sptooltip off.")
        ns.refresh("settings")
    elseif msg == "sound" or msg:match("^sound%s") then
        ns.Windfury.Slash(msg:match("^sound%s+(%a+)"))
    elseif msg:match("^wftotem") or msg:match("^wfstack") or msg:match("^fttotem") or msg:match("^ftstack") or msg:match("^ftcoef") or msg:match("^swings") then
        ns.ImbueMath.Slash(msg)
    elseif msg == "minimap" or msg:match("^minimap%s") then
        ns.Minimap.Slash(msg:match("^minimap%s+(%a+)"))
    elseif msg == "talents" then
        ns.TalentMods.Print()
    elseif msg == "check" then
        ns.SpellData.PrintCheck()
    else
        ns.say("commands: /es (open), /es spells, /es weapon, /es totems, /es healing, /es sim, /es test, /es meter, /es changes, /es talents, /es inspect, /es check, /es minimap, /es minimap reset, /es sound, /es sound test, /es sptooltip on|off, /es wftotem on|off, /es wfstack on|off, /es fttotem on|off, /es ftstack on|off, /es ftcoef 0.1, /es swings 50")
    end
end
