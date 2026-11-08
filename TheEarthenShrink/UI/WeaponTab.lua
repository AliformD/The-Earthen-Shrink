-- The Earthen Shrink: Weapon Buffs tab
--
-- Shows Rockbiter, Flametongue and Windfury at the highest rank for your
-- level, how much DPS each adds, and the math behind it.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.weapon = T

local ICON = { RB = 136086, FT = 135814, WF = 136018 }   -- fallback icons if the game has none
local f = function(...) return ns.fmt(...) end

-- Rows for the buff comparison. Shared with the Inspect tab.
function ns.ImbueRows(p, list)
    local rows = { { header = "Weapon buffs at the highest rank for level " .. (p.level or "?") } }
    local top = list[1] and list[1].calc and list[1].calc.dps or 0
    for i, e in ipairs(list) do
        local c, r = e.calc, e.rank
        local best = i == 1 and c ~= nil
        local sub
        if r then
            sub = ("Rank %d · learned at level %s%s"):format(r.rank, r.level or "?",
                r.levelSource == "guess" and " (guess)" or "")
        else
            sub = "Not available yet at this level"
        end
        if r and not c then sub = sub .. " · " .. (e.reason or "") end
        rows[#rows + 1] = {
            icon = (r and r.icon) or ICON[e.key],
            name = e.name .. (best and "  |cff1eff00(best)|r" or ""),
            sub = sub,
            cols = { r and ("Rank " .. r.rank) or "-", c and ("+" .. f(c.dps, 1)) or "-" },
            colColors = { nil, best and W.GREEN or W.WHITE },
            meter = c and top > 0 and c.dps / top or nil,
            tooltip = function(tt)
                tt:AddLine(e.name .. (r and ("  (Rank " .. r.rank .. ")") or ""), 1, 1, 1)
                if r and r.desc then tt:AddLine(r.desc, 1, 0.82, 0, true) end
                tt:AddLine(" ")
                if c then
                    W.AddMath(tt, c.lines)
                    tt:AddLine(" ")
                    tt:AddDoubleLine("DPS added", "+" .. f(c.dps, 1), 1, 0.82, 0, 0.12, 1, 0)
                else
                    tt:AddLine("Can't calculate: " .. (e.reason or "?"), 1, 0.3, 0.2, true)
                end
                W.AddNote(tt, "Numbers in the tooltip text come from the game. The 14 AP = 1 DPS, miss, dodge and crit rules are old Classic rules until we test them in Forever.")
            end,
        }
    end
    return rows
end

-- Rows showing the numbers the math used, so you can check them.
-- Each one has its own icon, says whether it's exact or an estimate, and
-- explains in the tooltip which weapon buff it matters for.
local STAT_INFO = {
    weapon = { icon = "Interface\\Icons\\INV_Axe_04", tip = "Your main-hand weapon. Its speed matters most: slow weapons get more from Windfury and Flametongue per hit." },
    ap     = { icon = "Interface\\Icons\\Ability_Warrior_BattleShout", tip = "Attack power. Every 14 adds 1 DPS. Windfury's extra attacks use it, so more AP makes Windfury better." },
    mcrit  = { icon = "Interface\\Icons\\Ability_CriticalStrike", tip = "Melee crit chance. Makes Rockbiter and Windfury hits crit more often." },
    scrit  = { icon = "Interface\\Icons\\Spell_Nature_StormReach", tip = "Spell crit chance. Flametongue's fire damage uses this one." },
    hit    = { icon = "Interface\\Icons\\Ability_Marksmanship", tip = "Hit from gear lowers your miss chance. Every buff here only works on hits that land." },
    sp     = { icon = "Interface\\Icons\\Spell_Nature_Lightning", tip = "Nature spell power. Used by Lightning Bolt, Earth Shock and Lightning Shield, not by weapon buffs." },
    mana   = { icon = "Interface\\Icons\\INV_Potion_76", tip = "Your mana pool. The Spell Efficiency tab uses it for '% of mana' and 'casts per mana bar'." },
}

function ns.ProfileRows(p)
    local w = p.weapon or {}
    local rows = { { header = "Numbers used" } }
    local function add(key, name, value, estKey)
        local info = STAT_INFO[key]
        local est = estKey and p.estimated and p.estimated[estKey]
        local icon = info.icon
        if key == "weapon" and p.unit then
            icon = ns.try(GetInventoryItemTexture, p.unit, 16) or icon
        end
        rows[#rows + 1] = {
            icon = icon, name = name,
            sub = est and "|cffff8000estimate|r · from gear and level" or "|cff1eff00exact|r · read from the game",
            cols = { "", value },
            tooltip = function(tt)
                tt:AddDoubleLine(name, value, 1, 1, 1, 1, 1, 1)
                tt:AddLine(info.tip, 1, 0.82, 0, true)
                if est then W.AddNote(tt, "We can't read another player's stats, so this is worked out from their gear and level with old Classic rules.") end
            end,
        }
    end
    add("weapon", w.name or "Main hand", w.min and (f(w.min) .. " - " .. f(w.max) .. " @ " .. f(w.speed or 0, 2)) or "none")
    add("ap", "Attack power", f(p.ap or 0), "ap")
    add("mcrit", "Melee crit", f(p.meleeCrit or 0, 2) .. "%", "meleeCrit")
    add("scrit", "Spell crit", f(p.spellCrit or 0, 2) .. "%", "spellCrit")
    add("hit", "Hit from gear", f(p.hit or 0) .. "%")
    add("sp", "Spell power (Nature)", f(p.sp and p.sp.Nature or 0))
    add("mana", "Max mana", f(p.mana or 0), "mana")
    return rows
end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    page.chips = W.Chips(page, 3, width)
    for _, c in ipairs(page.chips) do c:SetParent(page) end
    page.list = W.List(page, width, 330, { { title = "Rank", width = 60 }, { title = "+DPS", width = 70 } }, 2)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Buff")

    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -170, 0)
    page.note:SetText("Hover a row for the math. We assume you bought the highest rank for your level.")

    page.post = W.Button(page, "Post to chat", 150)
    page.post:SetPoint("BOTTOMRIGHT", 0, 0)
    page.post:SetScript("OnClick", function()
        if page.message then ns.Chat.OpenInChatBox(page.message) end
    end)
end

function T.Update(page)
    local p = ns.Profile.Player()
    local list = ns.ImbueMath.Compare(p)
    local best = list[1]
    page.chips[1]:Set("Level", tostring(p.level))
    page.chips[2]:Set("Best weapon buff", best and best.calc and (best.name:gsub(" Weapon", "") .. " +" .. f(best.calc.dps, 1) .. " DPS") or "-",
        best and best.calc and W.GREEN or nil)
    local w = p.weapon
    page.chips[3]:Set("Main hand", w and w.min and (f(w.min) .. "-" .. f(w.max) .. " @ " .. f(w.speed or 0, 2)) or "no weapon")

    local rows = ns.ImbueRows(p, list)
    if p.hasImbueNow then
        rows[#rows + 1] = { header = "Note: a weapon buff is on now. If it's Rockbiter, its AP is already in your stats." }
    end
    for _, r in ipairs(ns.ProfileRows(p)) do rows[#rows + 1] = r end
    page.list:SetRows(rows)

    page.message = ns.Chat.Build(p, list)
    if page.message then page.post:Enable() else page.post:Disable() end
end
