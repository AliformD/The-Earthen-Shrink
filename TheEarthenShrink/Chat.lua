-- The Earthen Shrink: the short message you can post in chat
--
-- WoW chat messages can be at most 255 characters, so the message is one
-- line: the ranking, then the formula for the winner.

local _, ns = ...
local C = {}
ns.Chat = C

C.MAX = 255

local SHORT = { RB = "Rockbiter", FT = "Flametongue", WF = "Windfury" }

function C.Build(p, list)
    local parts = {}
    for _, e in ipairs(list) do
        if e.calc then
            parts[#parts + 1] = ("%s R%d +%s DPS"):format(SHORT[e.key], e.rank.rank, ns.fmt(e.calc.dps, 1))
        end
    end
    if #parts == 0 then return nil end
    local best = list[1]
    local head = ("[Earthen Shrink] %s (lvl %d): %s."):format(p.name or "?", p.level or 0, table.concat(parts, " > "))
    local why = (" Why: %s = %s"):format(SHORT[best.key], best.calc.short or "")
    local note = p.source == "inspect" and " (est. from gear)" or ""
    local msg = head .. why .. note
    if #msg > C.MAX then msg = head .. note end
    if #msg > C.MAX then msg = msg:sub(1, C.MAX) end
    return msg
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
