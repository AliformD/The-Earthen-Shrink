-- The Earthen Shrink: Spell Power Test tab
--
-- Measures how much of your spell power each spell really gets in Forever.
--
--   Left:   the spells you can test. Pick one.
--   Top:    two boxes, BEFORE and AFTER. Click one to send numbers to it.
--   Middle: type the damage of each normal hit (not crits) and press Enter.
--   Bottom: the answer, how sure it is, and a button to save it.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.coef = T
local f = function(...) return ns.fmt(...) end

local RED = { 1, 0.29, 0.23 }
local YELLOW = { 1, 0.82, 0 }
local VERDICT = {
    good  = { "Good: you can trust this number.", W.GREEN },
    ok    = { "Okay: close. More hits will make it better.", YELLOW },
    rough = { "Too rough: needs more hits or a bigger spell power change.", RED },
    wait  = { "", W.GREY },
}

T.selected = nil   -- id of the picked test, like "LB:4:direct"
T.message = nil    -- last message under the typing box
T.messageColor = W.GREY

local function selectedTarget(list)
    for _, t in ipairs(list) do if t.id == T.selected then return t end end
    T.selected = list[1] and list[1].id or nil
    return list[1]
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

local function sampleBox(page, which, title, x, width)
    local box = W.Create("Button", nil, page, { "BackdropTemplate" })
    box:SetSize(width, 112)
    box:SetPoint("TOPLEFT", x, 0)
    if box.SetBackdrop then
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        box:SetBackdropColor(0.02, 0.03, 0.04, 0.9)
    end
    box.which = which
    box.title = W.Text(box, "GameFontNormal", nil, "LEFT")
    box.title:SetPoint("TOPLEFT", 10, -8)
    box.title:SetText(title)
    box.state = W.Text(box, "GameFontDisableSmall", nil, "RIGHT")
    box.state:SetPoint("TOPRIGHT", -10, -9)
    box.body = W.Text(box, "GameFontHighlight", nil, "LEFT")
    box.body:SetPoint("TOPLEFT", 10, -28)
    box.body:SetPoint("RIGHT", -10, 0)
    box.body:SetJustifyV("TOP")
    if box.body.SetSpacing then box.body:SetSpacing(2) end

    box.clear = W.Button(box, "Clear", 60)
    box.clear:SetHeight(18)
    box.clear:SetPoint("BOTTOMRIGHT", -6, 6)
    box.clear:SetScript("OnClick", function()
        local t = T.target
        if t then ns.CoefTest.Clear(t, which); T.message = nil; T.Update(page) end
    end)
    box:SetScript("OnClick", function()
        ns.CoefTest.SetActive(which)
        T.Update(page)
        if page.input.SetFocus then page.input:SetFocus() end
    end)
    box:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(which == "before"
            and "Your hits with the spell power you have now. Click here, then type the numbers."
            or "Your hits after you put on more spell power. Click here, then type the numbers.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    box:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return box
end

local function buildEntry(page, x, width)
    local box = W.Panel(page)
    box:SetSize(width, 74)
    box:SetPoint("TOPLEFT", x, -118)

    local label = W.Text(box, "GameFontNormalSmall", nil, "LEFT")
    label:SetPoint("TOPLEFT", 10, -7)
    label:SetPoint("RIGHT", -10, 0)
    page.entryLabel = label

    local input = W.Create("EditBox", nil, box, { "InputBoxTemplate" })
    input:SetSize(width - 120, 20)
    input:SetPoint("TOPLEFT", 16, -22)
    input:SetAutoFocus(false)
    if input.SetMaxLetters then input:SetMaxLetters(400) end
    input:SetScript("OnEnterPressed", function(self)
        T.Submit(page, self:GetText())
        self:SetText("")
    end)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    page.input = input

    local undo = W.Button(box, "Undo", 80)
    undo:SetHeight(20)
    undo:SetPoint("TOPRIGHT", -10, -22)
    undo:SetScript("OnClick", function()
        local t = T.target
        if not t then return end
        local v = ns.CoefTest.Undo(t)
        T.message = v and ("Took out " .. f(v) .. ".") or "Nothing to take out."
        T.messageColor = W.GREY
        T.Update(page)
    end)

    page.msg = W.Text(box, "GameFontHighlightSmall", nil, "LEFT")
    page.msg:SetPoint("BOTTOMLEFT", 10, 6)
    page.msg:SetPoint("RIGHT", -10, 0)

    -- Only shown if the game lets addons read the combat log.
    if ns.CoefTest.autoAvailable then
        local cb = W.Create("CheckButton", nil, box, { "UICheckButtonTemplate", "ChatConfigCheckButtonTemplate" })
        cb:SetSize(20, 20)
        cb:SetPoint("TOPRIGHT", -96, -21)
        cb:SetScript("OnClick", function(self) ns.CoefTest.autoOn = self:GetChecked() and true or false; T.Update(page) end)
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Record my hits by itself", 1, 1, 1)
            GameTooltip:AddLine("Adds every normal hit of the picked spell to the box you clicked. Crits and resisted hits are left out.", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        page.auto = cb
    end
end

local function buildResult(page, x, width)
    local box = W.Panel(page)
    box:SetSize(width, 228)
    box:SetPoint("TOPLEFT", x, -198)
    page.result = box

    local title = W.Text(box, "GameFontNormalSmall", nil, "LEFT")
    title:SetPoint("TOPLEFT", 10, -7)
    title:SetText("RESULT")
    title:SetTextColor(0.6, 0.6, 0.6)

    page.big = W.Text(box, "GameFontHighlightLarge", 22, "LEFT")
    page.big:SetPoint("TOPLEFT", 10, -24)
    page.verdict = W.Text(box, "GameFontNormal", nil, "LEFT")
    page.verdict:SetPoint("LEFT", page.big, "RIGHT", 12, 0)
    page.verdict:SetPoint("RIGHT", box, "RIGHT", -10, 0)

    page.body = W.Text(box, "GameFontHighlight", nil, "LEFT")
    page.body:SetPoint("TOPLEFT", 10, -54)
    page.body:SetPoint("RIGHT", -10, 0)
    page.body:SetJustifyV("TOP")
    if page.body.SetSpacing then page.body:SetSpacing(2) end

    page.save = W.Button(box, "Save for Sim Lab", 150)
    page.save:SetPoint("BOTTOMRIGHT", -8, 8)
    page.save:SetScript("OnClick", function()
        if T.target and ns.CoefTest.Save(T.target) then T.Update(page) end
    end)
    page.forget = W.Button(box, "Forget saved", 110)
    page.forget:SetPoint("RIGHT", page.save, "LEFT", -6, 0)
    page.forget:SetScript("OnClick", function()
        if T.target then ns.CoefTest.Forget(T.target); T.Update(page) end
    end)
    page.saved = W.Text(box, "GameFontHighlightSmall", nil, "LEFT")
    page.saved:SetPoint("BOTTOMLEFT", 10, 13)
    page.saved:SetPoint("RIGHT", page.forget, "LEFT", -8, 0)

    -- Ticks in one cast (only for "over time" tests).
    page.ticksLabel = W.Text(box, "GameFontHighlightSmall", nil, "RIGHT")
    page.ticksLabel:SetPoint("TOPRIGHT", -62, -9)
    local function tickButton(text, dx, delta)
        local b = W.Create("Button", nil, box, { "UIPanelButtonTemplate" })
        b:SetSize(22, 18)
        b:SetText(text)
        b:SetPoint("TOPRIGHT", dx, -6)
        b:SetScript("OnClick", function()
            local t = T.target
            if t then ns.CoefTest.SetTicks(t, ns.CoefTest.Ticks(t) + delta); T.Update(page) end
        end)
        return b
    end
    page.tickMinus = tickButton("-", -34, -1)
    page.tickPlus = tickButton("+", -8, 1)
end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    T.page = page
    local listW = 226
    page.list = W.List(page, listW, 426, { { title = "Saved", width = 46 } })
    page.list.frame:SetPoint("TOPLEFT", 0, 0)
    page.list:SetNameTitle("Spell to test")

    local x = listW + 8
    local right = width - x
    local half = (right - 6) / 2
    page.before = sampleBox(page, "before", "1. BEFORE", x, half)
    page.after = sampleBox(page, "after", "2. AFTER (more spell power)", x + half + 6, half)
    buildEntry(page, x, right)
    buildResult(page, x, right)
end

---------------------------------------------------------------------------
-- Typing numbers
---------------------------------------------------------------------------

function T.Submit(page, text)
    local t = T.target
    if not t then return end
    local nums, bad = ns.CoefMath.ParseNumbers(text)
    if #nums == 0 then
        T.message = #bad > 0 and ("'" .. bad[1] .. "' isn't a number.") or nil
        T.messageColor = RED
        T.Update(page)
        return
    end
    local added, problem = ns.CoefTest.Add(t, nums)
    if #bad > 0 and not problem then problem = "'" .. bad[1] .. "' isn't a number, so it was left out." end
    if problem then
        T.message = (added > 0 and ("Added " .. added .. ". ") or "") .. problem
        T.messageColor = added > 0 and YELLOW or RED
    else
        T.message = ("Added %d hit%s."):format(added, added == 1 and "" or "s")
        T.messageColor = W.GREEN
    end
    T.Update(page)
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

local function sampleText(s, stats, spNow, active)
    local lines = {}
    lines[#lines + 1] = "Spell power: " .. (s.sp and f(s.sp) or (spNow and ("|cff999999" .. f(spNow) .. " (now)|r") or "?"))
    lines[#lines + 1] = "Hits: " .. stats.n
    if stats.n > 0 then
        lines[#lines + 1] = "Average: " .. f(stats.mean, 1)
        lines[#lines + 1] = "|cff999999From " .. f(stats.low) .. " to " .. f(stats.high) .. "|r"
    elseif active then
        lines[#lines + 1] = "|cff999999Type numbers below.|r"
    end
    return table.concat(lines, "\n")
end

local function paintBox(box, on)
    if box.SetBackdropBorderColor then
        if on then box:SetBackdropBorderColor(0.2, 0.6, 1, 1) else box:SetBackdropBorderColor(0.15, 0.2, 0.28, 1) end
    end
    box.state:SetText(on and "|cff3fa9ffnumbers go here|r" or "click to use")
end

-- "+5 SP: about 400 hits each" for a few spell power changes.
local function planner(t, spread, dSPs)
    local C = ns.CoefMath
    local ticks = ns.CoefTest.Ticks(t)
    local parts = {}
    for _, d in ipairs(dSPs) do
        local n = C.HitsNeeded(spread, d, C.RULES.okMargin, ticks)
        parts[#parts + 1] = ("+%d: %s"):format(d, n and ("~" .. f(n)) or "|cffff4a3anot enough|r")
    end
    return table.concat(parts, "   ")
end

function T.Update(page)
    local CT, C = ns.CoefTest, ns.CoefMath
    local level = UnitLevel("player") or 1
    local list = CT.Targets(level)
    local t = selectedTarget(list)
    T.target = t

    -- Left list
    local rows = {}
    local lastGroup
    for _, x in ipairs(list) do
        local group = (x.part == "direct" or x.part == "tick") and "Spells (your highest rank)" or "Weapon buffs and totems"
        if group ~= lastGroup then rows[#rows + 1] = { header = group }; lastGroup = group end
        local saved = CT.Saved(x.spell.key, x.rank.rank)[x.part]
        local test = CT.Test(x)
        local n = #test.before.hits + #test.after.hits
        rows[#rows + 1] = {
            icon = x.rank.icon, name = x.spell.name,
            sub = "Rank " .. x.rank.rank .. " · " .. (CT.PART_NAMES[x.part] or x.part) .. (n > 0 and (" · " .. n .. " hits") or ""),
            cols = { saved and f(saved.total, 2) or "-" },
            colColors = { saved and W.GREEN or W.GREY },
            selected = x.id == T.selected, badge = saved ~= nil,
            onClick = function() T.selected = x.id; T.message = nil; T.Update(page) end,
            tooltip = function(tt)
                tt:AddDoubleLine(x.spell.name, "Rank " .. x.rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
                tt:AddLine("Type " .. x.what .. ".", 1, 0.82, 0, true)
                if saved then
                    tt:AddDoubleLine("Your saved result", f(saved.total, 3) .. " ± " .. f(saved.totalMargin, 3), 1, 0.82, 0, 0.12, 1, 0)
                end
                local rc = CT.RuleCoef(x)
                tt:AddDoubleLine("Old Classic rule (untested)", rc and f(rc * CT.Ticks(x), 3) or "none known", 1, 0.82, 0, 0.6, 0.6, 0.6)
            end,
        }
    end
    if #list == 0 then
        rows[#rows + 1] = { name = "No damage spells found", sub = "Try /es check", cols = { "" } }
    end
    page.list:SetRows(rows)

    if not t then
        page.big:SetText("")
        page.verdict:SetText("")
        page.body:SetText("The addon couldn't read any damage spells from the game yet.")
        return
    end

    -- Sample boxes
    local test = CT.Test(t)
    local active = CT.Active()
    local spNow = CT.CurrentSP(t)
    local res = CT.Result(t)
    page.before.body:SetText(sampleText(test.before, res.before, active == "before" and spNow or nil, active == "before"))
    page.after.body:SetText(sampleText(test.after, res.after, active == "after" and spNow or nil, active == "after"))
    paintBox(page.before, active == "before")
    paintBox(page.after, active == "after")

    -- Typing box
    local what = t.what
    if t.part == "direct" or t.part == "tick" then
        page.entryLabel:SetText(("Type %s of %s and press Enter."):format(what, t.spell.name))
    else
        page.entryLabel:SetText(("Type %s and press Enter."):format(what))
    end
    if page.auto then
        page.auto:SetChecked(CT.autoOn)
    end
    local msg = T.message
    if not msg then
        msg = CT.autoAvailable and "Tick the box to record hits by itself, or type them."
            or "Addons can't see your hits here. Type the numbers that pop up over the mob."
    end
    page.msg:SetText(msg)
    local mc = T.message and T.messageColor or W.GREY
    page.msg:SetTextColor(mc[1], mc[2], mc[3])

    -- Ticks control
    local isTick = t.part == "tick"
    local ticks = CT.Ticks(t)
    page.ticksLabel:SetShown(isTick)
    page.tickMinus:SetShown(isTick)
    page.tickPlus:SetShown(isTick)
    if isTick then page.ticksLabel:SetText(("Ticks per cast: %d (count them)"):format(ticks)) end

    -- Result
    local rule = CT.RuleCoef(t)
    local ruleTotal = rule and rule * ticks
    local lines = {}
    local function add(s) lines[#lines + 1] = s end
    local v = VERDICT[res.verdict] or VERDICT.wait
    page.verdict:SetText(v[1])
    page.verdict:SetTextColor(v[2][1], v[2][2], v[2][3])

    -- How spread out the hits are: from your Before hits if there are
    -- enough, or else from the tooltip range.
    local spread
    if res.before.n >= C.RULES.minHits then spread = res.before.sd
    else spread = t.spread or 0 end

    if res.verdict == "wait" then
        page.big:SetText("?")
        page.big:SetTextColor(0.6, 0.6, 0.6)
        if res.before.n == 0 and res.after.n == 0 then
            add("|cffffd1001.|r Click BEFORE. Use " .. t.spell.name .. " on a mob and type " .. what .. ".")
            add("|cffffd1002.|r Put on gear with more spell power. The more, the better.")
            add("|cffffd1003.|r Click AFTER and do the same.")
        else
            add(res.why)
            -- Gear already changed? Use the real change for the plan.
            local dSP = test.before.sp and spNow and (spNow - test.before.sp)
            if res.dSP ~= 0 and test.after.sp and test.before.sp then dSP = res.dSP end
            if dSP and dSP ~= 0 then
                local n = C.HitsNeeded(spread, dSP, C.RULES.okMargin, ticks)
                add(("With your %+d spell power: %s"):format(dSP,
                    n and ("about " .. f(n) .. " hits in each box.") or "|cffff4a3anot enough to see a change. Add more spell power.|r"))
            end
        end
        add("|cffffd100Hits needed in each box, by spell power added:|r")
        add(planner(t, spread, { 5, 10, 20, 40 }))
        if (spread or 0) < 0.5 then
            local need = C.SpellPowerNeeded(C.RULES.okMargin, ticks)
            add(("These hits are usually the same number every time, so typing more of them doesn't help much. You need about +%d spell power%s."):format(
                need, rule and (". With +5, each grows only about " .. f(rule * 5, 2)) or ""))
            if t.part == "proc" then
                add("|cff999999Nobody knows yet if Flametongue gets spell power in Forever. A result near 0 is a real answer too.|r")
            end
        elseif rule then
            add(("With +5 spell power each hit grows only about %s, but hits jump around by %s. That's why it takes many hits."):format(
                f(rule * 5, 1), f(t.high - t.low)))
        else
            add(("Hits jump around by %s, so it takes many hits. Nobody knows yet how much spell power this gets in Forever."):format(f(t.high - t.low)))
        end
    else
        page.big:SetText(f(res.total, 3) .. "  ± " .. f(res.totalMargin, 3))
        local col = v[2]
        page.big:SetTextColor(col[1], col[2], col[3])
        if res.why then add("|cffff4a3a" .. res.why .. "|r") end
        add(("%+d spell power made each %s %s bigger on average (%s to %s)."):format(
            res.dSP, t.part == "tick" and "tick" or "hit", f(res.dMean, 1), f(res.before.mean, 1), f(res.after.mean, 1)))
        if t.part == "tick" then
            add(("Per tick %s × %d ticks = %s of your spell power for the whole spell."):format(f(res.coef, 3), ticks, f(res.total, 3)))
        else
            add(("So each point of spell power adds about %s damage."):format(f(res.coef, 2)))
        end
        if ruleTotal then
            add(("Old Classic rule says %s |cff999999(not tested in Forever)|r."):format(f(ruleTotal, 3)))
        end
        local w = CT.Weight(t, res.total)
        if w and w.strEq then
            add(("Stat weight: 1 spell power here = %s DPS = about %s Strength |cff999999(if used every %s sec)|r."):format(
                f(w.dps, 3), f(w.strEq, 2), f(t.every, 1)))
        end
        if res.before.roundingLimited and res.after.roundingLimited then
            add("Every number was the same, so more hits won't help. More spell power will.")
        elseif res.verdict ~= "good" then
            local n = C.HitsNeeded(math.max(res.before.sd, res.after.sd), res.dSP, C.RULES.goodMargin, ticks)
            add(n and ("For a Good result: about %s hits in each box."):format(f(n))
                or "For a Good result you need a bigger spell power change.")
        end
        if not (w and w.strEq) then
            add("|cff999999Same mob type, no buffs or debuffs that change damage (like Stormstrike).|r")
        end
    end
    page.body:SetText(table.concat(lines, "\n"))

    -- Save
    local saved = CT.Saved(t.spell.key, t.rank.rank)[t.part]
    local canSave = res.verdict == "good" or res.verdict == "ok"
    if page.save.SetEnabled then page.save:SetEnabled(canSave) end
    page.forget:SetShown(saved ~= nil)
    if saved then
        page.saved:SetText(("|cff1eff00Saved: %s ± %s|r (%d + %d hits, %+d SP%s). Used by Spells and Sim Lab."):format(
            f(saved.total, 3), f(saved.totalMargin, 3), saved.hitsBefore or 0, saved.hitsAfter or 0, saved.dSP or 0,
            saved.date and (", " .. saved.date) or ""))
    else
        page.saved:SetText(canSave and "Save it so the Spells tab and Sim Lab use it." or "")
    end
end
