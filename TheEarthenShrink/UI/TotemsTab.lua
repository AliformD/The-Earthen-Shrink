-- The Earthen Shrink: Totems tab
--
-- Every totem at the highest rank for your level: cost, % of your mana, and
-- how long it must stay down (or how many hits / enemies it needs) to be as
-- mana-efficient as your best normal spell or heal. Also the breakpoints for
-- Fire Nova and Lightning Shield, and Call of the Elements vs one by one.
-- At the top: a live bar for each totem you have down (the addon's own
-- timer, see TotemTracker.lua) and how your Mana Spring drops went.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.totems = T
local f = function(...) return ns.fmt(...) end

local VERDICT_COLOR = { ok = W.GREEN, mid = W.GOLD, bad = { 1, 0.29, 0.23 }, info = W.GREY }
local VERDICT_TEXT = {
    ok = "Worth it: pays off before it runs out.",
    mid = "Only worth it in the right fight (more enemies or more people hurt).",
    bad = "Not worth its mana compared with your best spell.",
    info = "No mana comparison for this one.",
}
local ELEMENTS = { "Fire", "Water", "Earth", "Air" }

local COLS = {
    { title = "Level", width = 40 },
    { title = "Mana", width = 46 },
    { title = "% Mana", width = 52 },
    { title = "Break-even", width = 130 },
}

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    T.BuildLive(page, width)
    page.list = W.List(page, width, 262, COLS)
    page.list.frame:SetPoint("TOPLEFT", 0, -146)
    page.list:SetNameTitle("Totem")
    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", 0, 0)
    page.note:SetText("Green = pays for itself in time. Yellow = depends on the fight. Red = your best spell is better. Hover for the math.")
end

---------------------------------------------------------------------------
-- Live totem bars (one per element) and the Mana Spring log line
---------------------------------------------------------------------------

local TR = function() return ns.TotemTracker end
local ELEMENT_COLOR = {
    Fire = { 0.95, 0.45, 0.15 }, Earth = { 0.65, 0.5, 0.3 },
    Water = { 0.25, 0.6, 1 }, Air = { 0.7, 0.85, 1 },
}

local function updateBar(b)
    local rec, age, left = TR().Active(b.element)
    if not rec then
        b.bar:SetValue(0)
        b.mark:Hide()
        b.label:SetText(b.element .. ": |cff9d9d9dnone down|r")
        b.right:SetText("")
        return
    end
    local dur = rec.duration
    b.bar:SetMinMaxValues(0, dur or 1)
    b.bar:SetValue(dur and left or 1)
    local col = ELEMENT_COLOR[b.element]
    -- Mana totems turn green once they've paid for themselves.
    local paid = rec.payoffTicks and ((rec.ticks or 0) >= rec.payoffTicks or (rec.payoffSec and age >= rec.payoffSec))
    if paid then col = W.GREEN end
    -- Red: this totem is wasted (Windfury + Flametongue Totem both down).
    local wasted = TR().wastedNow
    if wasted and rec.name == wasted.drop then col = { 1, 0.2, 0.15 } end
    b.bar:SetStatusBarColor(col[1], col[2], col[3])
    -- A white line on the bar where it pays off.
    if dur and rec.payoffSec and rec.payoffSec < dur then
        b.mark:ClearAllPoints()
        b.mark:SetPoint("TOP", b.bar, "TOPLEFT", b.barW * (1 - rec.payoffSec / dur), 2)
        b.mark:Show()
    else
        b.mark:Hide()
    end
    local short = rec.name:gsub(" Totem$", "")
    if wasted and rec.name == wasted.drop then short = "|cffff4a3a" .. short .. " (wasted)|r" end
    b.label:SetText(short)
    local txt = left and (ns.fmt(left, 0) .. "s") or (ns.fmt(age, 0) .. "s")
    if rec.payoffTicks then txt = ("%d/%d ticks · %s"):format(rec.ticks or 0, rec.payoffTicks, txt) end
    b.right:SetText(txt)
end

function T.BuildLive(page, width)
    local box = W.Panel(page)
    box:SetPoint("TOPLEFT", 0, -50)
    box:SetSize(width, 90)
    page.live = box
    local title = W.Text(box, "GameFontNormalSmall", nil, "LEFT")
    title:SetPoint("TOPLEFT", 8, -6)
    title:SetText("Your totems right now (the addon's own timer)")
    page.clear = W.Button(box, "Clear log", 76)
    page.clear:SetHeight(18)
    page.clear:SetPoint("TOPRIGHT", -6, -3)
    page.clear:SetScript("OnClick", function() TR().Clear() end)

    page.bars = {}
    local bw = (width - 16 - 3 * 8) / 4
    for i, el in ipairs(ELEMENTS) do
        local b = CreateFrame("Frame", nil, box)
        b:SetSize(bw, 28)
        b:SetPoint("TOPLEFT", 8 + (i - 1) * (bw + 8), -24)
        b.element = el
        b.barW = bw
        b.label = W.OneLine(W.Text(b, "GameFontHighlightSmall", nil, "LEFT"))
        b.label:SetPoint("TOPLEFT", 0, 0)
        b.label:SetWidth(bw * 0.5)
        b.right = W.OneLine(W.Text(b, "GameFontHighlightSmall", nil, "RIGHT"))
        b.right:SetPoint("TOPRIGHT", 0, 0)
        b.right:SetWidth(bw * 0.6)
        local bar = CreateFrame("StatusBar", nil, b)
        bar:SetPoint("BOTTOMLEFT", 0, 0)
        bar:SetSize(bw, 10)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetMinMaxValues(0, 1)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 1)
        b.bar = bar
        local mark = bar:CreateTexture(nil, "OVERLAY")
        mark:SetSize(2, 14)
        mark:SetColorTexture(1, 1, 1, 0.9)
        mark:Hide()
        b.mark = mark
        b:EnableMouse(true)
        b:SetScript("OnEnter", function(self)
            local rec = TR().Active(el)
            local key = rec and rec.key or (el == "Water" and "MST") or nil
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(rec and rec.name or (el .. " totems"), 1, 1, 1)
            if rec then
                local _, age, left = TR().Active(el)
                W.AddMath(GameTooltip, {
                    { "Down for", ns.fmt(age, 1) .. " sec" },
                    { "Time left", left and (ns.fmt(left, 1) .. " sec") or "?" },
                    { "Duration from", rec.durationFrom or "unknown" },
                    rec.perTick and { "Ticks seen", ("%d (pays off at %d)"):format(rec.ticks or 0, rec.payoffTicks or 0) } or "",
                    rec.perTick and { "Mana back so far", ns.fmt(rec.gained or 0) .. " of " .. ns.fmt(rec.cost or 0) .. " spent" } or "",
                })
                GameTooltip:AddLine(" ")
            end
            if key then
                GameTooltip:AddLine("Your log", 1, 0.82, 0)
                W.AddMath(GameTooltip, TR().TooltipLines(key))
            end
            W.AddNote(GameTooltip, "The white line on the bar is where the totem has paid back its mana. The bar turns green after that.")
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        page.bars[i] = b
    end

    page.logLine = W.OneLine(W.Text(box, "GameFontHighlightSmall", nil, "LEFT"))
    page.logLine:SetPoint("BOTTOMLEFT", 8, 8)
    page.logLine:SetPoint("RIGHT", -8, 0)

    -- Move the bars every 0.1 sec while the window is open on this tab
    -- (works in combat too: it only changes bars, nothing protected).
    TR().onTick = function()
        if box:IsVisible() then for _, b in ipairs(page.bars) do updateBar(b) end end
    end
end

function T.UpdateLive(page)
    for _, b in ipairs(page.bars) do updateBar(b) end
    local wasted = TR().wastedNow
    if wasted then
        page.logLine:SetText(wasted.bestIsActive
            and ("|cffff4a3aActive: %s (dropped last). %s is wasted: swap it.|r"):format(wasted.active, wasted.drop)
            or ("|cffff4a3aActive: %s (dropped last). %s is wasted. Better: drop %s again.|r"):format(wasted.active, wasted.drop, wasted.best))
        return
    end
    local line = TR().ShortLine("MST")
    page.logLine:SetText("|cff3fc7ebMana Spring:|r " .. (line or "no drops logged yet. Drop one and the timer starts on its own."))
end

local function row(name, rank, p, res, extraTooltip)
    local col = VERDICT_COLOR[res.verdict or "info"]
    return {
        icon = rank and rank.icon,
        name = name,
        sub = (rank and ("Rank " .. rank.rank) or "") .. (res.sub and (" · " .. res.sub) or ""),
        cols = {
            rank and tostring(rank.level or "?") or "",
            res.mana and f(res.mana) or "?",
            res.manaPct and (f(res.manaPct, 1) .. "%") or "?",
            res.breakEven or "?",
        },
        colColors = { nil, nil, nil, col },
        tooltip = function(tt)
            tt:AddDoubleLine(name, rank and ("Rank " .. rank.rank) or "", 1, 1, 1, 0.6, 0.6, 0.6)
            if res.mana then tt:AddLine(f(res.mana) .. " Mana", 1, 1, 1) end
            if rank and rank.desc then tt:AddLine(rank.desc, 1, 0.82, 0, true) end
            tt:AddLine(" ")
            W.AddMath(tt, res.lines)
            if extraTooltip then extraTooltip(tt) end
            tt:AddLine(" ")
            tt:AddLine(VERDICT_TEXT[res.verdict or "info"], col[1], col[2], col[3], true)
            W.AddNote(tt, "Totem numbers come from the game. Attack speed (if the tooltip doesn't say), spell power share and crit are old Classic rules until tested.")
        end,
    }
end

function T.Update(page)
    local p = ns.Profile.Player()
    local refDmg = ns.SpellMath.BestDamageRef(p)
    local refHeal = ns.SpellMath.BestHealRef(p)

    page.chips[1]:Set("Compared with (damage)", refDmg and (("%s R%d: %s per mana"):format(refDmg.spell.name, refDmg.rank.rank, f(refDmg.c.dpm, 2))) or "-")
    page.chips[2]:Set("Compared with (healing)", refHeal and (("%s R%d: %s per mana"):format(refHeal.spell.name, refHeal.rank.rank, f(refHeal.c.hpm, 2))) or "-")
    page.chips[3]:Set("Max mana", f(p.mana))
    T.UpdateLive(page)

    local rows = {}
    for _, el in ipairs(ELEMENTS) do
        local first = true
        for _, spell in ipairs(ns.RANKS) do
            if spell.kind == "totem" and spell.element == el then
                local rank = ns.SpellData.Best(spell.key, p.level)
                if rank then
                    if first then rows[#rows + 1] = { header = el .. " totems" }; first = false end
                    rows[#rows + 1] = row(spell.name, rank, p, ns.TotemMath.Calc(spell, rank, p, refDmg, refHeal), function(tt)
                        if not TR().Summary(spell.key) then return end
                        tt:AddLine(" ")
                        tt:AddLine("Your log (the addon's own timer)", 1, 0.82, 0)
                        W.AddMath(tt, TR().TooltipLines(spell.key))
                    end)
                end
            end
        end
    end

    -- Breakpoints for spells that aren't totems
    local bp = {}
    local fn = ns.SpellData.Best("FN", p.level)
    local fnc = fn and ns.SpellMath.Calc(ns.RANKS_BY_KEY.FN, fn, p)
    if fnc then
        local n = ns.TotemMath.FireNovaBreakpoint(fnc, refDmg)
        bp[#bp + 1] = row("Fire Nova", fn, p, {
            mana = fn.mana, manaPct = fnc.manaPct, sub = "explodes around your Fire totem",
            breakEven = n and (n .. "+ enemies") or "?",
            verdict = n and (n <= 2 and "ok" or n <= 4 and "mid" or "bad") or "info",
            lines = {
                { "Damage to each enemy", f(fnc.expected) },
                ("%s ÷ %s mana = %s per mana for each enemy hit"):format(f(fnc.expected, 1), f(fn.mana), f(fnc.dpm, 2)),
                refDmg and ("%s ÷ %s = %d enemies to beat %s"):format(f(refDmg.c.dpm, 2), f(fnc.dpm, 2), n or 0, refDmg.spell.name) or "",
            },
        })
    end
    local ls = ns.SpellData.Best("LS", p.level)
    local lsc = ls and ns.SpellMath.CalcShield(ns.RANKS_BY_KEY.LS, ls, p)
    if lsc then
        local n = ns.TotemMath.ShieldBreakpoint(lsc, refDmg)
        bp[#bp + 1] = row("Lightning Shield", ls, p, {
            mana = ls.mana, manaPct = lsc.manaPct, sub = lsc.charges .. " charges, then recast",
            breakEven = n and (n .. " of " .. lsc.charges .. " charges") or "?",
            verdict = n and (n <= lsc.charges and "ok" or "bad") or "info",
            lines = {
                { "Damage per charge", f(lsc.perCharge, 1) },
                ("%d charges × %s = %s per cast"):format(lsc.charges, f(lsc.perCharge, 1), f(lsc.expected)),
                refDmg and ("Same mana on %s = %s damage"):format(refDmg.spell.name, f(ls.mana * refDmg.c.dpm)) or "",
                n and ("Needs %d charges to go off to match it. Each charge goes off when something hits you."):format(n) or "",
                "It still does damage while you cast other spells, so it's free damage on top.",
            },
        })
    end
    if #bp > 0 then
        rows[#rows + 1] = { header = "Breakpoints: when is it worth casting?" }
        for _, r in ipairs(bp) do rows[#rows + 1] = r end
    end

    -- Call of the Elements vs placing 4 totems yourself
    local coe = ns.SpellData.Ranks("COE")[1]
    local R = ns.TotemMath.RULES
    local cast = coe and coe.cast and coe.cast > 0 and coe.cast or R.callCast
    local byHand = 4 * R.totemGcd
    rows[#rows + 1] = { header = "Placing totems" }
    rows[#rows + 1] = row("Call of the Elements", coe, p, {
        mana = coe and coe.mana, sub = "drops your 4 saved totems",
        breakEven = cast < byHand and ("saves " .. f(byHand - cast, 1) .. " sec") or ("costs " .. f(cast - byHand, 1) .. " sec more"),
        verdict = "info",
        lines = {
            { "One cast", f(cast, 1) .. " sec" .. ((coe and coe.cast) and "" or " (Blizzard's number)") },
            { "4 totems one by one", ("4 × %s sec = %s sec"):format(f(R.totemGcd, 1), f(byHand, 1)) },
            "Mana is the same: it costs your 4 totems added together.",
            "Casting it can be interrupted; placing one by one can't (they're instant).",
            cast < byHand and "So it's faster when you need all 4. If you only need 1 or 2, place them yourself." or "Placing them yourself is faster.",
        },
    })
    local tr = ns.SpellData.Ranks("TR")[1]
    if tr then
        rows[#rows + 1] = row("Totemic Recall", tr, p, {
            mana = tr.mana, sub = "removes your totems",
            breakEven = "gets back " .. f(R.recallRefund * 100) .. "%", verdict = "info",
            lines = { "Gives back 25% of the mana of the totems you still have down (Blizzard). Use it when you leave a fight before they run out." },
        })
    end
    page.list:SetRows(rows)
end
