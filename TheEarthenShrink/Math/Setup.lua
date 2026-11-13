-- The Earthen Shrink: best weapon buff + totem setup
--
-- Angel's question after the shaman patch (2026-11-13): which weapon buff
-- and which Air/Fire totems give the most damage now?
--
-- The rules Angel saw in game:
--   * Windfury Totem stacks with Windfury Weapon, Flametongue Totem stacks
--     with Flametongue Weapon (the totem that matches your buff adds on top).
--   * A player only gets ONE of Windfury Totem / Flametongue Totem, even if
--     both are on the ground. So you pick one:
--       - Windfury Totem (Air) leaves your Fire spot free for Searing Totem
--         (one target) or Magma Totem (many targets).
--       - Flametongue Totem uses the Fire spot, so no Searing or Magma.
--
-- How we test it: for every weapon buff and every totem plan we run the
-- Sim Lab's full damage mix (Math/Rotation.lua: swings, buff, Stormstrike,
-- shocks, Lightning Shield, fire totem) and compare the totals.
--
-- "Group" adds what the totem gives the OTHER melee players in your party.
-- We can't see their weapons or attack power, so 🔶 we use YOUR weapon and
-- attack power as a stand-in for each of them, with no weapon buff of their
-- own. Searing and Magma Totem only count once (they don't help others).
--
-- C# comparison: a static class with one method that loops over two lists
-- (buffs × plans) and returns a sorted List of results.

local _, ns = ...
local SU = {}
ns.Setup = SU

local f = function(...) return ns.fmt(...) end

-- Totem plans. air/fire = which totem goes in that spot.
SU.PLANS = {
    { key = "WFT+ST", air = "WFT", fire = "ST",  name = "Windfury Totem + Searing Totem" },
    { key = "WFT+MT", air = "WFT", fire = "MT",  name = "Windfury Totem + Magma Totem", aoe = true },
    { key = "FTT",    fire = "FTT",              name = "Flametongue Totem (no fire damage totem)" },
    { key = "ST",     fire = "ST",               name = "Searing Totem, no Windfury Totem" },
    { key = "MT",     fire = "MT",               name = "Magma Totem, no Windfury Totem", aoe = true },
}

-- Settings: enemies for the AoE plans (1 = one target, Magma plans hidden),
-- and how many OTHER melee players are in your party for "Group".
function SU.Targets() return math.max(1, math.min(10, tonumber(ns.db().setupTargets) or 1)) end
function SU.GroupMelee() return math.max(0, math.min(4, tonumber(ns.db().groupMelee) or 3)) end

local function learned(key, q)
    return ns.SpellData.Best(key, q.level or 1, q) ~= nil
end

-- What the group's totem gives ONE other melee player per second (using
-- your weapon and attack power as a stand-in, no weapon buff of theirs).
local function perMember(q, ctx, plan)
    local IM = ns.ImbueMath
    if not (ctx and q.weapon and q.weapon.speed and q.weapon.speed > 0) then return 0 end
    local none = IM.Swing(q, ctx, { procs = {} })
    local with
    if plan.air == "WFT" and ctx.totem then
        with = IM.Swing(q, ctx, { procs = { ctx.totem } })
    elseif plan.fire == "FTT" and ctx.ftTotem then
        with = IM.Swing(q, ctx, { procs = {}, onHit = ctx.ftTotemHit })
    else
        return 0
    end
    return (with - none) / q.weapon.speed
end

-- Runs every weapon buff × totem plan. q = a profile (your real one).
-- Returns a list, best SOLO first:
--   { buff = "WF", buffName, plan, solo, group, member, total = R.Total result }
-- and a list of plans that couldn't be tested, with why.
function SU.Compare(q)
    local IM, R = ns.ImbueMath, ns.Rotation
    local targets, others = SU.Targets(), SU.GroupMelee()
    local style = R.STYLE_BY_ID.enh
    local out, skipped = {}, {}
    if not (q.weapon and q.weapon.min and q.weapon.speed) then return out, { "no weapon found" } end

    for _, plan in ipairs(SU.PLANS) do
        local why
        if plan.aoe and targets < 2 then why = "AoE plan (set enemies to 2 or more)"
        elseif plan.air == "WFT" and not learned("WFT", q) then why = "Windfury Totem not learned"
        elseif plan.fire == "FTT" and not learned("FTT", q) then why = "Flametongue Totem not learned"
        elseif (plan.fire == "ST" or plan.fire == "MT") and not learned(plan.fire, q) then
            why = (plan.fire == "MT" and "Magma" or "Searing") .. " Totem not learned"
        end
        if why then
            if not (plan.aoe and targets < 2) then skipped[#skipped + 1] = plan.name .. ": " .. why end
        else
            for _, key in ipairs(IM.ORDER) do
                if learned(key, q) then
                    IM.override = { wfTotem = plan.air == "WFT", ftTotem = plan.fire == "FTT" }
                    local ok, res = pcall(R.Total, q, { style = style, imbueKey = key, fireTotem = plan.fire, targets = targets })
                    local ctx = IM.lastCtx
                    local member = ok and perMember(q, ctx, plan) or 0
                    IM.override = nil
                    local hasBuff = false
                    if ok then for _, part in ipairs(res.parts) do if part.imbueKey == key then hasBuff = true end end end
                    if ok and hasBuff then
                        out[#out + 1] = {
                            buff = key, buffName = IM.SHORT[key], plan = plan,
                            solo = res.total, member = member, group = res.total + member * others,
                            total = res,
                        }
                    end
                end
            end
        end
    end
    IM.override = nil
    -- Put the normal settings' numbers back (Compare remembers its last run).
    pcall(IM.Compare, q)
    table.sort(out, function(a, b) return a.solo > b.solo end)
    return out, skipped
end

-- The best entry for "group" (a different order than solo).
function SU.BestGroup(list)
    local best
    for _, e in ipairs(list) do if not best or e.group > best.group then best = e end end
    return best
end

-- One line for chat or a row: "Windfury + Windfury Totem + Searing Totem".
function SU.Label(e)
    return e.buffName .. " Weapon + " .. e.plan.name
end

---------------------------------------------------------------------------
-- Rows for the Weapon Buffs tab
---------------------------------------------------------------------------
function SU.Rows(p)
    local W = ns.Widgets
    local list, skipped = SU.Compare(p)
    local targets, others = SU.Targets(), SU.GroupMelee()
    local rows = { { header = ("Best setup: weapon buff + totems · left = your DPS, right = with %d other melee in party · %s"):format(
        others, targets > 1 and (targets .. " enemies") or "1 enemy") } }
    if #list == 0 then
        rows[#rows + 1] = { name = "Can't compare yet", sub = (skipped[1] or "nothing learned yet"), dim = true, cols = { "-", "-" } }
        return rows
    end
    local topSolo, bestGroup = list[1].solo, SU.BestGroup(list)
    for i, e in ipairs(list) do
        if i > 8 then break end
        local isSolo, isGroup = i == 1, e == bestGroup
        local tags = (isSolo and "  |cff1eff00(best solo)|r" or "") .. (isGroup and "  |cff3fc7eb(best group)|r" or "")
        local diff = e.solo - topSolo
        rows[#rows + 1] = {
            icon = ns.SpellData.Best(e.buff, p.level or 1, p) and ns.SpellData.Best(e.buff, p.level or 1, p).icon,
            name = SU.Label(e) .. tags,
            sub = (diff < -0.05 and ("%s DPS less than the best solo"):format(f(-diff, 1)) or "your whole damage mix")
                .. (e.member > 0 and (" · totem gives each other melee +%s DPS 🔶"):format(f(e.member, 1)) or ""),
            cols = { f(e.solo, 1), f(e.group, 1) },
            colColors = { isSolo and W.GREEN or W.WHITE, isGroup and W.GREEN or W.WHITE },
            meter = topSolo > 0 and math.max(0, e.solo) / topSolo or nil,
            tooltip = function(tt)
                tt:AddLine(SU.Label(e), 1, 1, 1)
                tt:AddLine("Your whole damage mix with this weapon buff and these totems (same math as the Sim Lab's Total view).", 1, 0.82, 0, true)
                tt:AddLine(" ")
                for _, part in ipairs(e.total.parts) do
                    tt:AddDoubleLine(part.name, f(part.dps, 1) .. " DPS", 0.91, 0.89, 0.78, 1, 1, 1)
                end
                tt:AddDoubleLine("Your total", f(e.solo, 1) .. " DPS", 1, 0.82, 0, 0.12, 1, 0)
                if e.member > 0 then
                    tt:AddDoubleLine(("+ %d other melee × %s"):format(others, f(e.member, 1)), "+" .. f(e.member * others, 1) .. " DPS", 1, 0.82, 0, 1, 1, 1)
                end
                tt:AddDoubleLine("Group total", f(e.group, 1) .. " DPS", 1, 0.82, 0, 0.12, 1, 0)
                W.AddNote(tt, "Rules (Angel, in game after the patch): the totem that matches your weapon buff stacks with it, but a player only gets ONE of Windfury Totem or Flametongue Totem. Flametongue Totem takes your Fire spot, so no Searing or Magma with it.")
                W.AddNote(tt, "🔶 Other melee use YOUR weapon and attack power as a stand-in. Totem mana for Windfury/Flametongue Totem isn't counted. Maelstrom Weapon isn't in the math yet.")
            end,
        }
    end
    for _, s in ipairs(skipped) do
        rows[#rows + 1] = { name = "|cff9d9d9dNot tested:|r " .. s, dim = true, cols = { "", "" } }
    end
    return rows
end

-- Setting rows (click to change).
function SU.SettingRows()
    local W = ns.Widgets
    local targets, others = SU.Targets(), SU.GroupMelee()
    return {
        {
            icon = 135826, name = "Enemies (for Magma Totem)",
            sub = targets > 1 and ("%d enemies · Magma Totem plans are tested"):format(targets) or "1 enemy · Magma Totem plans are hidden",
            cols = { "", tostring(targets) },
            colColors = { nil, targets > 1 and W.ORANGE or W.GREY },
            onClick = function() ns.db().setupTargets = targets >= 5 and 1 or targets + 1; ns.refresh("settings") end,
            tooltip = function(tt)
                tt:AddLine("How many enemies are in the fight", 1, 1, 1)
                tt:AddLine("Magma Totem hits every enemy near it, so it only wins with more than one. Click to go 1, 2, 3, 4, 5. Also: /es aoe 3", 1, 0.82, 0, true)
            end,
        },
        {
            icon = 136018, name = "Other melee in your party",
            sub = ("%d · each one gets your Windfury or Flametongue Totem too"):format(others),
            cols = { "", tostring(others) },
            onClick = function() ns.db().groupMelee = others >= 4 and 0 or others + 1; ns.refresh("settings") end,
            tooltip = function(tt)
                tt:AddLine("Other melee players in your party", 1, 1, 1)
                tt:AddLine("Warriors, Rogues and other melee get your Air or Fire totem's buff. Casters and healers don't. Click to go 0 to 4. Also: /es groupmelee 2", 1, 0.82, 0, true)
            end,
        },
    }
end

---------------------------------------------------------------------------
-- /es setup (chat), /es aoe N, /es groupmelee N
---------------------------------------------------------------------------
function SU.Slash(msg)
    local cmd, arg = msg:match("^(%a+)%s*(.-)$")
    local n = tonumber(arg)
    if cmd == "aoe" and n then ns.db().setupTargets = math.max(1, math.min(10, math.floor(n)))
    elseif cmd == "groupmelee" and n then ns.db().groupMelee = math.max(0, math.min(4, math.floor(n))) end
    local p = ns.Profile.Player()
    local list, skipped = SU.Compare(p)
    if #list == 0 then ns.say("best setup: can't compare yet (" .. (skipped[1] or "nothing learned") .. ").") return end
    ns.say(("best setup (%s, %d other melee):"):format(SU.Targets() > 1 and (SU.Targets() .. " enemies") or "1 enemy", SU.GroupMelee()))
    for i = 1, math.min(5, #list) do
        local e = list[i]
        ns.say(("  %d. %s: %s DPS solo, %s group"):format(i, SU.Label(e), f(e.solo, 1), f(e.group, 1)))
    end
    local g = SU.BestGroup(list)
    if g ~= list[1] then ns.say("  best for the group: " .. SU.Label(g)) end
    ns.refresh("settings")
end
