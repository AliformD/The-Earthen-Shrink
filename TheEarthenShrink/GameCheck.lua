-- The Earthen Shrink: "what changed in the game?"
--
-- Blizzard changes Forever with hotfixes (Stormstrike, Mental Dexterity,
-- Windfury...). The addon's math depends on those numbers, so each time you
-- log in it saves the tooltips it depends on, and if one is different from
-- last time it prints a list in chat: "these changed since your last check".
--
-- Only tooltips that DON'T change with your gear or level are saved (Lightning Bolt
-- and Flametongue go up with spell power, so they would "change" every
-- time you swap gear). Type /es changes to see the saved values.

local _, ns = ...
local G = {}
ns.GameCheck = G

-- Spells whose tooltip text we watch (your highest rank).
-- (Frostbrand and Lightning Shield do spell damage, so their tooltips
-- probably change with your gear; they're left out.)
G.WATCH = { "SS", "WF", "WFT", "RB" }
-- Talents whose text we watch (only if the game lets us read it).
G.TALENTS = { "Mental Dexterity", "Mental Quickness", "Elemental Weapons", "Spirit Weapons" }
G.TALENT_POINTS = "Your points in talents that change tooltips"

local function build()
    local version, b = ns.try(GetBuildInfo)
    return version and (tostring(version) .. " (" .. tostring(b) .. ")") or "?"
end

-- Reads every watched value right now. Returns { [label] = text }.
function G.Read()
    local out = {}
    local level = UnitLevel("player") or 1
    for _, key in ipairs(G.WATCH) do
        local spell = ns.RANKS_BY_KEY[key]
        local rank = spell and ns.SpellData.Best(key, level)
        if rank and rank.desc and rank.desc ~= "" then
            local label = ("%s rank %d"):format(spell.name, rank.rank)
            out[label .. " tooltip"] = rank.desc
            if rank.cooldown then out[label .. " cooldown"] = ns.fmt(rank.cooldown) .. " sec" end
        end
    end
    for _, name in ipairs(G.TALENTS) do
        local text = ns.Talents and ns.Talents.Description(name)
        if text and text ~= "" then out[name .. " talent"] = text end
    end
    -- Your points in talents that change these tooltips. If you spend a
    -- point in Elemental Weapons, Rockbiter's tooltip changes, and that's
    -- not a hotfix, so we say so.
    local TM = ns.TalentMods
    if TM and not TM.Data().cantRead then
        local real, parts = TM.RealPoints() or {}, {}
        for _, n in ipairs(TM.TalentNames()) do parts[#parts + 1] = n .. " " .. (real[n] or 0) end
        if #parts > 0 then out[G.TALENT_POINTS] = table.concat(parts, ", ") end
    end
    return out
end

-- Compares with the saved values. Returns a list of { label, old, new }.
function G.Compare(old, now)
    local changes = {}
    for label, text in pairs(now) do
        if old[label] ~= nil and old[label] ~= text then
            changes[#changes + 1] = { label = label, old = old[label], new = text }
        end
    end
    table.sort(changes, function(a, b) return a.label < b.label end)
    return changes
end

-- Runs the check: prints what changed, then saves the new values.
-- quiet = don't print when nothing changed.
function G.Check(quiet)
    local db = ns.db()
    local saved = db.gameSnapshot or { values = {} }
    local now = G.Read()
    local changes = G.Compare(saved.values or {}, now)
    if #changes > 0 then
        ns.say(("|cffff8000%d game value(s) changed since your last check|r (%s, game %s):"):format(
            #changes, saved.date or "?", saved.build or "?"))
        for _, c in ipairs(changes) do
            print("  |cffffd100" .. c.label .. "|r")
            print("    was: |cff999999" .. tostring(c.old) .. "|r")
            print("    now: " .. tostring(c.new))
        end
        local talentsMoved = false
        for _, c in ipairs(changes) do if c.label == G.TALENT_POINTS then talentsMoved = true end end
        if talentsMoved then
            ns.say("your talent points changed too, so some tooltip changes may just be your talents, not a hotfix.")
        end
        ns.say("the math reads tooltips, so it already uses the new numbers. Please send a screenshot of this to the addon thread.")
    elseif not quiet then
        local n = 0
        for _ in pairs(now) do n = n + 1 end
        ns.say(("no changes in the %d game values the addon watches (last check %s)."):format(n, saved.date or "never"))
    end
    -- Keep values we couldn't read this time (like a talent you respecced out of).
    local values = saved.values or {}
    for label, text in pairs(now) do values[label] = text end
    db.gameSnapshot = { values = values, build = build(), date = date and date("%Y-%m-%d %H:%M") or "?" }
    return changes
end

-- /es changes: shows what's saved.
function G.Print()
    G.Check(false)
    local snap = ns.db().gameSnapshot
    local labels = {}
    for label in pairs(snap.values) do labels[#labels + 1] = label end
    table.sort(labels)
    for _, label in ipairs(labels) do print("  |cffffd100" .. label .. ":|r " .. snap.values[label]) end
end

-- After logging in, give the game a few seconds to send spell text.
ns.on("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(8, function() G.Check(true) end)
end)
