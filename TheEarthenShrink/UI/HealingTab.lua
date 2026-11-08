-- The Earthen Shrink: Healing tab
--
-- Every Shaman heal, every rank: mana, % of your mana bar, healing, healing
-- per mana and healing per second. "Best per mana" skips low ranks that heal
-- too slowly to be useful (less than half the healing per second of that
-- spell's top rank).

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.healing = T
local f = function(...) return ns.fmt(...) end
local DIM = { 0.45, 0.45, 0.45 }
local HEAL_COLOR = { 0.2, 0.9, 0.45 }

T.showFuture = false

local COLS = {
    { title = "Level", width = 40 },
    { title = "Mana", width = 46 },
    { title = "% Mana", width = 52 },
    { title = "Heal", width = 56 },
    { title = "Per Mana", width = 60 },
    { title = "HPS", width = 50 },
}

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    page.list = W.List(page, width, 330, COLS, 5)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Heal")
    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -170, 0)
    page.note:SetText("Tick = most healing per mana. Grey = low rank, heals too slowly to use.")
    page.future = W.Button(page, "Show higher ranks", 150)
    page.future:SetPoint("BOTTOMRIGHT", 0, 0)
    page.future:SetScript("OnClick", function()
        T.showFuture = not T.showFuture
        T.Update(page)
    end)
end

local function makeRow(e, p, best, maxHpm)
    local spell, rank, c = e.spell, e.rank, e.c
    local dim = e.locked or (c and not c.useful)
    local isBest = e == best
    local grey = dim and DIM or nil
    local sub = ("Rank %d · %s"):format(rank.rank, rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "instant")
    if e.locked then sub = sub .. " · not yet"
    elseif c and not c.useful then sub = sub .. " · low rank" end
    if rank.levelSource == "guess" then sub = sub .. " · level is a guess" end
    if not c then sub = sub .. " · couldn't read tooltip" end
    if spell.key == "CH" then sub = sub .. " · first target only" end
    return {
        icon = rank.icon, badge = isBest, dim = dim,
        name = spell.name, nameColor = dim and DIM or (isBest and W.GREEN or nil),
        sub = sub,
        cols = {
            tostring(rank.level or "?"),
            rank.mana and f(rank.mana) or "?",
            c and c.manaPct and (f(c.manaPct, 1) .. "%") or "?",
            c and f(c.expected) or "?",
            c and f(c.hpm, 2) or "?",
            c and f(c.hps, 1) or "?",
        },
        colColors = { grey, grey, grey, grey or W.WHITE, isBest and W.GREEN or grey or W.WHITE, grey or W.WHITE },
        meter = c and maxHpm > 0 and c.hpm / maxHpm or nil,
        meterColor = dim and DIM or HEAL_COLOR,
        tooltip = function(tt)
            tt:AddDoubleLine(spell.name, "Rank " .. rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
            tt:AddDoubleLine((rank.mana and f(rank.mana) or "?") .. " Mana",
                rank.cast and rank.cast > 0 and (f(rank.cast, 1) .. " sec cast") or "Instant", 1, 1, 1, 1, 1, 1)
            if rank.desc then tt:AddLine(rank.desc, 1, 0.82, 0, true) end
            tt:AddLine(" ")
            if c then
                local h = rank.heal
                W.AddMath(tt, {
                    { "Base heal (tooltip)", h.min == h.max and f(h.min) or (f(h.min) .. " to " .. f(h.max)) },
                    ("%s avg + %s healing power × %s = %s"):format(f(c.avgBase, 1), f(c.bonus), f(c.coef, 3), f(c.avgBase + c.bonus * c.coef, 1)),
                    ("× crit chance %s%% → %s per cast%s"):format(f(p.spellCrit or 0, 1), f(c.expected, 1), h.hot and " (plus the heal over time)" or ""),
                    ("%s ÷ %s mana = %s healing per mana"):format(f(c.expected, 1), f(c.mana), f(c.hpm, 2)),
                    ("%s ÷ %s sec = %s healing per second"):format(f(c.expected, 1), f(c.time, 1), f(c.hps, 1)),
                })
                tt:AddLine(" ")
                tt:AddDoubleLine("% of your mana", f(c.manaPct or 0, 1) .. "%", 1, 0.82, 0, 1, 1, 1)
                if p.mana then
                    tt:AddDoubleLine("Casts per full mana bar", f(math.floor(p.mana / c.mana)), 1, 0.82, 0, 1, 1, 1)
                    tt:AddDoubleLine("Healing per full mana bar", f(math.floor(p.mana / c.mana) * c.expected), 1, 0.82, 0, 0.12, 1, 0)
                end
                if spell.key == "CH" then
                    tt:AddLine(" ")
                    tt:AddLine("Chain Heal also jumps to more people. Only the first target is counted here.", 0.6, 0.6, 0.6, true)
                end
            else
                tt:AddLine("The addon couldn't read this rank's numbers from the game.", 1, 0.3, 0.2, true)
            end
            W.AddNote(tt, "Base healing, mana and cast time come from the game. Healing power share, crit (+50%) and the low-rank penalty are old Classic rules until we test them in Forever. Overhealing isn't counted.")
        end,
    }
end

function T.Update(page)
    page.future:SetText(T.showFuture and "Hide higher ranks" or "Show higher ranks")
    local p = ns.Profile.Player()
    local entries = {}
    for _, spell in ipairs(ns.RANKS) do
        if spell.kind == "heal" then
            for _, rank in ipairs(ns.SpellData.Ranks(spell.key)) do
                local locked = rank.level and rank.level > p.level
                if T.showFuture or not locked then
                    entries[#entries + 1] = { spell = spell, rank = rank, c = ns.SpellMath.CalcHeal(spell, rank, p), locked = locked }
                end
            end
        end
    end
    ns.SpellMath.MarkUseful(entries, "hps")
    local maxHpm, best, bestHps = 0, nil, nil
    for _, e in ipairs(entries) do
        if e.c and not e.locked then
            maxHpm = math.max(maxHpm, e.c.hpm)
            if e.c.useful and (not best or e.c.hpm > best.c.hpm) then best = e end
            if not bestHps or e.c.hps > bestHps.c.hps then bestHps = e end
        end
    end
    page.chips[1]:Set("Healing power", f(p.healing or 0))
    page.chips[2]:Set("Most healing per mana", best and (best.spell.name .. " R" .. best.rank.rank .. ": " .. f(best.c.hpm, 2)) or "-",
        best and W.GREEN or nil)
    page.chips[3]:Set("Fastest healing", bestHps and (bestHps.spell.name .. " R" .. bestHps.rank.rank .. ": " .. f(bestHps.c.hps, 1) .. "/s") or "-")

    local rows, lastKey = {}, nil
    if #entries == 0 then rows[1] = { header = "No healing spells found yet. Wait a few seconds, or type /es check" } end
    for _, e in ipairs(entries) do
        if e.spell.key ~= lastKey then
            rows[#rows + 1] = { header = e.spell.name, headerIcon = e.rank.icon }
            lastKey = e.spell.key
        end
        rows[#rows + 1] = makeRow(e, p, best, maxHpm)
    end
    page.list:SetRows(rows)
end
