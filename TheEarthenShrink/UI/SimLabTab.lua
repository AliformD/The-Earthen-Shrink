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

    page.itemName = W.Text(box, "GameFontNormal", nil, "LEFT")
    page.itemName:SetPoint("TOPLEFT", btn, "TOPRIGHT", 10, -3)
    page.itemName:SetPoint("RIGHT", -210, 0)
    page.itemSub = W.Text(box, "GameFontDisableSmall", nil, "LEFT")
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
    title:SetText("ADD OR TAKE AWAY STATS")
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
    cb:SetSize(22, 22)
    cb:SetPoint("BOTTOMLEFT", 6, 6)
    local label = W.Text(panel, "GameFontHighlightSmall", nil, "LEFT")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText("I have Mental Dexterity (Intellect gives attack power)")
    label:SetPoint("RIGHT", -6, 0)
    cb:SetScript("OnClick", function(self)
        ns.db().simMentalDex = self:GetChecked() and true or false
        T.Update(page)
    end)
    page.mentalDex = cb
end

function T.Build(page)
    local width = ns.UI.CONTENT_W
    T.page = page
    T.add = T.add or ns.SimMath.Empty()
    buildItemBox(page, width)
    buildSliders(page, -58, 368)

    page.list = W.List(page, width - 308, 340, {
        { title = "Now", width = 54 }, { title = "Try", width = 54 }, { title = "Change", width = 56 },
    })
    page.list.frame:SetPoint("TOPLEFT", 308, -58)
    page.list:SetNameTitle("With your current gear")

    page.metric = W.Button(page, "", 170)
    page.metric:SetPoint("BOTTOMRIGHT", 0, 0)
    page.metric:SetScript("OnClick", function()
        T.metric = T.metric % #METRICS + 1
        T.Update(page)
    end)
    page.note = W.Text(page, "GameFontDisableSmall", nil, "LEFT")
    page.note:SetPoint("BOTTOMLEFT", page.list.frame, "BOTTOMLEFT", 0, -22)
    page.note:SetPoint("RIGHT", page.metric, "LEFT", -8, 0)
    page.note:SetText("Hover a row for the math.")
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

function T.Update(page)
    T.add = T.add or ns.SimMath.Empty()
    local db = ns.db()
    local metric = METRICS[T.metric]
    page.metric:SetText("Show: " .. metric.name)
    if page.mentalDex.SetChecked then page.mentalDex:SetChecked(db.simMentalDex and true or false) end
    for key, row in pairs(page.sliders) do row:Set(T.add[key] or 0, false) end
    updateItemBox(page)

    local p = ns.Profile.Player()
    local q, why = ns.SimMath.Apply(p, T.add, { mentalDex = db.simMentalDex, weapon = T.item and T.item.weapon })
    local rows = {}
    local dec = metric.decimals

    rows[#rows + 1] = { header = "Your spells (highest rank you have)" }
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
                W.AddNote(tt, "Weapon buffs are on the Weapon Buffs tab. 🔶 Classic rules: 14 attack power = 1 DPS, 5% miss, 5% dodge.")
            end,
        }
    end

    -- Your stats, now and with the changes.
    rows[#rows + 1] = { header = "Your stats" }
    local STAT_ROWS = {
        { "Attack Power", "ap", 0, "Interface\\Icons\\Ability_Warrior_BattleShout" },
        { "Spell Power", function(x) return x.sp and x.sp.Nature end, 0, "Interface\\Icons\\Spell_Nature_StarFall" },
        { "Healing", "healing", 0, "Interface\\Icons\\Spell_Nature_HealingTouch" },
        { "Spell Crit", "spellCrit", 2, "Interface\\Icons\\Spell_Fire_FlameBolt", "%" },
        { "Melee Crit", "meleeCrit", 2, "Interface\\Icons\\Ability_CriticalStrike", "%" },
        { "Hit", "spellHit", 0, "Interface\\Icons\\Ability_Marksmanship", "%" },
        { "Max Mana", "mana", 0, "Interface\\Icons\\Spell_Shadow_ManaBurn" },
    }
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
    page.list:SetRows(rows)
end
