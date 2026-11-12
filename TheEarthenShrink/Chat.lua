-- The Earthen Shrink: the short message you can post in chat
--
-- WoW chat messages can be at most 255 characters, so the message is one
-- line: the ranking, a plain sentence on why the winner wins, and which
-- talents were counted. Bits are dropped if it gets too long.

local _, ns = ...
local C = {}
ns.Chat = C

C.MAX = 255

local SHORT = { RB = "Rockbiter", FT = "Flametongue", FB = "Frostbrand", WF = "Windfury" }

-- Talents that change these numbers, said plainly:
-- "Talents counted: Mental Dexterity 3, no Elemental Weapons."
-- size "mid" gives "Talents: Mental Dexterity 3, Elemental Weapons 0" and
-- "short" gives "Talents: MD 3, EW 0" when the message is too long.
C.TALENTS = { { "Mental Dexterity", "MD" }, { "Elemental Weapons", "EW" }, { "Mental Quickness", "MQ" }, { "Spirit Weapons", "SW" } }

function C.TalentText(p, size)
    local short = size == "short"
    local TM = ns.TalentMods
    local points
    if p.source == "inspect" then
        if p.talentsUnknown then return short and "Talents: unknown." or "Talents: couldn't read them, counted as none." end
        points = p.talentPoints or {}
    else
        points = TM and TM.RealPoints()
        if not points then return short and "Talents: unknown." or "Talents: couldn't read them." end
    end
    -- Spirit Weapons only when it matters (you or they have it, or the
    -- addon read that it changes a buff).
    local swMatters = (points["Spirit Weapons"] or 0) > 0
    for _, n in ipairs(TM and TM.TalentNames() or {}) do if n == "Spirit Weapons" then swMatters = true end end
    local parts = {}
    for _, t in ipairs(C.TALENTS) do
        if t[1] ~= "Spirit Weapons" or swMatters then
            local n = points[t[1]] or 0
            if short then
                parts[#parts + 1] = t[2] .. " " .. n
            elseif size == "mid" then
                parts[#parts + 1] = t[1] .. " " .. n
            else
                parts[#parts + 1] = n > 0 and (t[1] .. " " .. n) or ("no " .. t[1])
            end
        end
    end
    return (size and "Talents: " or "Talents counted: ") .. table.concat(parts, ", ") .. "."
end

-- One plain sentence on why the best buff wins, from the real numbers.
function C.Reason(p, list)
    local best, second, ft
    for _, e in ipairs(list) do
        if e.calc then
            if not best then best = e elseif not second then second = e end
            if e.key == "FT" then ft = e end
        end
    end
    if not best then return nil end
    local w = p.weapon or {}
    local intro = ""
    if best.key == "WF" and w.speed then
        intro = (" (%s speed weapon)"):format(ns.fmt(w.speed, 1))
    end
    local why
    if second then
        why = ("Why: %s%s wins, %s beats %s's %s."):format(SHORT[best.key], intro, best.calc.plain or "its bonus",
            SHORT[second.key], second.calc.plain or "bonus")
    else
        why = ("Why: %s is the only buff the addon could work out."):format(SHORT[best.key])
    end
    -- Flametongue gets stronger with spell power (only said when your SP
    -- Test or setting gives it a spell power share).
    local hint
    if ft and ft ~= best and ft.calc.spPerDps and ft.calc.spPerDps > 0 then
        local need = (best.calc.dps - ft.calc.dps) / ft.calc.spPerDps
        hint = (" Flametongue needs about +%s spell power to catch up."):format(ns.fmt(math.ceil(need)))
    end
    return why, hint
end

function C.Build(p, list)
    local parts = {}
    for _, e in ipairs(list) do
        if e.calc then
            -- "Windfury +17.5 DPS > Rockbiter +10.4 > ..." (DPS said once, to
            -- leave room in the 255 letters for the why and the talents)
            parts[#parts + 1] = ("%s +%s%s"):format(SHORT[e.key], ns.fmt(e.calc.dps, 1), #parts == 0 and " DPS" or "")
        end
    end
    if #parts == 0 then return nil end
    local head = ("[Earthen Shrink] %s (lvl %d): %s."):format(p.name or "?", p.level or 0, table.concat(parts, " > "))
    local why, hint = C.Reason(p, list)
    local note = p.source == "inspect" and " (gear estimate)" or ""
    local talents, talentsMid, talentsShort = " " .. C.TalentText(p), " " .. C.TalentText(p, "mid"), " " .. C.TalentText(p, "short")
    -- Longest first; drop the least important bits until it fits in chat.
    local tries = {
        { head, " ", why, hint or "", talents, note },
        { head, " ", why, talents, note },
        { head, " ", why, talentsMid, note },
        { head, " ", why, talentsShort, note },
        { head, " ", why, note },
        { head, talentsShort, note },
        { head, note },
    }
    for _, t in ipairs(tries) do
        local msg = table.concat(t)
        if #msg <= C.MAX then return msg end
    end
    return (head .. note):sub(1, C.MAX)
end

-- Puts the message in your chat box. You choose where it goes (say, party,
-- whisper) and press Enter yourself, so nothing is sent without you.
function C.OpenInChatBox(msg)
    if not msg then return end
    local opened = false
    if ChatFrameUtil and ChatFrameUtil.OpenChat then
        opened = pcall(ChatFrameUtil.OpenChat, msg)
    end
    if not opened and ChatFrame_OpenChat then
        opened = pcall(ChatFrame_OpenChat, msg)
    end
    if not opened then
        ns.say("couldn't open the chat box. Here's the message to copy:")
        print(msg)
    end
end
