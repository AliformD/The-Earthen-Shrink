-- The Earthen Shrink: Weapon Buffs tab
--
-- Shows Rockbiter, Flametongue, Frostbrand and Windfury at the highest rank
-- for your level. Each one is tested on 50 simulated main-hand swings with
-- your real gear (see Math/Imbues.lua), and the best is marked.
-- Below that are the settings the math depends on (click to change).

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.weapon = T

local ICON = { RB = 136086, FT = 135814, FB = "Interface\\Icons\\Spell_Frost_FrostBrand", WF = 136018 }   -- fallback icons if the game has none
local f = function(...) return ns.fmt(...) end

-- Rows for the buff comparison. Shared with the Inspect tab.
function ns.ImbueRows(p, list)
    local swings = ns.db().swings or 50
    local rows = { { header = ("Weapon buffs: %d simulated swings, highest rank for level %s"):format(swings, p.level or "?") } }
    local top = list[1] and list[1].calc and list[1].calc.dps or 0
    for i, e in ipairs(list) do
        local c, r = e.calc, e.rank
        local best = i == 1 and c ~= nil
        local sub
        if r then
            sub = ("Rank %d · level %s%s"):format(r.rank, r.level or "?",
                r.levelSource == "guess" and " (guess)" or "")
            if c then
                sub = sub .. (" · +%s dmg in %d swings"):format(f(c.total), swings)
                if c.fromFallback then sub = sub .. " · |cffff8000built-in numbers|r" end
            end
        else
            sub = "Not available yet at this level"
        end
        if r and not c then sub = sub .. " · |cffff8000" .. (e.reason or "") .. "|r" end
        rows[#rows + 1] = {
            icon = (r and r.icon) or ICON[e.key],
            name = e.name .. (best and "  |cff1eff00(best)|r" or ""),
            sub = sub,
            cols = { c and ("+" .. f(c.perSwing, 1)) or "-", c and ("+" .. f(c.dps, 1)) or "-" },
            colColors = { nil, best and W.GREEN or W.WHITE },
            meter = c and top > 0 and math.max(0, c.dps) / top or nil,
            dim = not c,
            tooltip = function(tt)
                tt:AddLine(e.name .. (r and ("  (Rank " .. r.rank .. ")") or ""), 1, 1, 1)
                if r and r.desc then tt:AddLine(r.desc, 1, 0.82, 0, true) end
                tt:AddLine(" ")
                if c then
                    W.AddMath(tt, c.lines)
                    tt:AddLine(" ")
                    tt:AddDoubleLine("DPS added", "+" .. f(c.dps, 1), 1, 0.82, 0, 0.12, 1, 0)
                    if c.fromFallback then
                        W.AddNote(tt, "The game didn't give us this tooltip's text, so these numbers are the built-in ones (" ..
                            (ns.IMBUE_FALLBACK[e.key][r.rank].source or "?") .. "). Type /es check to see what the game sent.")
                    end
                else
                    tt:AddLine("Can't calculate: " .. (e.reason or "?"), 1, 0.3, 0.2, true)
                    if r and e.reason and e.reason:find("tooltip") then
                        W.AddNote(tt, "The addon reads numbers out of the spell's tooltip text. Either the game hasn't sent the text yet (wait a few seconds), or the words are different from what we expect. Type /es check and send a screenshot of the chat so we can fix the reader.")
                    end
                end
                W.AddNote(tt, "Each buff is tested on the same simulated swings with your weapon, attack power and crit. The 14 AP = 1 DPS, miss, dodge and crit rules are old Classic rules until we test them in Forever.")
            end,
        }
    end
    return rows
end

-- Settings rows. Click one to change it.
function ns.ImbueSettingRows(p)
    local set, IM = ns.db(), ns.ImbueMath
    local rows = { { header = "Settings (click a row to change it)" } }
    local totem, why = IM.TotemProc(p)
    rows[#rows + 1] = {
        icon = (totem and totem.rank.icon) or "Interface\\Icons\\Spell_Nature_Windfury", name = "Windfury Totem in your group",
        sub = set.wfTotem and (totem and ("On · %d%% chance, %d extra attack(s), +%d AP (tooltip)"):format(totem.chance, totem.attacks, totem.ap)
            or ("|cffff8000On, but " .. (why or "?") .. "|r")) or "Off",
        cols = { "", set.wfTotem and "On" or "Off" },
        colColors = { nil, set.wfTotem and W.GREEN or W.GREY },
        onClick = function() IM.Slash("wftotem") end,
        tooltip = function(tt)
            tt:AddLine("Windfury Totem in your group", 1, 1, 1)
            tt:AddLine("Turn this on if a Shaman (you or someone else) keeps Windfury Totem down. Then every buff is tested with the totem's extra attacks too.", 1, 0.82, 0, true)
            W.AddNote(tt, "Also: /es wftotem on or /es wftotem off")
        end,
    }
    rows[#rows + 1] = {
        icon = 136018, name = "Totem stacks with Windfury Weapon",
        sub = set.wfStacks and "Yes · expected after the Nov 2026 hotfix" or "No · old rule: Windfury Weapon turns off the totem for you",
        cols = { "", set.wfStacks and "Yes" or "No" },
        colColors = { nil, set.wfStacks and W.GREEN or W.GREY },
        onClick = function() IM.Slash("wfstack") end,
        tooltip = function(tt)
            tt:AddLine("Does Windfury Totem stack with Windfury Weapon?", 1, 1, 1)
            tt:AddLine("The rank 1 tooltip says Windfury Weapon \"disables any benefit you personally receive from Windfury Totem\". A hotfix is changing that so both work. Only matters when Windfury Totem is on.", 1, 0.82, 0, true)
            W.AddNote(tt, "Not tested in game yet: we assume each one rolls its own chance on every hit. Also: /es wfstack on|off")
        end,
    }
    local coef = set.ftCoef or 0
    rows[#rows + 1] = {
        icon = 135814, name = "Flametongue spell power bonus",
        sub = "|cffff8000Unverified|r · share of your Fire spell power added to each Flametongue hit",
        cols = { "", f(coef * 100, 0) .. "%" },
        colColors = { nil, coef > 0 and W.ORANGE or W.GREY },
        onClick = function() IM.CycleFtCoef() end,
        tooltip = function(tt)
            tt:AddLine("Flametongue spell power bonus (unverified)", 1, 1, 1)
            tt:AddLine("Players say Flametongue gets stronger with spell power, but nobody has shown the number for Forever yet. It's 0% until we test it. Click to try other values and see how the ranking changes.", 1, 0.82, 0, true)
            tt:AddDoubleLine("Your Fire spell power", f(p.sp and p.sp.Fire or 0), 1, 0.82, 0, 1, 1, 1)
            W.AddNote(tt, "Exact value: /es ftcoef 0.1 (= 10%)")
        end,
    }
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
    page.list = W.List(page, width, 330, { { title = "Per swing", width = 70 }, { title = "+DPS", width = 70 } }, 2)
    page.list.frame:SetPoint("TOPLEFT", 0, -52)
    page.list:SetNameTitle("Buff")

    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", 0, 4)
    page.note:SetPoint("RIGHT", -170, 0)
    page.note:SetText("Hover a row for the math. Click a setting to change it. We assume you bought the highest rank for your level.")

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
    local ctx = ns.ImbueMath.lastCtx
    if ctx and ctx.removedRB then
        rows[#rows + 1] = { header = ("Rockbiter is on now: took its %d AP out of your stats for the test"):format(ctx.removedRB) }
    end
    for _, r in ipairs(ns.ImbueSettingRows(p)) do rows[#rows + 1] = r end
    for _, r in ipairs(ns.ProfileRows(p)) do rows[#rows + 1] = r end
    page.list:SetRows(rows)

    page.message = ns.Chat.Build(p, list)
    if page.message then page.post:Enable() else page.post:Disable() end
end
