-- The Earthen Shrink: Totems tab
--
-- Every totem at the highest rank for your level: cost, % of your mana, and
-- how long it must stay down (or how many hits / enemies it needs) to be as
-- mana-efficient as your best normal spell or heal. Also the breakpoints for
-- Fire Nova and Lightning Shield, and Call of the Elements vs one by one.

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
    page.list = W.List(page, width, 360, COLS)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Totem")
    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", 0, 0)
    page.note:SetText("Green = pays for itself in time. Yellow = depends on the fight. Red = your best spell is better. Hover for the math.")
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

    local rows = {}
    for _, el in ipairs(ELEMENTS) do
        local first = true
        for _, spell in ipairs(ns.RANKS) do
            if spell.kind == "totem" and spell.element == el then
                local rank = ns.SpellData.Best(spell.key, p.level)
                if rank then
                    if first then rows[#rows + 1] = { header = el .. " totems" }; first = false end
                    rows[#rows + 1] = row(spell.name, rank, p, ns.TotemMath.Calc(spell, rank, p, refDmg, refHeal))
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
