-- The Earthen Shrink: Windfury sound alert
-- Plays a sound when your Windfury procs (gives you extra attacks).
--
-- The game can tell us about a proc in two possible ways. We don't know yet
-- which one works on the Forever beta, so we try both:
--   Way 1: the combat log "SPELL_EXTRA_ATTACKS" event. Forever seems to hide
--          the combat log from addons, so this is probably switched off.
--   Way 2: the "UNIT_SPELLCAST_SUCCEEDED" event, if the game reports the
--          proc as a spell you used (in Classic it's called "Windfury Attack").
-- Type "/es sound test" in game to see which way works.

local _, ns = ...
local W = {}
ns.Windfury = W

-- Temporary test messages. Off unless you type /es sound test.
W.debug = false

-- 8960 is the game's number for the ready-check sound. SOUNDKIT is a list of
-- named sounds; if it is missing on this client we use the number directly.
local SOUND_ID = (SOUNDKIT and SOUNDKIT.READY_CHECK) or 8960

-- One proc gives two extra attacks, so the game may tell us twice.
-- We only play the sound once per this many seconds.
local GAP = 1
local lastPlay = 0

-- Prints a grey test message, but only while test mode is on.
local function note(msg)
    if W.debug then ns.say("|cff9d9d9d[sound test]|r " .. msg) end
end

-- Call this when a proc is seen. "how" says which way found it.
function W.Proc(how)
    note("|cff1eff00Windfury proc seen|r (found by: " .. how .. ")")
    if not ns.db().windfurySound then return end
    local now = GetTime()
    if now - lastPlay < GAP then return end
    lastPlay = now
    PlaySound(SOUND_ID, "Master")
end

---------------------------------------------------------------------------
-- Way 1: combat log
---------------------------------------------------------------------------

-- "missing" = the function doesn't exist, "blocked" = the game refused,
-- "on" = we are listening.
W.combatLog = "missing"

if type(CombatLogGetCurrentEventInfo) == "function" then
    local logFrame = CreateFrame("Frame")
    local ok = pcall(logFrame.RegisterEvent, logFrame, "COMBAT_LOG_EVENT_UNFILTERED")
    if ok then
        W.combatLog = "on"
        logFrame:SetScript("OnEvent", function()
            local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo()
            if subEvent == "SPELL_EXTRA_ATTACKS" and sourceGUID == UnitGUID("player") then
                W.Proc("combat log")
            end
        end)
    else
        W.combatLog = "blocked"
    end
end

---------------------------------------------------------------------------
-- Way 2: "you used a spell" event
---------------------------------------------------------------------------

ns.on("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
    if unit ~= "player" then return end
    local id = ns.clean(spellID)
    if not id then
        note("you used a spell, but the game hid which one (secret value).")
        return
    end
    local name = ns.clean(ns.try(C_Spell and C_Spell.GetSpellName, id))
    note("you used: " .. tostring(name) .. " (spell id " .. tostring(id) .. ")")
    -- "Windfury Weapon" (putting the buff on) and "Windfury Totem" are not procs.
    if name and name:find("Windfury") and not name:find("Weapon") and not name:find("Totem") then
        W.Proc("spell event")
    end
end)

---------------------------------------------------------------------------
-- /es sound and /es sound test
---------------------------------------------------------------------------

function W.Slash(arg)
    local db = ns.db()
    if arg == "test" then
        W.debug = not W.debug
        if not W.debug then
            ns.say("sound test mode |cffff4a3aoff|r.")
            return
        end
        local restricted = ns.try(C_CombatLog and C_CombatLog.IsCombatLogRestricted)
        ns.say("sound test mode |cff1eff00on|r. Playing the sound once now.")
        ns.say("  sound alert: " .. (db.windfurySound and "on" or "off"))
        ns.say("  way 1, combat log: " .. W.combatLog
            .. " (game says restricted: " .. tostring(restricted) .. ")")
        ns.say("  way 2, spell event: on")
        ns.say("Now hit a target dummy with Windfury on. Type /es sound test again to stop.")
        PlaySound(SOUND_ID, "Master")
        return
    end
    if arg == "on" then db.windfurySound = true
    elseif arg == "off" then db.windfurySound = false
    else db.windfurySound = not db.windfurySound end
    ns.say("Windfury sound: " .. (db.windfurySound and "|cff1eff00on|r" or "|cffff4a3aoff|r")
        .. ". Type /es sound to switch, or /es sound test to check it works.")
end
