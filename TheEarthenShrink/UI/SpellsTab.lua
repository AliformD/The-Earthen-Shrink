-- The Earthen Shrink: Spell Efficiency tab
--
-- Every damage spell, every rank: mana cost, % of your mana bar, damage,
-- damage per mana and DPS. The bar next to "Per Mana" is coloured by school.
-- "Best per mana" only counts ranks you'd really cast: a rank needs at least
-- half the DPS of that spell's top rank (so Lightning Bolt Rank 1 is shown
-- but never picked).

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.spells = T
local f = function(...) return ns.fmt(...) end

T.sortByDpm = false     -- false = grouped by spell, true = one list sorted by damage per mana
T.showFuture = false    -- also show ranks above your level (greyed out)

local SCHOOL_COLOR = {
    Nature = { 0.35, 0.6, 1 }, Fire = { 1, 0.45, 0.1 }, Frost = { 0.4, 0.85, 1 }, Physical = { 0.85, 0.85, 0.85 },
}
local DIM = { 0.45, 0.45, 0.45 }

local COLS = {
    { title = "Level", width = 40 },
    { title = "Mana", width = 46 },
    { title = "% Mana", width = 52 },
    { title = "Damage", width = 56 },
    { title = "Per Mana", width = 60 },
    { title = "DPS", width = 50 },
}

-- Which calc to use for each kind of spell.
local function calc(spell, rank, p)
    if spell.kind == "spell" then return ns.SpellMath.Calc(spell, rank, p) end
    if spell.kind == "shield" then return ns.SpellMath.CalcShield(spell, rank, p) end
    if spell.kind == "strike" then return ns.SpellMath.CalcStrike(spell, rank, p) end
end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    page.list = W.List(page, width, 330, COLS, 5)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Spell")

    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -320, 0)
    page.note:SetText("Tick = best per mana. Grey = low rank, too little DPS to use.")

    page.sort = W.Button(page, "Sort: by spell", 150)
    page.sort:SetPoint("BOTTOMRIGHT", -158, 0)
    page.sort:SetScript("OnClick", function()
        T.sortByDpm = not T.sortByDpm
        T.Update(page)
    end)
    page.future = W.Button(page, "Show higher ranks", 150)
    page.future:SetPoint("BOTTOMRIGHT", 0, 0)
    page.future:SetScript("OnClick", function()
        T.showFuture = not T.showFuture
        T.Update(page)
    end)
end

local function extraSub(e, refDmg)
    local c = e.c
    if not c then return "" end
    if e.spell.key == "FN" then
        local n = ns.TotemMath.FireNovaBreakpoint(c, refDmg)
        return n and (" · |cffffd100worth it at " .. n .. "+ enemies|r") or ""
    elseif e.spell.kind == "shield" then
        local n = ns.TotemMath.ShieldBreakpoint(c, refDmg)
        return (" · %d charges"):format(c.charges) .. (n and (" · |cffffd100needs %d to pay off|r"):format(n) or "")
    elseif e.spell.kind == "strike" then
        return " · weapon hit"
    end
    return ""
end

local function makeRow(e, p, best, maxDpm, refDmg)
    local spell, rank, c = e.spell, e.rank, e.c
    local dim = e.locked or (c and not c.useful)
    local sub = ("Rank %d · %s"):format(rank.rank, rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "instant")
    if e.locked then sub = sub .. " · not yet"
    elseif c and not c.useful then sub = sub .. " · low rank" end
    if rank.levelSource == "guess" then sub = sub .. " · level is a guess" end
    if not c then sub = sub .. " · couldn't read tooltip" end
    sub = sub .. extraSub(e, refDmg)
    local isBest = e == best
    local grey = dim and DIM or nil
    return {
        icon = rank.icon, badge = isBest, dim = dim,
        name = spell.name, nameColor = dim and DIM or (isBest and W.GREEN or nil),
        sub = sub,
        cols = {
            tostring(rank.level or "?"),
            rank.mana and f(rank.mana) or "?",
            c and c.manaPct and (f(c.manaPct, 1) .. "%") or "?",
            c and f(c.expected) or "?",
            c and f(c.dpm, 2) or "?",
            c and f(c.dps, 1) or "?",
        },
        colColors = { grey, grey, grey, grey or W.WHITE, isBest and W.GREEN or grey or W.WHITE, grey or W.WHITE },
        meter = c and maxDpm > 0 and c.dpm / maxDpm or nil,
        meterColor = dim and DIM or SCHOOL_COLOR[spell.school or "Physical"],
        tooltip = function(tt)
            tt:AddDoubleLine(spell.name, "Rank " .. rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
            tt:AddDoubleLine((rank.mana and f(rank.mana) or "?") .. " Mana",
                rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "Instant", 1, 1, 1, 1, 1, 1)
            if rank.desc then tt:AddLine(rank.desc, 1, 0.82, 0, true) end
            tt:AddLine(" ")
            if c and spell.kind == "spell" then
                W.AddMath(tt, ns.SpellMath.Explain(spell, rank, c))
            elseif c and spell.kind == "shield" then
                W.AddMath(tt, {
                    { "Damage per charge", f(c.perCharge, 1) },
                    ("%d charges × %s = %s if every charge goes off"):format(c.charges, f(c.perCharge, 1), f(c.expected)),
                    ("%s ÷ %s mana = %s damage per mana"):format(f(c.expected, 1), f(c.mana), f(c.dpm, 2)),
                    "DPS here = damage per second of your time spent casting it.",
                })
            elseif c and spell.kind == "strike" then
                W.AddMath(tt, {
                    ("%s%% weapon damage (%s)"):format(f(c.pct * 100), c.pctFromGame and "from the tooltip" or "guess, not from the tooltip"),
                    ("One hit with crit: %s"):format(f(c.expected, 1)),
                    ("%s ÷ %s mana = %s damage per mana"):format(f(c.expected, 1), f(c.mana), f(c.dpm, 2)),
                    "Its bonus to your next Lightning Bolt, Chain Lightning or Earth Shock is not added here.",
                })
            end
            if c then
                tt:AddLine(" ")
                tt:AddDoubleLine("% of your mana", f(c.manaPct or 0, 1) .. "%", 1, 0.82, 0, 1, 1, 1)
                if c.mana > 0 and p.mana then
                    tt:AddDoubleLine("Casts per full mana bar", f(math.floor(p.mana / c.mana)), 1, 0.82, 0, 1, 1, 1)
                    tt:AddDoubleLine("Damage per full mana bar", f(math.floor(p.mana / c.mana) * c.expected), 1, 0.82, 0, 0.12, 1, 0)
                end
                if not c.useful and not e.locked then
                    tt:AddLine(" ")
                    tt:AddLine("Low rank: less than half the DPS of your top rank, so it's not picked as best.", 0.6, 0.6, 0.6, true)
                end
            else
                tt:AddLine("The addon couldn't read this rank's numbers from the game.", 1, 0.3, 0.2, true)
            end
            W.AddNote(tt, "Base damage, mana and cast time come from the game. Spell power share, hit and crit rules are old Classic rules until we test them in Forever.")
        end,
    }
end

function T.Update(page)
    page.sort:SetText(T.sortByDpm and "Sort: per mana" or "Sort: by spell")
    page.future:SetText(T.showFuture and "Hide higher ranks" or "Show higher ranks")

    local p = ns.Profile.Player()
    local entries = {}
    for _, spell in ipairs(ns.RANKS) do
        if spell.kind == "spell" or spell.kind == "shield" or spell.kind == "strike" then
            for _, rank in ipairs(ns.SpellData.Ranks(spell.key)) do
                local locked = rank.level and rank.level > p.level
                if T.showFuture or not locked then
                    entries[#entries + 1] = { spell = spell, rank = rank, c = calc(spell, rank, p), locked = locked }
                end
            end
        end
    end
    ns.SpellMath.MarkUseful(entries, "dps")

    local maxDpm, best, bestDps = 0, nil, nil
    for _, e in ipairs(entries) do
        local c = e.c
        if c and not e.locked then
            maxDpm = math.max(maxDpm, c.dpm)
            -- Lightning Shield and Fire Nova depend on hits/enemies, so they
            -- aren't picked as the plain "best per mana".
            local plain = e.spell.kind == "spell" and not e.spell.aoe
            if plain and c.useful and (not best or c.dpm > best.c.dpm) then best = e end
            if plain and (not bestDps or c.dps > bestDps.c.dps) then bestDps = e end
        end
    end
    local refDmg = best

    page.chips[1]:Set("Max mana", f(p.mana))
    page.chips[2]:Set("Best damage per mana", best and (best.spell.name .. " R" .. best.rank.rank .. ": " .. f(best.c.dpm, 2)) or "-",
        best and W.GREEN or nil)
    page.chips[3]:Set("Highest DPS", bestDps and (bestDps.spell.name .. " R" .. bestDps.rank.rank .. ": " .. f(bestDps.c.dps, 1)) or "-")

    local rows = {}
    if #entries == 0 then
        rows[1] = { header = "No spell data yet. Wait a few seconds, or type /es check" }
    elseif T.sortByDpm then
        table.sort(entries, function(a, b)
            return (a.c and a.c.dpm or -1) > (b.c and b.c.dpm or -1)
        end)
        rows[1] = { header = "All damage spells, most damage per mana first" }
        for _, e in ipairs(entries) do rows[#rows + 1] = makeRow(e, p, best, maxDpm, refDmg) end
    else
        local lastKey
        for _, e in ipairs(entries) do
            if e.spell.key ~= lastKey then
                rows[#rows + 1] = { header = e.spell.name, headerIcon = e.rank.icon }
                lastKey = e.spell.key
            end
            rows[#rows + 1] = makeRow(e, p, best, maxDpm, refDmg)
        end
    end
    page.list:SetRows(rows)
end
