-- The Earthen Shrink: Core
-- Starts the addon, holds shared helpers, listens for game events and
-- handles the /es slash command.
--
-- Every file in this addon gets the same "ns" table (short for namespace).
-- Think of it like a static class in C# that every file can add methods to.

local ADDON, ns = ...
ns.VERSION = "0.6.0"

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
    -- Set to true if your spell tooltips already include your spell power.
    -- (We don't know yet how Forever shows it. See "/es sptooltip".)
    tooltipIncludesSpellPower = false,
    -- Ranks and levels learned from the class trainer window (real Forever data).
    trainer = {},
    -- Play a sound when Windfury procs. Switch with /es sound.
    windfurySound = true,
    -- Sim Lab: count Intellect as attack power (Mental Dexterity talent).
    simMentalDex = false,

    -- Weapon buff comparison settings (change them on the Weapon Buffs tab).
    -- Is a Shaman putting down Windfury Totem in your group?
    wfTotem = false,
    -- Do Windfury Totem and Windfury Weapon both work at once? The tooltip
    -- says no, but a hotfix (Nov 2026) is changing it so they stack.
    wfStacks = true,
    -- 🔶 UNVERIFIED: how much of your Fire spell power Flametongue adds to
    -- each hit (0.1 = 10%). 0 until someone tests it in Forever.
    ftCoef = 0,
    -- How many main-hand swings the comparison simulates.
    swings = 50,
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
    ns.db()
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
    elseif msg:match("^wftotem") or msg:match("^wfstack") or msg:match("^ftcoef") or msg:match("^swings") then
        ns.ImbueMath.Slash(msg)
    elseif msg == "check" then
        ns.SpellData.PrintCheck()
    else
        ns.say("commands: /es (open), /es spells, /es weapon, /es totems, /es healing, /es sim, /es inspect, /es check, /es sound, /es sound test, /es sptooltip on|off, /es wftotem on|off, /es wfstack on|off, /es ftcoef 0.1, /es swings 50")
    end
end
