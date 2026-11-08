-- The Earthen Shrink: Spell Efficiency tab
--
-- Every damage spell, every rank: mana cost, % of your mana bar, damage,
-- damage per mana and DPS. Best damage per mana is marked in green.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.spells = T
local f = function(...) return ns.fmt(...) end

T.sortByDpm = false     -- false = grouped by spell, true = one list sorted by damage per mana
T.showFuture = false    -- also show ranks above your level (greyed out)

local COLS = {
    { title = "Level", width = 40 },
    { title = "Mana", width = 46 },
    { title = "% Mana", width = 52 },
    { title = "Damage", width = 56 },
    { title = "Per Mana", width = 60 },
    { title = "DPS", width = 50 },
}

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    page.list = W.List(page, width, 330, COLS, 5)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Spell")

    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -320, 0)
    page.note:SetText("Hover a row for the math. Green = most damage per mana.")

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

local function makeRow(spell, rank, c, p, isBest, maxDpm)
    local locked = rank.level and rank.level > p.level
    local sub = ("Rank %d · %s"):format(rank.rank, rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "instant")
    if locked then sub = sub .. " · not yet" end
    if rank.levelSource == "guess" then sub = sub .. " · level is a guess" end
    if not c then sub = sub .. " · couldn't read tooltip" end
    local grey = locked and W.GREY or nil
    return {
        icon = rank.icon,
        name = spell.name .. (isBest and "  |cff1eff00(best per mana)|r" or ""),
        nameColor = grey,
        sub = sub,
        cols = {
            tostring(rank.level or "?"),
            rank.mana and f(rank.mana) or "?",
            c and c.manaPct and (f(c.manaPct, 1) .. "%") or "?",
            c and f(c.expected) or "?",
            c and f(c.dpm, 2) or "?",
            c and f(c.dps, 1) or "?",
        },
        colColors = { grey, grey, grey, grey, isBest and W.GREEN or grey, grey },
        meter = c and maxDpm > 0 and c.dpm / maxDpm or nil,
        tooltip = function(tt)
            tt:AddDoubleLine(spell.name, "Rank " .. rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
            tt:AddDoubleLine((rank.mana and f(rank.mana) or "?") .. " Mana",
                rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "Instant", 1, 1, 1, 1, 1, 1)
            if rank.desc then tt:AddLine(rank.desc, 1, 0.82, 0, true) end
            tt:AddLine(" ")
            if c then
                W.AddMath(tt, ns.SpellMath.Explain(spell, rank, c))
                tt:AddLine(" ")
                tt:AddDoubleLine("% of your mana", f(c.manaPct or 0, 1) .. "%", 1, 0.82, 0, 1, 1, 1)
                tt:AddDoubleLine("Casts per full mana bar", f(c.castsPerBar or 0), 1, 0.82, 0, 1, 1, 1)
                tt:AddDoubleLine("Damage per full mana bar", f(c.dmgPerBar or 0), 1, 0.82, 0, 0.12, 1, 0)
            else
                tt:AddLine("The addon couldn't read this rank's damage from the game.", 1, 0.3, 0.2, true)
            end
            W.AddNote(tt, "Base damage, mana and cast time come from the game. Spell power share, hit and crit rules are old Classic rules until we test them in Forever.")
        end,
    }
end

function T.Update(page)
    page.sort:SetText(T.sortByDpm and "Sort: per mana" or "Sort: by spell")
    page.future:SetText(T.showFuture and "Hide higher ranks" or "Show higher ranks")

    local p = ns.Profile.Player()
    -- Work out every row first so we know the best one.
    local entries, maxDpm, best, bestDps = {}, 0, nil, nil
    for _, spell in ipairs(ns.RANKS) do
        if spell.kind == "spell" then
            for _, rank in ipairs(ns.SpellData.Ranks(spell.key)) do
                local locked = rank.level and rank.level > p.level
                if T.showFuture or not locked then
                    local c = ns.SpellMath.Calc(spell, rank, p)
                    local e = { spell = spell, rank = rank, c = c, locked = locked }
                    entries[#entries + 1] = e
                    if c and not locked then
                        if c.dpm > maxDpm then maxDpm, best = c.dpm, e end
                        if not bestDps or c.dps > bestDps.c.dps then bestDps = e end
                    end
                end
            end
        end
    end

    page.chips[1]:Set("Max mana", f(p.mana))
    page.chips[2]:Set("Most damage per mana", best and (best.spell.name .. " R" .. best.rank.rank .. ": " .. f(best.c.dpm, 2)) or "-",
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
        for _, e in ipairs(entries) do rows[#rows + 1] = makeRow(e.spell, e.rank, e.c, p, e == best, maxDpm) end
    else
        local lastKey
        for _, e in ipairs(entries) do
            if e.spell.key ~= lastKey then
                rows[#rows + 1] = { header = e.spell.name }
                lastKey = e.spell.key
            end
            rows[#rows + 1] = makeRow(e.spell, e.rank, e.c, p, e == best, maxDpm)
        end
    end
    page.list:SetRows(rows)
end
