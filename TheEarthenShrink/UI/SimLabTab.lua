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
--   Left:  the stat sliders, your talents (tick + points), and how you play
--          (Melee / Caster / Healer, fight length).
--   Right: five buttons pick ONE view at a time:
--          Total   = everything you do in a fight added up, now vs. with
--                    your changes (the number to compare gear with)
--          Weights = one weight per stat, plus copy-ready text for Pawn
--          Spells, Buffs (weapon buff), Stats.

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

-- A small "Melee / Caster / Healer" style picker: three buttons, the one
-- you picked stays lit.
local function buildStyleButtons(panel, y)
    local btns = {}
    local bw = (280 - 2 * 4) / #ns.Rotation.STYLES
    for i, st in ipairs(ns.Rotation.STYLES) do
        local b = W.Button(panel, st.short, bw)
        b:SetHeight(20)
        b:SetPoint("TOPLEFT", 10 + (i - 1) * (bw + 4), y)
        b:SetScript("OnClick", function()
            ns.db().simStyle = st.id
            T.Update(T.page)
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(st.name, 1, 1, 1)
            local what = {
                enh = "Your mix: weapon swings, weapon buff, Stormstrike, shocks, Lightning Shield and Searing Totem. Stat weights are counted in Strength (1 Strength = 1.00).",
                ele = "Your mix: shocks, Lightning Shield, Searing Totem, and Lightning Bolt in all the time left. Stat weights are counted in Spell Power (1 Spell Power = 1.00).",
                resto = "Your mix: Healing Wave over and over. Stat weights are counted in Healing (1 Healing = 1.00).",
            }
            GameTooltip:AddLine(what[st.id], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btns[st.id] = b
    end
    return btns
end

-- One talent: a tick box ("I have it"), a points slider, and "2/3".
local function buildTalentRow(panel, key, y)
    local S = ns.SimMath
    local def = S.TALENT_BY_KEY[key]
    local row
    row = W.StatSlider(panel, 280, {
        label = def.name, min = 0, max = def.maxFallback, step = 1, compact = true,
        labelInset = 22, labelWidth = 118, valueWidth = 34,
        format = function(v)
            local info = S.Talent(key)
            local col = info.on and "|cff1eff00" or "|cff999999"
            return col .. ns.fmt(v) .. "/" .. info.max .. "|r"
        end,
        onChange = function(v)
            S.SetTalentPoints(key, v)
            T.Update(T.page)
        end,
        tooltip = function(tt) T.TalentTooltip(tt, key) end,
    })
    row:SetPoint("TOPLEFT", 10, y)
    local cb = W.Create("CheckButton", nil, row, { "UICheckButtonTemplate", "ChatConfigCheckButtonTemplate" })
    cb:SetSize(20, 20)
    cb:SetPoint("LEFT", -2, 0)
    cb:SetScript("OnClick", function(self)
        S.SetTalentOn(key, self:GetChecked() and true or false)
        T.Update(T.page)
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        T.TalentTooltip(GameTooltip, key)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.check = cb
    return row
end

function T.TalentTooltip(tt, key)
    local S = ns.SimMath
    local info = S.Talent(key)
    tt:AddLine(info.name, 1, 1, 1)
    tt:AddLine(info.what, 1, 0.82, 0, true)
    tt:AddLine(" ")
    if info.real ~= nil then
        tt:AddDoubleLine("Your character has", info.real .. "/" .. info.max .. " points", 1, 0.82, 0, 1, 1, 1)
    else
        tt:AddLine("The addon couldn't read your talents, so set your points here.", 1, 0.5, 0, true)
    end
    tt:AddDoubleLine("The Sim Lab uses", info.points .. " points", 1, 0.82, 0, info.changed and 0.12 or 1, 1, info.changed and 0 or 1)
    if S.TALENT_BY_KEY[key].buff then
        T.BuffTalentLines(tt, info.name)
    elseif key == "MD" then
        local per, src = S.MentalDexRatio()
        tt:AddLine(("Each point: 1 Intellect = %s attack power (%s)."):format(ns.fmt(per, 2),
            src == "talent" and "read from the talent's text" or "50% per point, as Angel saw in game"), 0.91, 0.89, 0.78, true)
    else
        tt:AddLine(("Each point: spell damage and healing = %s%% of your Intellect (what Angel saw in game, tooltip not checked yet)."):format(
            ns.fmt(S.RULES.mentalQuickSpPerIntPerRank * 100)), 0.91, 0.89, 0.78, true)
    end
    if not info.maxFromGame then
        tt:AddLine(("🔶 Max %d points is a guess; the game's number is used when the addon can read it."):format(info.max), 0.6, 0.6, 0.6, true)
    end
    W.AddNote(tt, "Tick = you have it. Slider = how many points. Change them to test a different build; \"Real\" goes back to your character's talents.")
end

-- What a weapon buff talent does, as the addon read it from the game.
function T.BuffTalentLines(tt, name)
    local TM = ns.TalentMods
    local found = false
    for _, key in ipairs({ "RB", "FT", "FB", "WF", "WFT", "FTT", "ST", "MT", "ES", "FlS", "FrS", "LB", "CL", "LS", "HW", "LHW", "CH", "HST", "MST", "FN" }) do
        for _, m in ipairs(TM.ModsFor(key)) do
            if m.talent == name then
                found = true
                local spell = ns.RANKS_BY_KEY[key]
                tt:AddDoubleLine((spell and spell.name or key) .. (m.kind == "cost" and " mana cost" or ""),
                    ("%s%s%% per point"):format(m.perPoint >= 0 and "+" or "", ns.fmt(m.perPoint, 2)), 0.91, 0.89, 0.78, 1, 1, 1)
            end
        end
    end
    if found then
        tt:AddLine("Read from the talent's text in the game. 🔶 Assumes the text shows the total for your points (or 1 point if you have none).", 0.6, 0.6, 0.6, true)
    else
        tt:AddLine("The addon couldn't read a % for this talent from the game yet, so changing it does nothing here. /es talents shows what it read.", 1, 0.5, 0, true)
    end
end

local function sectionTitle(panel, text, y)
    local t = W.Text(panel, "GameFontNormalSmall", nil, "LEFT")
    t:SetPoint("TOPLEFT", 10, y)
    t:SetText(text)
    t:SetTextColor(0.6, 0.6, 0.6)
    return t
end

local function buildSliders(page, top, height)
    local panel = W.Panel(page)
    panel:SetSize(300, height)
    panel:SetPoint("TOPLEFT", 0, top)

    sectionTitle(panel, "1. CHANGE YOUR STATS", -7)
    local reset = W.Button(panel, "Reset", 64)
    reset:SetHeight(18)
    reset:SetPoint("TOPRIGHT", -6, -4)
    reset:SetScript("OnClick", function() T.Clear() end)

    page.sliders = {}
    for i, st in ipairs(ns.SimMath.STATS) do
        local row = W.StatSlider(panel, 280, {
            label = st.label, min = st.min, max = st.max, step = st.step, unit = st.unit, compact = true,
            onChange = function(v)
                T.add[st.key] = v
                T.Update(page)
            end,
            tooltip = st.tip and function(tt)
                tt:AddLine(st.label, 1, 1, 1)
                tt:AddLine(st.tip, 1, 0.82, 0, true)
            end or nil,
        })
        row:SetPoint("TOPLEFT", 10, -24 - (i - 1) * 22)
        page.sliders[st.key] = row
    end

    -- Talents: read from your character, change them to test other builds.
    local y = -24 - #ns.SimMath.STATS * 22 - 2
    sectionTitle(panel, "YOUR TALENTS", y)
    local real = W.Button(panel, "Real", 64)
    real:SetHeight(18)
    real:SetPoint("TOPRIGHT", -6, y + 3)
    real:SetScript("OnClick", function()
        ns.SimMath.ResetTalents()
        T.Update(page)
    end)
    real:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Back to your real talents", 1, 1, 1)
        GameTooltip:AddLine("Undo any talent changes you made here, and use the points your character really has. Weapon buffs, totems and spells go back to what your own tooltips say.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    real:SetScript("OnLeave", function() GameTooltip:Hide() end)
    page.talentReset = real
    page.talents = {}
    for i, t in ipairs(ns.SimMath.TALENTS) do
        page.talents[t.key] = buildTalentRow(panel, t.key, y - 15 - (i - 1) * 22)
    end

    -- How you play and how long a fight lasts.
    y = y - 15 - #ns.SimMath.TALENTS * 22 - 2
    sectionTitle(panel, "HOW YOU PLAY", y)
    page.styleButtons = buildStyleButtons(panel, y - 15)
    page.fight = W.StatSlider(panel, 280, {
        label = "Fight length", min = ns.Rotation.FIGHT_MIN, max = ns.Rotation.FIGHT_MAX, step = ns.Rotation.FIGHT_STEP, compact = true, valueWidth = 50,
        format = function(v) return ns.fmt(v) .. " sec" end,
        onChange = function(v)
            ns.db().simFight = v
            T.Update(page)
        end,
        tooltip = function(tt)
            tt:AddLine("Fight length", 1, 1, 1)
            tt:AddLine("How long one fight lasts: 10 to 30 sec, like killing mobs while questing. In a longer fight your mana can run out, so Intellect (more mana) is worth more.", 1, 0.82, 0, true)
            W.AddNote(tt, "🔶 Mana you get back during the fight (Spirit, Mana Spring) isn't counted yet.")
        end,
    })
    page.fight:SetPoint("TOPLEFT", 10, y - 39)
end

-- The views on the right. cols = the column titles for that view.
local VIEWS = {
    { id = "total",  label = "Total",   title = "Your total",                  cols = { "Now", "Try", "Change" },
      note = "Everything you do in a fight, added up. Hover a row for the math." },
    { id = "weights", label = "Weights", title = "Stat weights",               cols = { "", "Per point", "Weight" },
      note = "How much 1 point of each stat adds to your total. Copy them at the bottom." },
    { id = "spells", label = "Spells",  title = "Your spells (highest rank)",  cols = { "Now", "Try", "Change" },
      note = "Try = with your changes. Hover a row for the math." },
    { id = "weapon", label = "Buffs",   title = "Best weapon buff (DPS added)", cols = { "Now", "Try", "Change" },
      note = "Move Spell Power or Attack Power to see when the best buff changes." },
    { id = "stats",  label = "Stats",   title = "Your stats",                  cols = { "Now", "Try", "Change" },
      note = "Now = from the game. Try = with your changes." },
}
local VIEW_BY_ID = {}
for _, v in ipairs(VIEWS) do VIEW_BY_ID[v.id] = v end

function T.View()
    local id = ns.db().simView
    return VIEW_BY_ID[id] and id or "total"
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
    local bw = (right - (#VIEWS - 1) * 4) / #VIEWS
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
-- View: Total (everything you do in a fight, added up)
---------------------------------------------------------------------------

local RED = { 1, 0.29, 0.23 }

-- "+0.4" / "-1.2" with a colour, for small numbers where % would mislead.
local function diff(now, try, decimals)
    if not now or not try then return "", nil end
    local d = try - now
    if math.abs(d) < 0.05 then return "-", W.GREY end
    return (d > 0 and "+" or "") .. f(d, decimals or 1), d > 0 and W.GREEN or RED
end

local function totalRows(p, q, why, opts)
    local Ro = ns.Rotation
    local style = Ro.Style()
    local a, b = Ro.Total(p, { style = style }), Ro.Total(q, { style = style })
    local unit = style.unit
    local rows = {}
    rows[#rows + 1] = { header = ("%s · %s sec fight"):format(style.name, f(b.fight)) }

    -- The answer first: one number for everything.
    local ch, chCol = change(a.total, b.total, 1)
    -- Melee vs spells, so you can see "weaker swings, stronger spells".
    local groups = {}
    local function addTo(res, slot)
        for _, part in ipairs(res.parts) do
            local g = part.kind == "melee" and "Melee" or part.kind == "heal" and "Healing" or "Spells"
            groups[g] = groups[g] or { 0, 0 }
            groups[g][slot] = groups[g][slot] + part.dps
        end
    end
    addTo(a, 1); addTo(b, 2)
    local bits = {}
    for _, g in ipairs({ "Melee", "Spells", "Healing" }) do
        local v = groups[g]
        if v then
            local d = v[2] - v[1]
            local col = math.abs(d) < 0.05 and "|cff999999" or (d > 0 and "|cff1eff00" or "|cffff4a3a")
            bits[#bits + 1] = ("%s %s%s|r"):format(g, col, math.abs(d) < 0.05 and "same" or ((d > 0 and "+" or "") .. f(d, 1)))
        end
    end
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\Spell_Nature_Lightning", badge = b.total > a.total + 0.05,
        name = (unit == "HPS" and "Healing" or "Damage") .. " per second, all together",
        nameColor = W.WHITE, sub = table.concat(bits, " · "),
        cols = { f(a.total, 1), f(b.total, 1), ch }, colColors = { W.GREY, W.WHITE, chCol },
        tooltip = function(tt)
            tt:AddLine("Your total " .. unit, 1, 1, 1)
            tt:AddLine("Every part of your mix below, added up. This is the number to look at when you compare gear: if it goes up, the item is better for you, even if one part (like your swings) goes down.", 1, 0.82, 0, true)
            tt:AddLine(" ")
            tt:AddDoubleLine("Now", f(a.total, 1) .. " " .. unit, 1, 0.82, 0, 1, 1, 1)
            tt:AddDoubleLine("With your changes", f(b.total, 1) .. " " .. unit, 1, 0.82, 0, 0.12, 1, 0)
            for g, v in pairs(groups) do
                tt:AddDoubleLine("  " .. g, f(v[1], 1) .. " -> " .. f(v[2], 1), 0.91, 0.89, 0.78, 1, 1, 1)
            end
            addWhy(tt, why)
        end,
    }

    -- Each part of the mix.
    rows[#rows + 1] = { header = "Where it comes from" }
    local byKey = {}
    for _, part in ipairs(a.parts) do byKey[part.key] = part end
    for _, part in ipairs(b.parts) do
        local old = byKey[part.key]
        local dch, dcol = diff(old and old.dps, part.dps, 1)
        local share = b.total > 0 and part.dps / b.total * 100 or 0
        rows[#rows + 1] = {
            icon = part.icon, name = part.name,
            sub = (part.sub or (part.kind == "melee" and "melee" or "spell")) .. (" · %s%% of your total"):format(f(share)),
            cols = { old and f(old.dps, 1) or "-", f(part.dps, 1), dch }, colColors = { W.GREY, W.WHITE, dcol },
            tooltip = function(tt)
                tt:AddLine(part.name, 1, 1, 1)
                W.AddMath(tt, part.lines)
                if part.usesMana and b.manaFactor < 1 then
                    tt:AddLine(("Mana runs out: only %s%% of this fits in the fight."):format(f(b.manaFactor * 100)), 1, 0.5, 0, true)
                end
                addWhy(tt, why)
                W.AddNote(tt, "Spell numbers come from your tooltips. How often each is used, misses and crits are old Classic rules (🔶) until tested in Forever.")
            end,
        }
    end
    if #b.parts == 0 then
        rows[#rows + 1] = { icon = 134400, name = "Nothing to add up yet", sub = "The addon couldn't read your weapon or spells.", cols = { "", "", "" } }
    end

    -- Mana for the whole fight.
    local short = b.manaFactor < 1
    rows[#rows + 1] = { header = "Mana" }
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\Spell_Shadow_ManaBurn", name = short and "You run out of mana" or "Enough mana for the fight",
        nameColor = short and { 1, 0.5, 0 } or W.GREEN,
        sub = ("needs %s, you have %s"):format(f(b.manaNeed), f(b.manaHave)),
        cols = { f(a.manaFactor * 100) .. "%", f(b.manaFactor * 100) .. "%", "" }, colColors = { W.GREY, W.WHITE, W.GREY },
        tooltip = function(tt)
            tt:AddLine("Mana for one fight", 1, 1, 1)
            tt:AddLine("The % is how much of your spell casting your mana bar pays for. Under 100% means spells get cut down, and more Intellect (mana) helps.", 1, 0.82, 0, true)
            tt:AddLine(" ")
            tt:AddDoubleLine("Mana needed", f(b.manaNeed), 1, 0.82, 0, 1, 1, 1)
            tt:AddDoubleLine("Your mana bar", f(b.manaHave), 1, 0.82, 0, 1, 1, 1)
            W.AddNote(tt, "🔶 Mana you get back during the fight (Spirit, Mana Spring) isn't counted yet. Change the fight length on the left.")
        end,
    }

    -- What's in the mix.
    if style.id ~= "resto" then
        local on = ns.db().simUseFlameShock ~= false
        rows[#rows + 1] = { header = "Your mix (click to change)" }
        rows[#rows + 1] = {
            icon = "Interface\\Icons\\Spell_Fire_FlameShock", name = "Flame Shock: " .. (on and "on" or "off"),
            nameColor = on and W.GREEN or W.GREY,
            sub = on and "cast once, then again when it runs out" or "only Earth Shock",
            cols = { "", "", "" },
            onClick = function()
                ns.db().simUseFlameShock = not on
                T.Update(T.page)
            end,
            tooltip = function(tt)
                tt:AddLine("Flame Shock in your mix", 1, 1, 1)
                tt:AddLine("On: Flame Shock goes out once and again when it runs out; the other shock casts are Earth Shock. Off: only Earth Shock. Click to switch.", 1, 0.82, 0, true)
            end,
        }
    end
    return rows
end

---------------------------------------------------------------------------
-- View: Stat weights
---------------------------------------------------------------------------

local BASE_LABEL = { str = "Strength", sp = "Spell Power", heal = "Healing" }

-- Short "where it comes from" text: the biggest parts.
local function topParts(byPart)
    local list = {}
    for _, x in ipairs(byPart or {}) do if x.gain > 0 then list[#list + 1] = x end end
    table.sort(list, function(a, b) return a.gain > b.gain end)
    local names = {}
    for i = 1, math.min(3, #list) do names[#names + 1] = list[i].name end
    return #names > 0 and ("from " .. table.concat(names, ", ")) or "does nothing for your mix"
end

-- Plain words for what each stat does.
local WHAT = {
    str = "Strength gives attack power (🔶 2 per Strength): every melee hit, Stormstrike and Windfury.",
    agi = "Agility gives melee crit (🔶 20 Agility = 1%). It doesn't help spells.",
    int = "Intellect does several things at once: more mana, spell crit, spell power (Mental Quickness) and attack power (Mental Dexterity). All of them are in this one number.",
    sp = "Spell power makes shocks, Lightning Shield, totems, Lightning Bolt and Flametongue fire hit harder.",
    heal = "Healing makes your heals bigger. Items that say \"damage and healing\" give you this AND Spell Power; Pawn counts both.",
    ap = "Attack power: every melee hit, Stormstrike and the weapon buffs (🔶 14 attack power = 1 weapon DPS).",
    crit = "Crit CHANCE: how often a hit is a critical hit. Blizzard says Forever combines melee and spell crit, so 1% from gear helps both.",
    hit = "Hit CHANCE: fewer misses. Blizzard says Forever combines melee and spell hit, so 1% from gear helps both. It also means more Windfury procs, because only a hit that lands can proc.",
    wdps = "The DPS number on a weapon. Only counts for your main hand.",
}

---------------------------------------------------------------------------
-- Crit chance and hit chance, explained (Angel: "what does Crit (1%) mean?")
---------------------------------------------------------------------------

-- The short grey line under the Crit chance / Hit chance rows.
function T.CritHitSub(key, q)
    local H = ns.HitCrit
    if key == "crit" then
        local c = H.Conversions(q.level)
        return ("1%% = about %s Agility or %s Intellect"):format(f(c.agi), f(c.int))
    elseif key == "hit" then
        local melee, spell = H.Caps(q)
        return ("you have %s%% · cap %s%% melee, %s%% spells"):format(f(q.hit or 0, 1), f(melee), f(spell))
    end
end

-- Extra hover lines for the two "per 1%" rows.
function T.PercentNote(tt, key, q)
    local H = ns.HitCrit
    tt:AddLine(" ")
    tt:AddLine("\"1%\" means one PERCENTAGE POINT of chance (like 9.6% to 10.6%), not one point on an item. So you can't compare this number with 1 Intellect or 1 Strength by eye.", 0.4, 0.8, 1, true)
    if key == "crit" then
        local c = H.Conversions(q.level)
        tt:AddDoubleLine("1% melee crit from Agility", f(c.agi, 1) .. " Agility", 1, 0.82, 0, 1, 1, 1)
        tt:AddDoubleLine("1% spell crit from Intellect", f(c.int, 1) .. " Intellect", 1, 0.82, 0, 1, 1, 1)
        tt:AddLine(c.agiFromGame and c.intFromGame and "|cff1eff00Both read from the game.|r"
            or "|cffff8000🔶 Classic rule (the game didn't tell us), not checked in Forever.|r", 1, 1, 1, true)
    else
        local melee, spell = H.Caps(q)
        tt:AddDoubleLine("Your hit now", f(q.hit or 0, 1) .. "%", 1, 0.82, 0, 1, 1, 1)
        tt:AddDoubleLine("Melee hit cap (" .. H.Target(q).short .. ")", f(melee) .. "% 🔶", 1, 0.82, 0, 1, 1, 1)
        tt:AddDoubleLine("Spell hit cap (" .. H.Target(q).short .. ")", f(spell) .. "% 🔶", 1, 0.82, 0, 1, 1, 1)
        tt:AddLine("Past a cap, more hit does nothing there, so this weight drops. 🔶 Caps are Classic numbers: Blizzard hasn't announced Forever's.", 0.91, 0.89, 0.78, true)
    end
end

-- The "Hit and crit" rows under the weights.
function T.CritHitRows(rows, w, q, real)
    local H = ns.HitCrit
    local target = H.Target(q)
    local melee, spell = H.Caps(q)
    local hit = q.hit or 0
    rows[#rows + 1] = { header = "Hit and crit, explained (hover)" }

    rows[#rows + 1] = {
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot", name = "Target: " .. target.name,
        sub = "click to switch same level / boss", cols = { "", "", "switch" }, colColors = { nil, nil, W.GOLD },
        onClick = function()
            local db = ns.db()
            db.simTarget = (db.simTarget == "boss") and "same" or "boss"
            T.Update(T.page)
        end,
        tooltip = function(tt)
            tt:AddLine("Who you're fighting", 1, 1, 1)
            tt:AddLine("Bosses are 3 levels higher than you, so you miss them more and the hit cap is higher. This changes every number in the Sim Lab, not other tabs.", 1, 0.82, 0, true)
            W.AddNote(tt, "🔶 Miss chances are Classic numbers: melee 5% (same level) / 9% (boss), spells 3% / 16% you can remove, plus 1% that always misses.")
        end,
    }

    local function capLine(name, cap)
        if hit >= cap then return name .. " capped", W.GREEN end
        return ("%s %s%% more to cap"):format(name, f(cap - hit, 1)), W.WHITE
    end
    local mText = capLine("melee", melee)
    local sText = capLine("spells", spell)
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\Ability_Marksmanship", name = ("Hit: you have %s%%, cap %s%% / %s%%"):format(f(hit, 1), f(melee), f(spell)),
        sub = mText .. " · " .. sText .. " 🔶", cols = { "", "", "" },
        tooltip = function(tt)
            tt:AddLine("Hit chance and the hit cap", 1, 1, 1)
            tt:AddLine("Every attack can miss. Hit from gear, talents and your race takes misses away, 1% at a time. When you have enough that you never miss, you're \"hit capped\" and more hit does nothing.", 1, 0.82, 0, true)
            tt:AddLine(" ")
            -- Where your real hit comes from (read from the game).
            local src = ns.HitCrit.HitSources(real)
            tt:AddDoubleLine("Your hit, from the game (all sources)", f(src.total, 1) .. "%", 1, 0.82, 0, 1, 1, 1)
            for _, part in ipairs(src.parts) do
                tt:AddDoubleLine("   " .. part.name .. " · " .. part.kind, "+" .. f(part.pct, 1) .. "%", 0.91, 0.89, 0.78, 1, 1, 1)
            end
            if math.abs(src.other) >= 0.05 then
                tt:AddDoubleLine("   gear and anything else", (src.other > 0 and "+" or "") .. f(src.other, 1) .. "%", 0.91, 0.89, 0.78, 1, 1, 1)
            end
            if #src.parts == 0 then
                tt:AddLine("   (couldn't find a talent or racial that mentions hit; the total above is still the game's own number)", 0.6, 0.6, 0.6, true)
            end
            if math.abs(hit - src.total) >= 0.05 then
                tt:AddDoubleLine("   with your Sim Lab change", f(hit, 1) .. "%", 0.91, 0.89, 0.78, 0.4, 0.8, 1)
            end
            tt:AddDoubleLine("Melee cap vs " .. target.short, f(melee) .. "%", 1, 0.82, 0, 1, 1, 1)
            tt:AddDoubleLine("Spell cap vs " .. target.short, f(spell) .. "%", 1, 0.82, 0, 1, 1, 1)
            tt:AddLine(" ")
            tt:AddLine("That's why hit can be worth a lot now and almost nothing later: the Hit chance weight above already counts how far you are from the caps.", 0.91, 0.89, 0.78, true)
            tt:AddLine("Dodges (5% 🔶) are not misses: hit doesn't remove them.", 0.91, 0.89, 0.78, true)
            W.AddNote(tt, "🔶 Blizzard hasn't announced Forever's hit caps. These are Classic numbers. Forever also replaces weapon skill with Expertise (not counted here).")
        end,
    }

    local fl = select(2, H.FlurryFactor(q))
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\Ability_CriticalStrike", name = "Crit chance vs crit damage",
        sub = ("melee crit %s%% · spell crit %s%%"):format(f(q.meleeCrit or 0, 2), f(q.spellCrit or 0, 2)),
        cols = { "", "", "" },
        tooltip = function(tt)
            local c = H.Conversions(q.level)
            tt:AddLine("Crit chance vs crit damage", 1, 1, 1)
            tt:AddLine("Crit CHANCE is how OFTEN a hit is a critical hit. Crit DAMAGE is how BIG a critical hit is. Gear in Forever gives crit chance. Nothing here changes crit damage.", 1, 0.82, 0, true)
            tt:AddLine(" ")
            tt:AddDoubleLine("Melee crit does", "double (+100%) 🔶", 1, 0.82, 0, 1, 1, 1)
            tt:AddDoubleLine("Spell crit does", "1.5× (+50%) 🔶", 1, 0.82, 0, 1, 1, 1)
            tt:AddLine(" ")
            tt:AddLine("Where crit chance comes from:", 1, 1, 1)
            tt:AddDoubleLine("   Agility → melee crit", ("%s Agility = 1%%"):format(f(c.agi, 1)), 0.91, 0.89, 0.78, 1, 1, 1)
            tt:AddDoubleLine("   Intellect → spell crit", ("%s Intellect = 1%%"):format(f(c.int, 1)), 0.91, 0.89, 0.78, 1, 1, 1)
            tt:AddDoubleLine("   Gear crit → both", "1% = 1%", 0.91, 0.89, 0.78, 1, 1, 1)
            tt:AddLine(" ")
            tt:AddLine(("So 1%% crit from gear is worth a lot more than 1 Intellect, but you'd need about %s Intellect to get the same 1%% spell crit, and those %s Intellect also give mana, attack power and spell power. Per POINT, Intellect still wins."):format(f(c.int), f(c.int)), 0.91, 0.89, 0.78, true)
            if fl then
                tt:AddLine(" ")
                tt:AddLine(("Flurry %d: after a melee crit your next 3 swings are %s%% faster, so crit also means more swings (counted)."):format(fl.points, f(fl.pct)), 0.4, 0.8, 1, true)
            else
                tt:AddLine(" ")
                tt:AddLine("No Flurry found in your talents. If you take Flurry, crit gets worth more (faster swings after a crit).", 0.6, 0.6, 0.6, true)
            end
            W.AddNote(tt, (c.agiFromGame and c.intFromGame) and "Agility/Intellect numbers read from the game. Crit damage (×2 / ×1.5) is a Classic number 🔶."
                or "🔶 Agility/Intellect per 1% and crit damage are Classic numbers: the game didn't tell us, and they're not checked in Forever yet.")
        end,
    }
end

local function weightRows(p, q, opts)
    local Ro = ns.Rotation
    local w = Ro.Weights(p, T.add, opts)
    T.lastWeights = w
    local style = w.style
    local unit = style.unit
    local base = BASE_LABEL[style.base]
    local rows = {}
    rows[#rows + 1] = { header = ("Counted in %s: 1 %s = 1.00"):format(base, base) }
    if not (w.unitGain and w.unitGain > 1e-9) then
        rows[#rows + 1] = { icon = 134400, name = "Can't work out weights yet",
            sub = ("%s does nothing for your %s mix"):format(base, style.short:lower()), cols = { "", "", "" } }
    end
    local list = {}
    for _, def in ipairs(Ro.WEIGHTS) do
        local r = w.rows[def.key]
        if r then list[#list + 1] = { def = def, r = r } end
    end
    -- Highest weight first, Stamina (an estimate) last.
    table.sort(list, function(a, b)
        if a.r.estimate ~= b.r.estimate then return not a.r.estimate end
        return (a.r.weight or -1) > (b.r.weight or -1)
    end)
    for _, x in ipairs(list) do
        local def, r = x.def, x.r
        local weight = r.weight
        local isBase = def.key == style.base
        local row = {
            icon = def.icon, name = def.label,
            nameColor = isBase and W.WHITE or nil,
            sub = r.estimate and "no damage; our estimate (hover)" or T.CritHitSub(def.key, q) or topParts(r.byPart),
            cols = { "", r.estimate and "-" or (f(r.gain, 3) .. " " .. unit), weight and f(weight, 2) or "?" },
            colColors = { W.GREY, W.GREY, r.estimate and W.ORANGE or ((weight or 0) > 0.005 and W.GREEN or W.GREY) },
            meter = weight and math.max(0, math.min(1, weight)) or 0,
        }
        row.tooltip = function(tt)
            tt:AddDoubleLine(def.label, weight and ("weight " .. f(weight, 2)) or "", 1, 1, 1, 0.12, 1, 0)
            if r.estimate then
                tt:AddLine("Stamina gives health (🔶 10 per point), not damage, so the addon can't measure it like the others.", 1, 0.82, 0, true)
                tt:AddLine(("We set it to %s of %s: low enough that it never beats a damage stat, high enough to pick the tougher item when two items are close. It's our estimate, not game data."):format(
                    f(Ro.RULES.staminaShare, 2), base), 0.91, 0.89, 0.78, true)
                return
            end
            tt:AddLine(WHAT[def.key] or "", 1, 0.82, 0, true)
            if def.percent then T.PercentNote(tt, def.key, q) end
            tt:AddLine(" ")
            tt:AddDoubleLine(def.percent and ("1%% %s adds"):format((def.label:gsub(" %(per 1%%%)", ""))) or ("1 %s adds"):format(def.label),
                f(r.gain, 3) .. " " .. unit, 1, 0.82, 0, 1, 1, 1)
            for _, bp in ipairs(r.byPart or {}) do
                tt:AddDoubleLine("   " .. bp.name, (bp.gain > 0 and "+" or "") .. f(bp.gain, 3), 0.91, 0.89, 0.78, 1, 1, 1)
            end
            tt:AddDoubleLine(("1 %s adds"):format(base), f(w.unitGain or 0, 3) .. " " .. unit, 1, 0.82, 0, 1, 1, 1)
            if weight then
                tt:AddLine(("%s ÷ %s = %s"):format(f(r.gain, 3), f(w.unitGain, 3), f(weight, 2)), 0.91, 0.89, 0.78, true)
            end
            if def.key == "crit" and w.rows.mcrit and w.rows.scrit then
                tt:AddLine(" ")
                tt:AddDoubleLine("   melee part", f(w.rows.mcrit.weight or 0, 2), 0.91, 0.89, 0.78, 1, 1, 1)
                tt:AddDoubleLine("   spell part", f(w.rows.scrit.weight or 0, 2), 0.91, 0.89, 0.78, 1, 1, 1)
            end
            if def.key == "int" then
                local t = ns.SimMath.TalentOpts()
                tt:AddLine(("With Mental Dexterity %d and Mental Quickness %d (your talents on the left)."):format(t.mentalDex, t.mentalQuick), 0.6, 0.6, 0.6, true)
            end
            W.AddNote(tt, "Measured by adding a little of the stat and seeing how much your TOTAL goes up, with your changes on the left.")
        end
        rows[#rows + 1] = row
    end

    T.CritHitRows(rows, w, q, p)

    -- Copy-ready text for other addons.
    rows[#rows + 1] = { header = "Copy for other addons (click a row)" }
    local pawn, plain = Ro.PawnString(w), Ro.PlainList(w)
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\INV_Misc_Note_01", name = "Pawn scale", sub = pawn,
        cols = { "", "", "copy" }, colColors = { nil, nil, W.GOLD },
        onClick = function() T.ShowCopy("Pawn scale", pawn) end,
        tooltip = function(tt)
            tt:AddLine("Pawn scale", 1, 1, 1)
            tt:AddLine("Click, then press Ctrl+C. In Pawn: Scale tab, Import, paste with Ctrl+V.", 1, 0.82, 0, true)
            tt:AddLine(pawn, 0.91, 0.89, 0.78, true)
            W.AddNote(tt, "🔶 This is Pawn's own scale format from the Classic-era addon. We haven't checked that Pawn runs in Forever, or that it reads Forever's \"crit by 1%\" lines as CritRating. Hover an item after importing to check.")
        end,
    }
    rows[#rows + 1] = {
        icon = "Interface\\Icons\\INV_Misc_Book_09", name = "Plain list", sub = plain,
        cols = { "", "", "copy" }, colColors = { nil, nil, W.GOLD },
        onClick = function() T.ShowCopy("Plain list", plain) end,
        tooltip = function(tt)
            tt:AddLine("Plain list", 1, 1, 1)
            tt:AddLine("For any other gear addon, or to write down. Click, then press Ctrl+C.", 1, 0.82, 0, true)
            tt:AddLine(plain, 0.91, 0.89, 0.78, true)
        end,
    }

    -- Optional detail: where a weight comes from, part by part.
    local folded = not W.IsFolded("simlab", "weightDetailOpen")   -- folded up unless you opened it
    rows[#rows + 1] = {
        header = "Detail: what 1 point adds to each part", foldable = true, collapsed = folded,
        onClick = function()
            W.SetFolded("simlab", "weightDetailOpen", folded)
            T.Update(T.page)
        end,
    }
    if not folded then
        for _, key in ipairs({ "sp", "int", "str", "agi" }) do
            local r = w.rows[key]
            local def
            for _, d in ipairs(Ro.WEIGHTS) do if d.key == key then def = d end end
            if r and r.byPart then
                for _, bp in ipairs(r.byPart) do
                    rows[#rows + 1] = {
                        icon = def.icon, name = ("1 %s → %s"):format(def.label, bp.name),
                        sub = "part of the one number above",
                        cols = { "", f(bp.gain, 3) .. " " .. unit, w.unitGain > 0 and f(bp.gain / w.unitGain, 2) or "?" },
                        colColors = { nil, W.GREY, W.GREY },
                        tooltip = function(tt)
                            tt:AddLine(("1 %s → %s"):format(def.label, bp.name), 1, 1, 1)
                            tt:AddLine(("These rows add up to the %s weight above. They show WHERE the value comes from: a part you use a lot (or that hits hard) gets a bigger share. A part you use rarely, like Flame Shock once every 12 sec, only gets a small share."):format(def.label), 1, 0.82, 0, true)
                        end,
                    }
                end
            end
        end
    end
    return rows
end

-- A small box with the text selected, so Ctrl+C copies it.
function T.ShowCopy(title, text)
    local page = T.page
    if not page then return end
    local box = page.copyBox
    if not box then
        box = W.Panel(page)
        box:SetSize(page.list.frame:GetWidth() or 384, 74)
        box:SetPoint("BOTTOMLEFT", page.list.frame, "BOTTOMLEFT", 0, 0)
        box:SetFrameLevel((page.list.frame:GetFrameLevel() or 1) + 10)
        box.title = W.Text(box, "GameFontNormal", nil, "LEFT")
        box.title:SetPoint("TOPLEFT", 10, -8)
        box.hint = W.Text(box, "GameFontDisableSmall", nil, "LEFT")
        box.hint:SetPoint("TOPLEFT", 10, -26)
        box.hint:SetText("Press Ctrl+C to copy, then Esc to close.")
        local eb = W.Create("EditBox", nil, box, { "InputBoxTemplate" })
        eb:SetHeight(20)
        eb:SetPoint("BOTTOMLEFT", 14, 8)
        eb:SetPoint("BOTTOMRIGHT", -90, 8)
        eb:SetAutoFocus(false)
        -- Read only: typing puts the text back.
        eb:SetScript("OnTextChanged", function(self, user)
            if user and box.text then self:SetText(box.text); self:HighlightText() end
        end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); box:Hide() end)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box.edit = eb
        local close = W.Button(box, "Close", 70)
        close:SetPoint("BOTTOMRIGHT", -8, 7)
        close:SetScript("OnClick", function() box:Hide() end)
        page.copyBox = box
    end
    box.text = text
    box.title:SetText(title)
    box.edit:SetText(text)
    box:Show()
    box.edit:SetFocus()
    box.edit:HighlightText()
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
    { "Hit chance", "spellHit", 0, "Interface\\Icons\\Ability_Marksmanship", "%" },
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

    for key, row in pairs(page.sliders) do row:Set(T.add[key] or 0, false) end
    updateItemBox(page)
    if page.copyBox and viewId ~= "weights" then page.copyBox:Hide() end

    -- Talents: tick + points, read from your character unless you changed them.
    local S = ns.SimMath
    local anyChanged = false
    for key, row in pairs(page.talents) do
        local info = S.Talent(key)
        row:SetRange(0, info.max)
        row:Set(info.set, false)
        if row.check.SetChecked then row.check:SetChecked(info.on) end
        row.label:SetTextColor(info.on and 1 or 0.6, info.on and 0.82 or 0.6, info.on and 0 or 0.6)
        anyChanged = anyChanged or info.changed
    end
    if anyChanged then page.talentReset:Enable() else page.talentReset:Disable() end
    local style = ns.Rotation.Style()
    for id, b in pairs(page.styleButtons) do
        if id == style.id then b:LockHighlight() else b:UnlockHighlight() end
    end
    page.fight:Set(ns.Rotation.FightSeconds(), false)

    local p = ns.Profile.Player()
    local opts = S.TalentOpts()
    opts.weapon = T.item and T.item.weapon
    local q, why = S.Apply(p, T.add, opts)

    local rows
    if viewId == "weapon" then
        rows = weaponRows(p, q, why, opts)
    elseif viewId == "weights" then
        rows = weightRows(p, q, opts)
    elseif viewId == "stats" then
        rows = statRows(p, q, why)
    elseif viewId == "spells" then
        rows = spellRows(p, q, why, metric)
    else
        rows = totalRows(p, q, why, opts)
    end
    page.list:SetRows(rows)
end
