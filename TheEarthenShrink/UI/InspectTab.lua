-- The Earthen Shrink: Inspect tab
--
-- Target another player, press Inspect, and see which Shaman weapon buff is
-- best for them, based on the gear they're wearing. "Post to chat" puts a
-- short summary with the formula in your chat box.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.inspect = T
local f = function(...) return ns.fmt(...) end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    page.list = W.List(page, width, 300, { { title = "Rank", width = 60 }, { title = "+DPS", width = 70 } }, 2)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Buff")

    page.status = W.Text(page, "GameFontHighlightSmall", nil, "LEFT")
    page.status:SetPoint("TOPLEFT", page.list.frame, "BOTTOMLEFT", 0, -6)
    page.status:SetPoint("RIGHT", 0, 0)

    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -320, 0)
    page.note:SetText("Their stats are estimated from their gear and level. Talents: theirs, not yours.")

    page.inspect = W.Button(page, "Inspect target", 150)
    page.inspect:SetPoint("BOTTOMRIGHT", -158, 0)
    page.inspect:SetScript("OnClick", function() ns.Inspect.Start("target") end)

    page.post = W.Button(page, "Post to chat", 150)
    page.post:SetPoint("BOTTOMRIGHT", 0, 0)
    page.post:SetScript("OnClick", function()
        if page.message then ns.Chat.OpenInChatBox(page.message) end
    end)
end

function T.Update(page)
    page.status:SetText(ns.Inspect.status or "")
    local p = ns.Inspect.profile
    if not p then
        page.chips[1]:Set("Player", "-")
        page.chips[2]:Set("Best weapon buff", "-")
        page.chips[3]:Set("Main hand", "-")
        page.list:SetRows({ { header = "Target a player and press Inspect target" } })
        page.message = nil
        page.post:Disable()
        return
    end
    local list = ns.ImbueMath.Compare(p)
    local best = list[1]
    page.chips[1]:Set("Player", ("%s (%d)"):format(p.name or "?", p.level or 0))
    page.chips[2]:Set("Best weapon buff", best and best.calc and (best.name:gsub(" Weapon", "") .. " +" .. f(best.calc.dps, 1) .. " DPS") or "-",
        best and best.calc and W.GREEN or nil)
    local w = p.weapon
    page.chips[3]:Set("Main hand", w and w.min and (f(w.min) .. "-" .. f(w.max) .. " @ " .. f(w.speed or 0, 2)) or "no weapon")

    local rows = ns.ImbueRows(p, list)
    for _, r in ipairs(ns.ProfileRows(p)) do rows[#rows + 1] = r end
    if p.talentsUnknown then
        rows[#rows + 1] = { header = "Couldn't read their talents: counted as none (see the talents row)" }
    end
    rows[#rows + 1] = { header = "Group buffs (other totems, food) aren't counted for inspected players yet" }
    page.list:SetRows(rows)

    page.message = ns.Chat.Build(p, list)
    if page.message then page.post:Enable() else page.post:Disable() end
end
