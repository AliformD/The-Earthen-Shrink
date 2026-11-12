-- The Earthen Shrink: Sim Lab tab
--
-- Try stats without wearing them. Move a slider ("+17 Strength") or put an
-- item in the box at the top, and see how hard each spell would hit next to
-- what it hits for now.
--
-- Getting an item into the box (while the Sim Lab is open):
--   * Shift-click any item: in your bags, on your character, a link in chat,
--     or in a loot-list addon. (Shift-click is the same click that puts a
--     link in chat, so it works anywhere the game lets you link an item.)
--   * Or pick the item up and drop it on the box.
-- The item's stats are compared with what you wear in that slot, and the
-- sliders are set to the difference.
--
-- Layout (simple on purpose):
--   Left:  "1. Change stats": the sliders and your talents.
--   Right: "2. See what changes": four buttons pick ONE view at a time:
--          Spells, Weapon buff, Stat value, My stats.

local _, ns = ...
local W = ns.Widgets
local T = {}
ns.Tabs = ns.Tabs or {}
ns.Tabs.simlab = T
local f = function(...) return ns.fmt(...) end

T.add = nil          -- the slider values, like { str = 17, int = 0, ... }
T.item = nil         -- the item being tried on (see T.LoadItem)
T.metric = 1         -- which number the list shows (see METRICS)

local EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

-- What the list can show. heal = the field for healing spells.
local METRICS = {
    { name = "Per cast",   dmg = "expected", heal = "expected", melee = "expected", decimals = 0 },
    { name = "Per mana",   dmg = "dpm",      heal = "hpm",      melee = nil,        decimals = 2 },
    { name = "Per second", dmg = "dps",      heal = "hps",      melee = "dps",      decimals = 1 },
}

-- Spells shown in the list, in this order. Each one uses your highest rank.
local SPELL_KEYS = { "LB", "CL", "ES", "FlS", "FrS", "LvB", "SS", "HW", "LHW", "CH" }

local function calc(spell, rank, p)
    local M = ns.SpellMath
    if spell.kind == "spell" then return M.Calc(spell, rank, p) end
    if spell.kind == "strike" then return M.CalcStrike(spell, rank, p) end
    if spell.kind == "heal" then return M.CalcHeal(spell, rank, p) end
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

local function buildItemBox(page, width)
    local box = W.Panel(page)
    box:SetSize(width, 52)
    box:SetPoint("TOPLEFT", 0, 0)
    page.itemBox = box

    local btn = W.Create("Button", nil, box, { "BackdropTemplate" })
    btn:SetSize(40, 40)
    btn:SetPoint("LEFT", 6, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(EMPTY_SLOT)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    page.itemButton = btn

    -- Dropping an item: the game calls OnReceiveDrag, or OnClick if you
    -- click while holding it.
    local function takeFromCursor()
        local kind, _, link = ns.try(GetCursorInfo)
        if kind == "item" and link then
            ClearCursor()
            T.LoadItem(link)
            return true
        end
    end
    btn:SetScript("OnReceiveDrag", takeFromCursor)
    btn:SetScript("OnClick", function(_, mouse)
        if takeFromCursor() then return end
        if mouse == "RightButton" then T.Clear() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if T.item and T.item.link and GameTooltip.SetHyperlink then
            pcall(GameTooltip.SetHyperlink, GameTooltip, T.item.link)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Right-click to take it out.", 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine("Try on an item", 1, 1, 1)
            GameTooltip:AddLine("Shift-click any item while this page is open: in your bags, on your character, a link in chat, or in a loot-list addon. You can also drop an item here.", 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    page.itemName = W.OneLine(W.Text(box, "GameFontNormal", nil, "LEFT"))
    page.itemName:SetPoint("TOPLEFT", btn, "TOPRIGHT", 10, -3)
    page.itemName:SetPoint("RIGHT", -210, 0)
    page.itemSub = W.OneLine(W.Text(box, "GameFontDisableSmall", nil, "LEFT"))
    page.itemSub:SetPoint("BOTTOMLEFT", btn, "BOTTOMRIGHT", 10, 3)
    page.itemSub:SetPoint("RIGHT", -210, 0)

    page.clear = W.Button(box, "Clear", 80)
    page.clear:SetPoint("RIGHT", -8, 0)
    page.clear:SetScript("OnClick", function() T.Clear() end)
    -- Rings, trinkets and one-hand weapons fit in two slots.
    page.otherSlot = W.Button(box, "Other slot", 110)
    page.otherSlot:SetPoint("RIGHT", page.clear, "LEFT", -6, 0)
    page.otherSlot:SetScript("OnClick", function()
        local it = T.item
        if it and it.slots and #it.slots > 1 then
            it.which = it.which % #it.slots + 1
            T.ApplyItem()
        end
    end)
end

local function buildSliders(page, top, height)
    local panel = W.Panel(page)
    panel:SetSize(300, height)
    panel:SetPoint("TOPLEFT", 0, top)

    local title = W.Text(panel, "GameFontNormalSmall", nil, "LEFT")
    title:SetPoint("TOPLEFT", 10, -7)
    title:SetText("1. CHANGE YOUR STATS")
    title:SetTextColor(0.6, 0.6, 0.6)
    local reset = W.Button(panel, "Reset", 64)
    reset:SetHeight(18)
    reset:SetPoint("TOPRIGHT", -6, -4)
    reset:SetScript("OnClick", function() T.Clear() end)

    page.sliders = {}
    for i, st in ipairs(ns.SimMath.STATS) do
        local row = W.StatSlider(panel, 280, {
            label = st.label, min = st.min, max = st.max, step = st.step, unit = st.unit,
            onChange = function(v)
                T.add[st.key] = v
                T.Update(page)
            end,
        })
        row:SetPoint("TOPLEFT", 10, -26 - (i - 1) * 38)
        page.sliders[st.key] = row
    end

    -- Mental Dexterity: we can't read talents yet, so you tick it yourself.
    local cb = W.Create("CheckButton", nil, panel, { "UICheckButtonTemplate", "ChatConfigCheckButtonTemplate" })
    cb:SetSize(20, 20)
    cb:SetPoint("BOTTOMLEFT", 6, 21)
    local label = W.Text(panel, "GameFontHighlightSmall", nil, "LEFT")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText("Mental Dexterity (Intellect gives attack power)")
    label:SetPoint("RIGHT", -6, 0)
    W.OneLine(label)
    cb:SetScript("OnClick", function(self)
        ns.db().simMentalDex = self:GetChecked() and true or false
        T.Update(page)
    end)
    page.mentalDex = cb

    -- Mental Quickness: Intellect gives spell power. Click to set your
    -- points yourself; right-click to go back to reading your talents.
    local mq = W.Create("Button", nil, panel, { "UIPanelButtonTemplate" })
    mq:SetSize(288, 18)
    mq:SetPoint("BOTTOMLEFT", 6, 3)
    mq:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mq:SetScript("OnClick", function(_, mouse)
        local S, db = ns.SimMath, ns.db()
        if mouse == "RightButton" then
            db.simMentalQuick = nil
        else
            local r = S.MentalQuickRank()
            db.simMentalQuick = (r + 1) % (S.RULES.mentalQuickMaxRank + 1)
        end
        T.Update(page)
    end)
    mq:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Mental Quickness", 1, 1, 1)
        GameTooltip:AddLine(("Each point: spell damage and healing = %s%% of your Intellect."):format(
            ns.fmt(ns.SimMath.RULES.mentalQuickSpPerIntPerRank * 100)), 1, 0.82, 0, true)
        GameTooltip:AddLine("Click to change your points. Right-click to let the addon read your talents.", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("15% per point is what Angel saw in game. The tooltip text isn't checked yet.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    mq:SetScript("OnLeave", function() GameTooltip:Hide() end)
    page.mentalQuick = mq
end

-- The four views on the right. cols = the column titles for that view.
local VIEWS = {
    { id = "spells", label = "Spells",      title = "Your spells (highest rank)",  cols = { "Now", "Try", "Change" },
      note = "Try = with your changes. Hover a row for the math." },
    { id = "weapon", label = "Weapon buff", title = "Best weapon buff (DPS added)", cols = { "Now", "Try", "Change" },
      note = "Move Spell Power or Attack Power to see when the best buff changes." },
    { id = "worth",  label = "Stat value",  title = "What 1 point is worth",       cols = { "", "DPS", "Same as" },
      note = "Uses your SP Test results. Bigger DPS = that stat helps more." },
    { id = "stats",  label = "My stats",    title = "Your stats",                  cols = { "Now", "Try", "Change" },
      note = "Now = from the game. Try = with your changes." },
}
local VIEW_BY_ID = {}
for _, v in ipairs(VIEWS) do VIEW_BY_ID[v.id] = v end

function T.View()
    local id = ns.db().simView
    return VIEW_BY_ID[id] and id or "spells"
end

function T.SetView(id)
    if not VIEW_BY_ID[id] then return end
    ns.db().simView = id
    if T.page then T.Update(T.page) end
end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    T.page = page
    T.add = T.add or ns.SimMath.Empty()
    buildItemBox(page, width)
    buildSliders(page, -58, 368)

    -- "2. See what changes": one button per view.
    local x, right = 308, width - 308
    page.viewButtons = {}
    local bw = (right - 3 * 4) / #VIEWS
    for i, v in ipairs(VIEWS) do
        local b = W.Button(page, v.label, bw)
        b:SetPoint("TOPLEFT", x + (i - 1) * (bw + 4), -58)
        b:SetScript("OnClick", function() T.SetView(v.id) end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(v.label, 1, 1, 1)
            GameTooltip:AddLine(v.note, 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        page.viewButtons[v.id] = b
    end

    page.list = W.List(page, right, 312, {
        { title = "Now", width = 54 }, { title = "Try", width = 54 }, { title = "Change", width = 56 },
    })
    page.list.frame:SetPoint("TOPLEFT", x, -86)

    page.metric = W.Button(page, "", 150)
    page.metric:SetPoint("BOTTOMRIGHT", 0, 0)
    page.metric:SetScript("OnClick", function()
        T.metric = T.metric % #METRICS + 1
        T.Update(page)
    end)
    page.note = W.OneLine(W.Text(page, "GameFontDisableSmall", nil, "LEFT"))
    page.note:SetPoint("BOTTOMLEFT", page.list.frame, "BOTTOMLEFT", 0, -20)
    page.note:SetPoint("RIGHT", 0, 0)
end

---------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------

function T.Clear()
    T.item = nil
    T.add = ns.SimMath.Empty()
    if T.page then T.Update(T.page) end
end

-- Reads an item link and puts it in the box. The game may not have the
-- item loaded yet (an item you've never seen), so it asks and tries again.
function T.LoadItem(link, tries)
    tries = tries or 6
    local new, loaded = ns.Profile.LinkStats(link)
    if not loaded and tries > 0 then
        local id = tonumber(link:match("item:(%d+)"))
        if id and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
        C_Timer.After(0.3, function() T.LoadItem(link, tries - 1) end)
        return
    end
    local slots = ns.SimMath.SlotsFor(link)
    new.name = link:match("%[(.-)%]")
    T.item = { link = link, new = new, slots = slots, which = 1 }
    if not slots then
        T.item.error = "This item can't be worn, so there's nothing to try on."
        if T.page then T.Update(T.page) end
        return
    end
    T.ApplyItem()
end

-- Compares the item with what you wear in its slot and sets the sliders.
function T.ApplyItem()
    local it = T.item
    local slot = it.slots[it.which]
    local old, oldLink = ns.Profile.ItemStats("player", slot)
    it.slot, it.oldLink = slot, oldLink
    T.add, it.weapon, it.other = ns.SimMath.ItemDelta(it.new, old, slot)
    if T.page then T.Update(T.page) end
end

-- Shift-clicking an item anywhere in the game while the Sim Lab is open.
-- Both of these game functions run on a shift-click; the time check stops
-- one click from loading the item twice.
local lastLink, lastTime = nil, 0
local function onLinkClick(link)
    if type(link) ~= "string" or not link:find("|Hitem:") then return end
    if not (ns.UI.IsShowing and ns.UI.IsShowing("simlab")) then return end
    local now = GetTime and GetTime() or 0
    if link == lastLink and now - lastTime < 0.3 then return end
    lastLink, lastTime = link, now
    T.LoadItem(link)
end

if hooksecurefunc then
    if HandleModifiedItemClick then
        hooksecurefunc("HandleModifiedItemClick", function(link)
            if (IsModifiedClick and IsModifiedClick("CHATLINK")) or (IsShiftKeyDown and IsShiftKeyDown()) then
                onLinkClick(link)
            end
        end)
    end
    if ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", onLinkClick) end
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

local function change(now, try, decimals)
    if not now or not try then return "", nil end
    local d = try - now
    if math.abs(d) < 0.0005 then return "-", W.GREY end
    local col = d > 0 and W.GREEN or { 1, 0.29, 0.23 }
    if now ~= 0 then
        local pct = d / now * 100
        if math.abs(pct) < 0.05 then return (d > 0 and "+" or "-") .. "0.1%", col end  -- tiny, but not zero
        return (d > 0 and "+" or "") .. f(pct, 1) .. "%", col
    end
    return (d > 0 and "+" or "") .. f(d, decimals), col
end

local function addWhy(tt, why)
    if #why == 0 then return end
    tt:AddLine(" ")
    tt:AddLine("Where the change comes from", 1, 0.82, 0)
    for _, l in ipairs(why) do tt:AddLine(l, 0.91, 0.89, 0.78, true) end
end

local function updateItemBox(page)
    local it = T.item
    page.otherSlot:SetShown(it and it.slots and #it.slots > 1 or false)
    if not it then
        page.itemButton.icon:SetTexture(EMPTY_SLOT)
        page.itemName:SetText("Try on any item")
        page.itemName:SetTextColor(1, 0.82, 0)
        page.itemSub:SetText("Shift-click an item (bags, chat, loot lists) or drop it on the box.")
        return
    end
    local id = tonumber(it.link:match("item:(%d+)"))
    local icon = id and C_Item and C_Item.GetItemIconByID and ns.try(C_Item.GetItemIconByID, id)
    page.itemButton.icon:SetTexture(icon or 134400)
    page.itemName:SetText(it.link)
    if it.error then
        page.itemSub:SetText("|cffff4a3a" .. it.error .. "|r")
        return
    end
    local slotName = ns.SimMath.SLOT_NAMES[it.slot] or "?"
    local sub = "Instead of your " .. slotName .. ": " .. (it.oldLink or "(empty)")
    if it.other and #it.other > 0 then sub = sub .. " · " .. table.concat(it.other, ", ") end
    page.itemSub:SetText(sub)
end

---------------------------------------------------------------------------
-- View: Spells
---------------------------------------------------------------------------

local function spellRows(p, q, why, metric)
    local rows = {}
    local dec = metric.decimals
    for _, key in ipairs(SPELL_KEYS) do
        local spell = ns.RANKS_BY_KEY[key]
        local rank = spell and ns.SpellData.Best(key, p.level)
        if rank then
            local a, b = calc(spell, rank, p), calc(spell, rank, q)
            local field = spell.kind == "heal" and metric.heal or metric.dmg
            local va, vb = a and a[field], b and b[field]
            local ch, chCol = change(va, vb, dec)
            rows[#rows + 1] = {
                icon = rank.icon, name = spell.name,
                sub = "Rank " .. rank.rank .. (spell.kind == "heal" and " · healing" or ""),
                cols = { va and f(va, dec) or "?", vb and f(vb, dec) or "?", ch },
                colColors = { W.GREY, W.WHITE, chCol },
                tooltip = function(tt)
                    tt:AddDoubleLine(spell.name, "Rank " .. rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
                    if not (a and b) then
                        tt:AddLine("The addon couldn't read this spell's numbers from the game.", 1, 0.3, 0.2, true)
                        return
                    end
                    tt:AddDoubleLine("Now", f(a.expected, 1) .. (spell.kind == "heal" and " healing" or " damage") .. " per cast",
                        1, 0.82, 0, 1, 1, 1)
                    tt:AddDoubleLine("With the changes", f(b.expected, 1) .. " per cast", 1, 0.82, 0, 0.12, 1, 0)
                    if spell.kind == "spell" then
                        tt:AddLine(" ")
                        tt:AddLine("The math with the changes", 1, 0.82, 0)
                        W.AddMath(tt, ns.SpellMath.Explain(spell, rank, b))
                    end
                    addWhy(tt, why)
                    W.AddNote(tt, "Spell numbers come from the game's tooltip. How stats turn into crit, mana and attack power are old Classic rules until we test them in Forever.")
                end,
            }
        end
    end

    -- White hits with your main-hand weapon.
    local ma, mb = ns.SimMath.Melee(p), ns.SimMath.Melee(q)
    if ma or mb then
        local field = metric.melee
        local va, vb = field and ma and ma[field], field and mb and mb[field]
        local ch, chCol = change(va, vb, dec)
        local weaponIcon = ns.try(GetInventoryItemTexture, "player", 16)
        rows[#rows + 1] = {
            icon = weaponIcon, name = "Melee swing",
            sub = (T.item and T.item.weapon) and "With the weapon you're trying" or "Main hand, no weapon buff",
            cols = { va and f(va, dec) or "-", vb and f(vb, dec) or "-", field and ch or "" },
            colColors = { W.GREY, W.WHITE, chCol },
            tooltip = function(tt)
                tt:AddLine("Melee swing", 1, 1, 1)
                tt:AddLine("One normal hit with your main-hand weapon, counting misses, dodges and crits.", 1, 0.82, 0, true)
                for _, pair in ipairs({ { "Now", ma }, { "With the changes", mb } }) do
                    local c = pair[2]
                    if c then
                        tt:AddLine(" ")
                        tt:AddLine(pair[1], 1, 0.82, 0)
                        W.AddMath(tt, {
                            ("%s average hit × %s crit × %s%% land = %s per swing"):format(f(c.avg, 1), f(c.critMult, 3), f(c.land * 100), f(c.expected, 1)),
                            { "DPS", f(c.dps, 1) },
                        })
                    end
                end
                addWhy(tt, why)
                W.AddNote(tt, "Weapon buffs are in the Weapon buff view. 🔶 Classic rules: 14 attack power = 1 DPS, 5% miss, 5% dodge.")
            end,
        }
    end
    return rows
end

---------------------------------------------------------------------------
-- View: Weapon buff
---------------------------------------------------------------------------

local function dpsOf(list, key)
    for _, e in ipairs(list) do
        if e.key == key then return e.calc and e.calc.dps end
    end
end

-- The best buff in a list, and how far ahead of the next one it is.
local function bestOf(list)
    local b = list[1]
    if not (b and b.calc) then return nil end
    return b
end

-- How much MORE of one stat (on top of the sliders) makes buff "key" the
-- best? Tries amounts between 0 and maxAmount and halves the gap each time
-- (like guessing a number with "higher / lower"). Returns the amount, or
-- nil if even maxAmount isn't enough.
local function crossover(p, add, opts, key, stat, maxAmount)
    local IM = ns.ImbueMath
    local function lead(amount)
        local a = {}
        for k, v in pairs(add) do a[k] = v end
        a[stat] = (a[stat] or 0) + amount
        local q = ns.SimMath.Apply(p, a, opts)
        local list = IM.Compare(q)
        local mine, other = nil, nil
        for _, e in ipairs(list) do
            if e.calc then
                if e.key == key then mine = e.calc.dps
                elseif not other or e.calc.dps > other then other = e.calc.dps end
            end
        end
        if not mine then return nil end
        return mine - (other or 0)
    end
    local top = lead(maxAmount)
    if not top or top < 0 then return nil end
    local lo, hi = 0, maxAmount
    while hi - lo > 1 do
        local mid = math.floor((lo + hi) / 2)
        local l = lead(mid)
        if l and l >= 0 then hi = mid else lo = mid end
    end
    return hi
end

-- Stats that can change which buff wins, and the buff each one helps most.
local TURNING_POINTS = {
    { key = "FT", stat = "sp", unit = "spell power", max = 1500,
      why = "Flametongue's fire gets stronger with spell power (your SP Test result, or the setting below)." },
    { key = "WF", stat = "ap", unit = "attack power", max = 3000,
      why = "Windfury's extra attacks get stronger with attack power. Rockbiter's bonus stays the same." },
}

local function weaponRows(p, q, why, opts)
    local IM = ns.ImbueMath
    local rows = {}
    if not (q.weapon and q.weapon.min and q.weapon.speed) then
        rows[#rows + 1] = { header = "No main-hand weapon found" }
        return rows
    end
    local now, try = IM.Compare(p), IM.Compare(q)
    local ctx = IM.lastCtx   -- from the "try" run
    local bNow, bTry = bestOf(now), bestOf(try)

    -- The answer first.
    rows[#rows + 1] = { header = "The best weapon buff" }
    if bTry then
        local changed = bNow and bNow.key ~= bTry.key
        local nowDps = bNow and dpsOf(now, bNow.key)
        local ch, chCol = change(nowDps, bTry.calc.dps, 1)
        rows[#rows + 1] = {
            icon = bTry.rank and bTry.rank.icon, badge = true,
            name = (changed and "New best: " or "Best: ") .. bTry.name, nameColor = W.GREEN,
            sub = changed and ("|cffffd100Your changes make it beat " .. bNow.name .. ".|r")
                or "Same as now. Move a slider to test.",
            cols = { nowDps and ("+" .. f(nowDps, 1)) or "-", "+" .. f(bTry.calc.dps, 1), changed and "new!" or ch },
            colColors = { W.GREY, W.GREEN, changed and W.GREEN or chCol },
            tooltip = function(tt)
                tt:AddLine("Best weapon buff with your changes", 1, 1, 1)
                if bNow then tt:AddDoubleLine("Now", bNow.name .. " +" .. f(bNow.calc.dps, 1) .. " DPS", 1, 0.82, 0, 1, 1, 1) end
                tt:AddDoubleLine("With your changes", bTry.name .. " +" .. f(bTry.calc.dps, 1) .. " DPS", 1, 0.82, 0, 0.12, 1, 0)
                addWhy(tt, why)
                W.AddNote(tt, "Same math as the Weapon Buffs tab: your weapon swung many times with each buff, using your attack power, crit, spell power and hit.")
            end,
        }
    end

    -- Every buff, now and with the changes.
    rows[#rows + 1] = { header = "DPS each buff adds" }
    for _, e in ipairs(try) do
        local c = e.calc
        local nowDps = dpsOf(now, e.key)
        local ch, chCol = change(nowDps, c and c.dps, 1)
        local sub = e.rank and ("Rank " .. e.rank.rank) or "Not learned yet"
        if not c then sub = sub .. " · |cffff8000" .. (e.reason or "?") .. "|r"
        elseif e.key == "WF" and ctx and ctx.ftTotem then sub = sub .. " · extra attacks get totem fire too"
        elseif e.key == "FT" then sub = sub .. " · uses spell crit" end
        rows[#rows + 1] = {
            icon = e.rank and e.rank.icon, name = e.name, sub = sub, dim = not c,
            badge = bTry and e == bTry,
            nameColor = (bTry and e == bTry) and W.GREEN or nil,
            cols = { nowDps and ("+" .. f(nowDps, 1)) or "-", c and ("+" .. f(c.dps, 1)) or "-", c and ch or "" },
            colColors = { W.GREY, W.WHITE, chCol },
            tooltip = function(tt)
                tt:AddLine(e.name .. (e.rank and ("  (Rank " .. e.rank.rank .. ")") or ""), 1, 1, 1)
                if not c then
                    tt:AddLine("Can't calculate: " .. (e.reason or "?"), 1, 0.3, 0.2, true)
                    return
                end
                tt:AddDoubleLine("Now", nowDps and ("+" .. f(nowDps, 1) .. " DPS") or "-", 1, 0.82, 0, 1, 1, 1)
                tt:AddDoubleLine("With your changes", "+" .. f(c.dps, 1) .. " DPS", 1, 0.82, 0, 0.12, 1, 0)
                tt:AddLine(" ")
                W.AddMath(tt, c.lines)
                if e.key == "WF" then
                    W.AddNote(tt, "Each Windfury extra attack is a full hit, so anything that adds damage to every hit (like Flametongue Totem) is added to the extra attacks too. Turn Flametongue Totem on below to see it.")
                elseif e.key == "FT" then
                    W.AddNote(tt, "Flametongue's fire uses your spell crit (from Intellect), not melee crit. Only one weapon buff fits on a weapon, so Flametongue Weapon and Windfury Weapon can't both be on your main hand.")
                end
                addWhy(tt, why)
            end,
        }
    end

    -- When would a different buff win?
    rows[#rows + 1] = { header = "What would change the best buff" }
    for _, tp in ipairs(TURNING_POINTS) do
        local e
        for _, x in ipairs(try) do if x.key == tp.key then e = x end end
        if e and e.calc then
            local isBest = bTry and bTry.key == tp.key
            local row = { icon = e.rank and e.rank.icon, name = e.name, cols = { "", "", "" }, colColors = { W.GREY, W.WHITE, W.GREEN } }
            if isBest then
                row.sub = "Already the best with your changes."
                row.cols[3] = "best"
            else
                local need = crossover(p, T.add, opts, tp.key, tp.stat, tp.max)
                if need then
                    row.sub = ("Beats %s with %s more %s"):format(bTry.name, f(need), tp.unit)
                    row.cols[3] = "+" .. f(need)
                else
                    -- Doesn't get there even with a huge amount.
                    row.sub = ("Not even with +%s %s"):format(f(tp.max), tp.unit)
                    if tp.key == "FT" then row.sub = row.sub .. " (check its spell power share)" end
                    row.cols[3] = "never"
                    row.colColors[3] = W.GREY
                end
            end
            row.tooltip = function(tt)
                tt:AddLine(e.name, 1, 1, 1)
                tt:AddLine(tp.why, 1, 0.82, 0, true)
                tt:AddLine("The number is how much MORE " .. tp.unit .. " you'd need on top of what the sliders already add.", 0.6, 0.6, 0.6, true)
                if tp.key == "FT" then
                    tt:AddLine(" ")
                    tt:AddDoubleLine("Fire spell power (with changes)", f(q.sp and q.sp.Fire or 0), 1, 0.82, 0, 1, 1, 1)
                end
            end
            rows[#rows + 1] = row
        end
    end

    -- Group settings (same ones as the Weapon Buffs tab), so you can see
    -- what a Flametongue or Windfury Totem in the group does.
    for _, r in ipairs(ns.ImbueSettingRows(p)) do
        if r.header then
            r.header = "Your group (click a row to change it)"
        elseif r.cols then
            r.cols = { "", "", r.cols[2] }
            r.colColors = { nil, nil, r.colColors and r.colColors[2] }
        end
        rows[#rows + 1] = r
    end
    return rows
end

---------------------------------------------------------------------------
-- View: Stat value (what 1 point is worth)
---------------------------------------------------------------------------

local function worthRows(p, mqRank)
    local db = ns.db()
    local rows = { { header = "1 spell power is worth (your SP Tests)" } }
    local strDps = ns.CoefTest.StrengthDps(p)
    local weights = ns.CoefTest.Weights(p)
    for _, w in ipairs(weights) do
        local t = w.t
        rows[#rows + 1] = {
            icon = t.rank.icon, name = t.spell.name,
            sub = ("%s · %s per use · every %s sec"):format(ns.CoefTest.PART_NAMES[t.part] or t.part, f(w.saved.total, 2), f(t.every, 1)),
            cols = { "", f(w.dps, 3), w.strEq and (f(w.strEq, 2) .. " Str") or "?" },
            colColors = { W.GREY, W.WHITE, W.GREEN },
            tooltip = function(tt)
                tt:AddDoubleLine(t.spell.name, "Rank " .. t.rank.rank, 1, 1, 1, 0.6, 0.6, 0.6)
                W.AddMath(tt, {
                    { "Your SP Test", f(w.saved.total, 3) .. " ± " .. f(w.saved.totalMargin, 3) },
                    ("1 spell power = %s more damage each use"):format(f(w.saved.total, 3)),
                    ("÷ %s sec between uses = %s DPS"):format(f(t.every, 1), f(w.dps, 3)),
                    strDps and ("1 Strength = %s melee DPS"):format(f(strDps, 3)) or "Couldn't read your weapon for Strength.",
                    w.strEq and ("So 1 spell power ≈ %s Strength for this"):format(f(w.strEq, 2)) or "",
                })
                W.AddNote(tt, "Only counts this one spell or buff. If you use several, add their numbers up. Time between uses, misses and crits are old Classic rules, not tested in Forever.")
            end,
        }
    end
    if #weights == 0 then
        rows[#rows + 1] = { icon = "Interface\\Icons\\Trade_Alchemy", name = "No saved tests yet",
            sub = "Save a result on the SP Test tab", cols = { "", "", "" } }
    end
    -- 1 Intellect: spell power (Mental Quickness) + attack power (Mental Dexterity).
    local int = ns.CoefTest.IntellectValue(p, { mentalDex = db.simMentalDex, mentalQuick = mqRank }, weights)
    rows[#rows + 1] = { header = "Compare with" }
    if int then
        rows[#rows + 1] = {
            icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", name = "1 Intellect (compare)",
            sub = ("%s spell power + %s attack power"):format(f(int.sp, 2), f(int.ap, 1)),
            cols = { "", f(int.dps, 3), int.strEq and (f(int.strEq, 2) .. " Str") or "?" },
            colColors = { W.GREY, W.WHITE, W.GREEN },
            tooltip = function(tt)
                tt:AddLine("1 Intellect", 1, 1, 1)
                W.AddMath(tt, {
                    ("Mental Quickness %d × %s%% = %s spell power"):format(mqRank, f(ns.SimMath.RULES.mentalQuickSpPerIntPerRank * 100), f(int.sp, 2)),
                    int.best and ("× %s DPS per spell power (%s, your best saved test) = %s DPS"):format(f(int.best.dps, 3), int.best.t.spell.name, f(int.spDps, 3))
                        or "No saved SP Test yet, so spell power counts as 0 here.",
                    db.simMentalDex and ("Mental Dexterity: +%s attack power = %s melee DPS"):format(f(int.ap, 1), f(int.apDps, 3))
                        or "Mental Dexterity not ticked: no attack power.",
                    { "Total", f(int.dps, 3) .. " DPS" },
                })
                W.AddNote(tt, "Intellect also gives mana and spell crit; those aren't in this number. 15% per point is Angel-reported, the tooltip isn't checked yet.")
            end,
        }
    end
    if strDps then
        rows[#rows + 1] = { icon = "Interface\\Icons\\Ability_Warrior_BattleShout", name = "1 Strength (compare)",
            sub = "Melee swing DPS from +2 attack power", cols = { "", f(strDps, 3), "1 Str" },
            colColors = { W.GREY, W.WHITE, W.GREY } }
    end
    return rows
end

---------------------------------------------------------------------------
-- View: My stats
---------------------------------------------------------------------------

local STAT_ROWS = {
    { "Attack Power", "ap", 0, "Interface\\Icons\\Ability_Warrior_BattleShout" },
    { "Spell Power", function(x) return x.sp and x.sp.Nature end, 0, "Interface\\Icons\\Spell_Nature_StarFall" },
    { "Healing", "healing", 0, "Interface\\Icons\\Spell_Nature_HealingTouch" },
    { "Spell Crit", "spellCrit", 2, "Interface\\Icons\\Spell_Fire_FlameBolt", "%" },
    { "Melee Crit", "meleeCrit", 2, "Interface\\Icons\\Ability_CriticalStrike", "%" },
    { "Hit", "spellHit", 0, "Interface\\Icons\\Ability_Marksmanship", "%" },
    { "Max Mana", "mana", 0, "Interface\\Icons\\Spell_Shadow_ManaBurn" },
}

local function statRows(p, q, why)
    local rows = {}
    for _, s in ipairs(STAT_ROWS) do
        local get = type(s[2]) == "function" and s[2] or function(x) return x[s[2]] end
        local va, vb = get(p) or 0, get(q) or 0
        local unit = s[5] or ""
        local d = vb - va
        local dCol = math.abs(d) < 0.005 and W.GREY or (d > 0 and W.GREEN or { 1, 0.29, 0.23 })
        rows[#rows + 1] = {
            icon = s[4], name = s[1], sub = "",
            cols = { f(va, s[3]) .. unit, f(vb, s[3]) .. unit, math.abs(d) < 0.005 and "-" or ((d > 0 and "+" or "") .. f(d, s[3]) .. unit) },
            colColors = { W.GREY, W.WHITE, dCol },
            tooltip = function(tt)
                tt:AddDoubleLine(s[1], f(vb, s[3]) .. unit, 1, 1, 1, 1, 1, 1)
                tt:AddDoubleLine("Now (from the game)", f(va, s[3]) .. unit, 1, 0.82, 0, 1, 1, 1)
                addWhy(tt, why)
            end,
        }
    end
    return rows
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

function T.Update(page)
    T.add = T.add or ns.SimMath.Empty()
    local db = ns.db()
    local metric = METRICS[T.metric]
    local viewId = T.View()
    local view = VIEW_BY_ID[viewId]

    -- The picked view's button stays lit.
    for id, b in pairs(page.viewButtons) do
        if id == viewId then b:LockHighlight() else b:UnlockHighlight() end
    end
    page.list:SetNameTitle(view.title)
    page.list:SetColumnTitles(view.cols)
    page.note:SetText(view.note)
    page.metric:SetShown(viewId == "spells")
    page.note:SetPoint("RIGHT", viewId == "spells" and -158 or 0, 0)
    page.metric:SetText("Show: " .. metric.name)

    if page.mentalDex.SetChecked then page.mentalDex:SetChecked(db.simMentalDex and true or false) end
    for key, row in pairs(page.sliders) do row:Set(T.add[key] or 0, false) end
    updateItemBox(page)

    local p = ns.Profile.Player()
    local mqRank, mqFrom = ns.SimMath.MentalQuickRank()
    page.mentalQuick:SetText(("Mental Quickness: %d point%s (%s)"):format(mqRank, mqRank == 1 and "" or "s",
        mqFrom == "talents" and "read from talents" or mqFrom == "setting" and "set by you" or "click to set"))
    local opts = { mentalDex = db.simMentalDex, mentalQuick = mqRank, weapon = T.item and T.item.weapon }
    local q, why = ns.SimMath.Apply(p, T.add, opts)

    local rows
    if viewId == "weapon" then
        rows = weaponRows(p, q, why, opts)
    elseif viewId == "worth" then
        rows = worthRows(p, mqRank)
    elseif viewId == "stats" then
        rows = statRows(p, q, why)
    else
        rows = spellRows(p, q, why, metric)
    end
    page.list:SetRows(rows)
end
