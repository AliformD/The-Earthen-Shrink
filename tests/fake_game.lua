-- Fake WoW API to smoke-test the addon outside the game.
-- Run from the repo root: lua5.1 tests/fake_game.lua TheEarthenShrink
-- All numbers in here are MADE UP test values, not Forever data.
local ADDON_DIR = arg[1]
local frames = {}
local function newObj(kind)
  local o = { _kind = kind, _scripts = {}, _shown = true, _text = "", _events = {} }
  return setmetatable(o, { __index = function(t, k)
    local special = {
      GetFont = function() return "Fonts\\FRIZQT__.TTF", 12, "" end,
      CreateFontString = function() return newObj("FontString") end,
      CreateTexture = function() return newObj("Texture") end,
      SetScript = function(self, n, fn) self._scripts[n] = fn end,
      GetScript = function(self, n) return self._scripts[n] end,
      Show = function(self) self._shown = true end,
      Hide = function(self) self._shown = false end,
      SetShown = function(self, v) self._shown = v and true or false end,
      IsShown = function(self) return self._shown end,
      SetText = function(self, s) self._text = s end,
      GetText = function(self) return self._text end,
      RegisterEvent = function(self, e) if not rawget(self, "_reg") then self._reg=true; frames[#frames+1] = self end; self._events[e] = true end,
      StartMoving = function() end, StopMovingOrSizing = function() end,
    }
    if special[k] then return special[k] end
    if type(k) == "string" and k:match("^[a-z_]") then return nil end  -- fields we never set are nil, like in the game
    return function() end
  end })
end
function CreateFrame(kind, name, parent, template) local o = newObj(kind); if name then _G[name] = o end; return o end
UISpecialFrames = {}
UIParent = newObj("Frame")
GameTooltip = newObj("GameTooltip")
local tlines = {}
GameTooltip.AddLine = function(_, s) tlines[#tlines+1] = s end
GameTooltip.AddDoubleLine = function(_, a, b) tlines[#tlines+1] = a .. "  ||  " .. b end
function print(...) local t = {...}; for i = 1, select("#", ...) do t[i] = tostring(t[i]) end; io.write(table.concat(t, " "), "\n") end
C_Timer = { After = function(s, fn) PENDING = PENDING or {}; PENDING[#PENDING+1] = fn end }
function InCombatLockdown() return false end
function UnitName(u) return u == "player" and "Angel" or "Kaz" end
function UnitLevel(u) return u == "player" and 30 or 28 end
function UnitClass(u) return "Shaman", "SHAMAN" end
function UnitExists() return true end
function UnitIsPlayer() return true end
function UnitIsUnit(a, b) return a == b end
function UnitGUID(u) return u == "player" and "P-1" or "P-2" end
function CanInspect() return true end
function CheckInteractDistance() return true end
function NotifyInspect(u) INSPECTED = u end
function UnitPowerMax(u) return u == "player" and 1450 or 1200 end
function UnitPower() return 1300 end
function GetSpellBonusDamage(i) return 64 end
function GetSpellBonusHealing() return 90 end
function GetInventoryItemTexture() return 135000 end
function GetSpellCritChance() return 4.5 end
function GetCritChance() return 6.2 end
function GetHitModifier() return 1 end
function GetSpellHitModifier() return 1 end
function UnitAttackPower() return 300, 40, 0 end
function UnitAttackSpeed() return 3.6 end
function GetWeaponEnchantInfo() return false end
function GetInventoryItemLink(u, slot) if slot == 16 then return "|cff0070dd|Hitem:1:0|h[Grinning Axe]|h|r" end if slot == 1 then return "|Hitem:2|h[Hat]|h" end end
function GetInventoryItemID(u, slot) if slot == 16 then return 1 end if slot == 1 then return 2 end end
C_Item = { IsItemDataCachedByID = function() return true end }
C_TooltipInfo = {
  GetInventoryItem = function(u, slot)
    if slot == 16 then return { lines = { {leftText="Grinning Axe"}, {leftText="45 - 84 Damage", rightText="Speed 3.60"}, {leftText="+8 Strength"}, {leftText="Equip: Improves your chance to get a critical strike by 1%."} } } end
    if slot == 1 then return { lines = { {leftText="Hat"}, {leftText="+10 Intellect"}, {leftText="Equip: Increases damage and healing done by magical spells and effects by up to 12."} } } end
  end,
  GetSpellByID = function(id) local s = SPELLS[id]; if not s then return nil end; return { lines = { {leftText=s.name, rightText="Rank "..s.rank}, {leftText=s.mana.." Mana"}, {leftText=s.desc} } } end,
}
SPELLS = {
  [403] = { name="Lightning Bolt", rank=1, mana=15, cast=1500, desc="Casts a bolt of lightning at the target for 15 to 17 Nature damage.", lvl=1 },
  [529] = { name="Lightning Bolt", rank=2, mana=30, cast=2000, desc="Casts a bolt of lightning at the target for 28 to 33 Nature damage.", lvl=8 },
  [548] = { name="Lightning Bolt", rank=3, mana=45, cast=2500, desc="Casts a bolt of lightning at the target for 48 to 57 Nature damage.", lvl=14 },
  [915] = { name="Lightning Bolt", rank=4, mana=75, cast=2500, desc="Casts a bolt of lightning at the target for 88 to 100 Nature damage.", lvl=20 },
  [943] = { name="Lightning Bolt", rank=5, mana=105, cast=2500, desc="Casts a bolt of lightning at the target for 1,131 to 1,149 Nature damage.", lvl=26 },
  [6041]= { name="Lightning Bolt", rank=6, mana=135, cast=2500, desc="Casts a bolt of lightning at the target for 178 to 202 Nature damage.", lvl=32 },
  [8050]= { name="Flame Shock", rank=1, mana=55, cast=0, desc="Instantly sears the target with fire, causing 25 Fire damage immediately and 28 Fire damage over 12 sec.", lvl=10 },
  [8042]= { name="Earth Shock", rank=1, mana=30, cast=0, desc="Instantly shocks the target with concussive force, causing 19 to 22 Nature damage.", lvl=4 },
  [8017]= { name="Rockbiter Weapon", rank=1, mana=20, cast=0, desc="Imbue the Shaman's weapon, increasing attack power by 50 for 60 min.", lvl=1 },
  [10399]={ name="Rockbiter Weapon", rank=4, mana=60, cast=0, desc="Imbue the Shaman's weapon, increasing attack power by 150 for 60 min.", lvl=24 },
  [8030]= { name="Flametongue Weapon", rank=3, mana=60, cast=0, desc="Imbue the Shaman's weapon with fire. Each hit causes 4.71 to 18 additional Fire damage, based on the speed of the weapon.", lvl=26 },
  -- Real Forever rank 1 text (Angel, 2026-11-12). "melee" broke the old reader.
  [8232]= { name="Windfury Weapon", rank=1, mana=95, cast=0, desc="Imbue the Shaman's weapon with wind. Each hit has a 20% chance of granting you two extra attacks with 104 extra melee attack power. When applied to main hand, disables any benefit you personally receive from Windfury Totem.", lvl=30 },
  [8033]= { name="Frostbrand Weapon", rank=1, mana=50, cast=0, desc="Imbue the Shaman's weapon with frost. Each hit has a chance of causing 23 additional Frost damage and slowing the target.", lvl=20 },
  [8038]= { name="Frostbrand Weapon", rank=2, mana=70, cast=0, desc="Imbue the Shaman's weapon with frost. Each hit has a chance of causing 34 additional Frost damage and slowing the target.", lvl=28 },
  [8512]= { name="Windfury Totem", rank=1, mana=115, cast=0, desc="Summons a Windfury Totem. Party members' melee attacks have a 20% chance of granting 1 extra attack with 122 extra attack power. Lasts 2 min.", lvl=30 },
  [324] = { name="Lightning Shield", rank=1, mana=45, cast=0, desc="Surrounds the caster with balls of lightning that deal 13 Nature damage to attackers. 3 charges. Lasts 10 min.", lvl=8 },
  [905] = { name="Lightning Shield", rank=3, mana=100, cast=0, desc="Surrounds the caster with balls of lightning that deal 50 Nature damage to attackers. 3 charges. Lasts 10 min.", lvl=24 },
  [3599]= { name="Searing Totem", rank=1, mana=25, cast=0, desc="Summons a Searing Totem that attacks one enemy within 20 yards for 9 to 11 Fire damage. Lasts 30 sec.", lvl=10 },
  [6363]= { name="Searing Totem", rank=2, mana=45, cast=0, desc="Summons a Searing Totem that attacks one enemy within 20 yards for 13 to 17 Fire damage. Lasts 35 sec.", lvl=20 },
  [8190]= { name="Magma Totem", rank=1, mana=230, cast=0, desc="Summons a Magma Totem that causes 22 Fire damage to all enemies within 8 yards every 2 sec. Lasts 20 sec.", lvl=26 },
  [5394]= { name="Healing Stream Totem", rank=1, mana=40, cast=0, desc="Summons a Healing Stream Totem that heals group members within 20 yards for 6 every 2 sec. Lasts 5 min.", lvl=20 },
  [5675]= { name="Mana Spring Totem", rank=1, mana=40, cast=0, desc="Summons a Mana Spring Totem that restores 4 mana to group members within 20 yards every 2 sec. Lasts 5 min.", lvl=26 },
  [8071]= { name="Stoneskin Totem", rank=1, mana=30, cast=0, desc="Party members take 4 less damage from melee attacks. Lasts 5 min.", lvl=4 },
  [331] = { name="Healing Wave", rank=1, mana=25, cast=1500, desc="Heals a friendly target for 34 to 44.", lvl=1 },
  [547] = { name="Healing Wave", rank=3, mana=80, cast=2500, desc="Heals a friendly target for 136 to 163.", lvl=12 },
  [939] = { name="Healing Wave", rank=5, mana=200, cast=3000, desc="Heals a friendly target for 389 to 454.", lvl=24 },
  [8004]= { name="Lesser Healing Wave", rank=1, mana=105, cast=1500, desc="Heals a friendly target for 162 to 186.", lvl=20 },
  [77001]={ name="Stormstrike", rank=1, mana=40, cast=0, desc="Instantly strike an enemy with both weapons. Your next Lightning Bolt, Chain Lightning or Earth Shock deals 20% more damage.", lvl=20 },
  [77002]={ name="Call of the Elements", rank=1, mana=0, cast=3000, desc="Calls the 4 totems you have saved.", lvl=20 },
  [1535] = { name="Fire Nova", rank=1, mana=95, cast=0, desc="Your Fire totem explodes, causing 53 to 62 Fire damage to all enemies within 10 yards.", lvl=12 },
}
local BOOK = { 77001, 77002 }
C_SpellBook = {
  GetNumSpellBookSkillLines = function() return 1 end,
  GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #BOOK, name = "Shaman" } end,
  GetSpellBookItemInfo = function(i) local id = BOOK[i]; return { spellID = id, name = SPELLS[id].name, subName = "" } end,
}
C_Spell = {
  GetSpellInfo = function(id) local s = SPELLS[id]; if s then return { name = s.name, castTime = s.cast, iconID = 136048 } end end,
  GetSpellDescription = function(id) return SPELLS[id] and SPELLS[id].desc end,
  GetSpellPowerCost = function(id) local s = SPELLS[id]; if s then return { { type = 0, name = "MANA", cost = s.mana } } end end,
  GetSpellLevelLearned = function(id) return SPELLS[id] and SPELLS[id].lvl end,
  RequestLoadSpellData = function() end,
}
SlashCmdList = {}
-- Sim Lab: shift-click hooks, dragging items, and reading item links.
HOOKS = {}
function hooksecurefunc(name, fn) HOOKS[name] = HOOKS[name] or {}; table.insert(HOOKS[name], fn) end
function HandleModifiedItemClick() end
function ChatEdit_InsertLink() end
function IsModifiedClick() return true end
function ClearCursor() CURSOR = nil end
function GetCursorInfo() if CURSOR then return "item", 3, CURSOR end end
function GetInventoryItemTexture() return 135000 end
local ITEMS = {
  ["3"] = { loc = "INVTYPE_HEAD", lines = { {leftText="Thinking Cap"}, {leftText="+17 Strength"}, {leftText="+4 Stamina"} } },
  ["4"] = { loc = "INVTYPE_2HWEAPON", lines = { {leftText="Big Hammer"}, {leftText="80 - 120 Damage", rightText="Speed 3.40"}, {leftText="+10 Strength"} } },
  ["5"] = { loc = "INVTYPE_FINGER", lines = { {leftText="Ring"}, {leftText="+5 Intellect"} } },
  ["6"] = { loc = "INVTYPE_BAG", lines = { {leftText="Bag"} } },
}
C_Item.GetItemInfoInstant = function(link) local id = link:match("item:(%d+)"); return tonumber(id), "Armor", "Misc", ITEMS[id] and ITEMS[id].loc end
C_Item.GetItemIconByID = function() return 133000 end
C_Item.GetItemStats = function() return {} end
C_TooltipInfo.GetHyperlink = function(link) local id = link:match("item:(%d+)"); return ITEMS[id] and { lines = ITEMS[id].lines } end

-- Fake minimap: 140 wide, centre at (1000, 700), scale 1.
Minimap = newObj("Frame")
Minimap.GetWidth = function() return 140 end
Minimap.GetCenter = function() return 1000, 700 end
Minimap.GetEffectiveScale = function() return 1 end
MOUSE = { 1000, 800 }
function GetCursorPosition() return MOUSE[1], MOUSE[2] end
local ns = {}
for line in io.lines(ADDON_DIR .. "/TheEarthenShrink.toc") do
  if not line:match("^##") and line:match("%S") then
    local chunk = assert(loadfile(ADDON_DIR .. "/" .. line:gsub("\\", "/")))
    chunk("TheEarthenShrink", ns)
  end
end
local function fire(e, ...) for _, f in ipairs(frames) do if f._events[e] then f._scripts.OnEvent(f, e, ...) end end end
local function runTimers() local p = PENDING or {}; PENDING = {}; for _, fn in ipairs(p) do fn() end end
fire("ADDON_LOADED", "TheEarthenShrink")
runTimers()
SlashCmdList.THEEARTHENSHRINK("check")
SlashCmdList.THEEARTHENSHRINK("")
-- dump weapon tab
local function dump(id)
  local page = TheEarthenShrinkFrame.pages[id]
  print("=== " .. id)
  for i, c in ipairs(page.chips) do print("chip", c.label._text, c.value._text) end
  for _, r in ipairs(page.list.rows) do
    if r._shown then
      local cols = {}
      for _, t in ipairs(r.cols) do cols[#cols+1] = tostring(t._text) end
      print(r.data.header and ("-- " .. r.data.header) or (r.name._text .. " | " .. r.sub._text .. " | " .. table.concat(cols, " / ")))
      if r.data.tooltip then tlines = {}; r.data.tooltip(GameTooltip); for _, l in ipairs(tlines) do print("     tt: " .. l) end end
    end
  end
  if rawget(page, "message") then print("CHAT(" .. #page.message .. "): " .. page.message) end
end
dump("weapon")
SlashCmdList.THEEARTHENSHRINK("spells")
dump("spells")
-- Fold up Lightning Bolt: its rank rows go away, the title stays
do
  local sp = TheEarthenShrinkFrame.pages.spells
  local function count(name)
    local n = 0
    for _, r in ipairs(sp.list.rows) do if r._shown and r.data.name == name then n = n + 1 end end
    return n
  end
  local before = count("Lightning Bolt")
  for _, r in ipairs(sp.list.rows) do if r._shown and r.data.header == "Lightning Bolt" then r._scripts.OnClick(r) end end
  print("Lightning Bolt rows:", before, "->", count("Lightning Bolt"))
  assert(before > 0 and count("Lightning Bolt") == 0 and ns.db().collapsed.spells.LB)
  sp.fold._scripts.OnClick()   -- some open: collapse all
  assert(count("Earth Shock") == 0)
  sp.fold._scripts.OnClick()   -- all folded: expand all
  assert(count("Lightning Bolt") == before and not ns.db().collapsed.spells.LB)
  print("fold tests passed")
end
TheEarthenShrinkFrame.pages.spells.sort._scripts.OnClick()
dump("spells")
SlashCmdList.THEEARTHENSHRINK("inspect")
fire("INSPECT_READY", "P-2")
runTimers()
ns.UI.Update()
dump("inspect")
ns.Chat.OpenInChatBox(TheEarthenShrinkFrame.pages.inspect.message)
SlashCmdList.THEEARTHENSHRINK("totems")
dump("totems")
SlashCmdList.THEEARTHENSHRINK("spells")
TheEarthenShrinkFrame.pages.spells.sort._scripts.OnClick()
dump("spells")
SlashCmdList.THEEARTHENSHRINK("healing")
dump("healing")
-- trainer test: Forever has a new Chain Lightning ID 99001 at level 28
SPELLS[99001] = { name="Chain Lightning", rank=1, mana=120, cast=2000, desc="Hurls a lightning bolt at the enemy, dealing 200 to 227 Nature damage and then jumping to additional nearby enemies.", lvl=0 }
function GetNumTrainerServices() return 2 end
function GetTrainerServiceInfo(i) if i == 1 then return "Chain Lightning", "Rank 1", "available" end return "Healing Wave", "Rank 3", "used" end
function GetTrainerServiceLevelReq(i) return 28 end
C_TooltipInfo.GetTrainerService = function(i) return { id = 99001 } end
fire("TRAINER_SHOW"); runTimers(); runTimers()
SlashCmdList.THEEARTHENSHRINK("spells")
dump("spells")
-- Fold up Lightning Bolt: its rank rows go away, the title stays
do
  local sp = TheEarthenShrinkFrame.pages.spells
  local function count(name)
    local n = 0
    for _, r in ipairs(sp.list.rows) do if r._shown and r.data.name == name then n = n + 1 end end
    return n
  end
  local before = count("Lightning Bolt")
  for _, r in ipairs(sp.list.rows) do if r._shown and r.data.header == "Lightning Bolt" then r._scripts.OnClick(r) end end
  print("Lightning Bolt rows:", before, "->", count("Lightning Bolt"))
  assert(before > 0 and count("Lightning Bolt") == 0 and ns.db().collapsed.spells.LB)
  sp.fold._scripts.OnClick()   -- some open: collapse all
  assert(count("Earth Shock") == 0)
  sp.fold._scripts.OnClick()   -- all folded: expand all
  assert(count("Lightning Bolt") == before and not ns.db().collapsed.spells.LB)
  print("fold tests passed")
end
-- Sim Lab
SlashCmdList.THEEARTHENSHRINK("sim")
local sim = TheEarthenShrinkFrame.pages.simlab
local function dumpSim(title)
  print("=== simlab: " .. title)
  print("item:", sim.itemName._text, "|", sim.itemSub._text)
  local adds = {}
  for _, st in ipairs(ns.SimMath.STATS) do adds[#adds+1] = st.key .. "=" .. tostring(sim.sliders[st.key].value._text) end
  print("sliders:", table.concat(adds, " "))
  for _, r in ipairs(sim.list.rows) do
    if r._shown then
      local cols = {}
      for _, t in ipairs(r.cols) do cols[#cols+1] = tostring(t._text) end
      print(r.data.header and ("-- " .. r.data.header) or (r.name._text .. " | " .. r.sub._text .. " | " .. table.concat(cols, " / ")))
    end
  end
end
ns.Tabs.simlab.SetView("spells")
dumpSim("nothing changed")
sim.sliders.str:Set(17, true)
dumpSim("+17 Strength from the slider")
local melee
for _, r in ipairs(sim.list.rows) do if r._shown and r.data.name == "Melee swing" then melee = r end end
tlines = {}; melee.data.tooltip(GameTooltip); for _, l in ipairs(tlines) do print("     tt: " .. l) end
sim.sliders.int.plus._scripts.OnClick()
assert(ns.Tabs.simlab.add.int == 1, "plus button adds 1")
sim.metric._scripts.OnClick()
dumpSim("+1 Int by the + button, per mana")
-- shift-click an item somewhere in the game
for _, fn in ipairs(HOOKS.HandleModifiedItemClick) do fn("|cffffffff|Hitem:3::|h[Thinking Cap]|h|r") end
for _, fn in ipairs(HOOKS.ChatEdit_InsertLink) do fn("|cffffffff|Hitem:3::|h[Thinking Cap]|h|r") end
dumpSim("shift-clicked a hat: +17 Str vs the worn hat (+10 Int, 12 spell power)")
assert(ns.Tabs.simlab.add.str == 17 and ns.Tabs.simlab.add.int == -10 and ns.Tabs.simlab.add.sp == -12)
-- drop a weapon on the box
CURSOR = "|cffffffff|Hitem:4::|h[Big Hammer]|h|r"
sim.itemButton._scripts.OnReceiveDrag()
sim.metric._scripts.OnClick()
dumpSim("dropped a 2-hander, per second")
assert(ns.Tabs.simlab.item.weapon and ns.Tabs.simlab.item.weapon.speed == 3.4)
assert(ns.Tabs.simlab.add.str == 2, "hammer +10 Str vs axe +8 Str")
for _, fn in ipairs(HOOKS.ChatEdit_InsertLink) do fn("|Hitem:5|h[Ring]|h") end
sim.otherSlot._scripts.OnClick()
dumpSim("ring, other slot")
for _, fn in ipairs(HOOKS.ChatEdit_InsertLink) do fn("|Hitem:6|h[Bag]|h") end
dumpSim("a bag")
ns.SimMath.SetTalentPoints("MD", 3)
sim.clear._scripts.OnClick()
dumpSim("cleared")
-- Weapon buff view: does a lot of spell power make Flametongue the best?
ns.Tabs.simlab.SetView("weapon")
SlashCmdList.THEEARTHENSHRINK("ftcoef 0.5")
dumpSim("weapon view, ftcoef 0.5")
local function bestRow()
  for _, r in ipairs(sim.list.rows) do if r._shown and r.data.name and (r.data.name:find("^New best: ") or r.data.name:find("^Best: ")) then return r.data.name end end
end
print("best:", bestRow())
local need
for _, r in ipairs(sim.list.rows) do
  if r._shown and r.data.name == "Flametongue Weapon" and r.sub._text:find("Beats") then need = tonumber((r.cols[3]._text:gsub("[+,]", ""))) end
end
print("Flametongue needs +", need, "spell power")
assert(need and need > 0, "should say how much spell power Flametongue needs")
sim.sliders.sp:Set(math.min(150, need + 1), true)
dumpSim("weapon view, + spell power")
if need + 1 <= 150 then assert(bestRow():find("Flametongue"), "Flametongue should be best now") end
-- Flametongue Totem in group: Windfury's extra attacks get the totem fire
SlashCmdList.THEEARTHENSHRINK("fttotem on")
dumpSim("weapon view, Flametongue Totem on")
SlashCmdList.THEEARTHENSHRINK("fttotem off")
SlashCmdList.THEEARTHENSHRINK("ftcoef 0")
sim.clear._scripts.OnClick()
ns.Tabs.simlab.SetView("stats")
dumpSim("stats view")
-- Total view: the whole mix, now vs with changes
ns.Tabs.simlab.SetView("total")
dumpSim("total view, nothing changed")
sim.sliders.str:Set(20, true)
dumpSim("total view, +20 Str")
local totalRow = sim.list.rows[2]
assert(totalRow.data.name:find("all together"), "first row is the total")
assert(totalRow.cols[3]._text:find("^%+"), "more Strength = more total DPS")
sim.clear._scripts.OnClick()
-- Weights view: one number per stat, Strength = 1
ns.Tabs.simlab.SetView("weights")
dumpSim("weights view")
local W8 = ns.Tabs.simlab.lastWeights
assert(math.abs(W8.rows.str.weight - 1) < 1e-6, "Strength is 1.00")
assert(W8.rows.agi.weight > 0 and W8.rows.ap.weight > 0 and W8.rows.wdps.weight > 0, "melee stats count")
assert(W8.rows.sp.weight > 0, "spell power counts (shocks, shield, totem)")
assert(W8.rows.sta.weight == 0.25, "stamina estimate")
local intNoTalents = W8.rows.int.weight
ns.SimMath.SetTalentPoints("MQ", 2)
ns.Tabs.simlab.Update(sim)
print("Int weight: MD 3 + MQ 0 =", intNoTalents, " MD 3 + MQ 2 =", ns.Tabs.simlab.lastWeights.rows.int.weight)
assert(ns.Tabs.simlab.lastWeights.rows.int.weight > intNoTalents, "Mental Quickness makes Intellect worth more")
print("PAWN:", ns.Rotation.PawnString(ns.Tabs.simlab.lastWeights))
print("PLAIN:", ns.Rotation.PlainList(ns.Tabs.simlab.lastWeights))
for _, r in ipairs(sim.list.rows) do if r._shown and r.data.name == "Pawn scale" then r._scripts.OnClick(r) end end
assert(sim.copyBox and sim.copyBox.edit._text:find("^%( Pawn: v1:"), "copy box has the Pawn string")
-- Detail section opens
for _, r in ipairs(sim.list.rows) do if r._shown and r.data.header and r.data.header:find("^Detail") then r._scripts.OnClick(r) end end
dumpSim("weights view, detail open")
-- Talents: turn off, then back to real
ns.SimMath.SetTalentOn("MD", false)
assert(ns.SimMath.Talent("MD").points == 0 and ns.SimMath.Talent("MD").set == 3)
ns.SimMath.SetTalentOn("MD", true)
assert(ns.SimMath.Talent("MD").points == 3)
ns.SimMath.ResetTalents()
assert(ns.SimMath.Talent("MD").points == 0, "no real talents in the fake game")
-- Caster and healer styles
ns.db().simStyle = "ele"; ns.Tabs.simlab.SetView("total"); dumpSim("caster total")
ns.Tabs.simlab.SetView("weights"); dumpSim("caster weights")
assert(math.abs(ns.Tabs.simlab.lastWeights.rows.sp.weight - 1) < 1e-6, "caster: Spell Power is 1.00")
ns.db().simStyle = "resto"; ns.Tabs.simlab.Update(sim); dumpSim("healer weights")
assert(math.abs(ns.Tabs.simlab.lastWeights.rows.heal.weight - 1) < 1e-6, "healer: Healing is 1.00")
-- The Healing slider changes heals now (it didn't before v0.10)
ns.Tabs.simlab.SetView("spells")
sim.sliders.heal:Set(50, true)
dumpSim("healing +50")
for _, r in ipairs(sim.list.rows) do
  if r._shown and r.data.name == "Healing Wave" then assert(r.cols[3]._text:find("^%+"), "Healing slider raises Healing Wave") end
end
sim.clear._scripts.OnClick()
ns.db().simStyle = "enh"
-- Window closed: shift-clicks are ignored
TheEarthenShrinkFrame:Hide()
for _, fn in ipairs(HOOKS.ChatEdit_InsertLink) do fn("|Hitem:3|h[Thinking Cap]|h") end
assert(ns.Tabs.simlab.item == nil, "ignored while closed")

-- Windfury sound test (the events here are FAKE; the real client is untested)
SOUNDS = 0
function GetTime() return (FAKE_TIME or 0) end
function PlaySound(id, ch) SOUNDS = SOUNDS + 1; print("PlaySound", id, ch) end
C_Spell.GetSpellName = function(id) return ({ [25584] = "Windfury Attack", [8232] = "Windfury Weapon" })[id] end
SlashCmdList.THEEARTHENSHRINK("sound test")
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 8232)   -- buffing the weapon: no sound
FAKE_TIME = 10
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-2", 25584)  -- proc: sound
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-3", 25584)  -- same proc again: no 2nd sound
FAKE_TIME = 14
SlashCmdList.THEEARTHENSHRINK("sound")                         -- switch off
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-4", 25584)  -- off: no sound
SlashCmdList.THEEARTHENSHRINK("sound on")
SlashCmdList.THEEARTHENSHRINK("sound test")
print("sounds played (expect 2: test + 1 proc):", SOUNDS)
assert(SOUNDS == 2)

-- Weapon buff comparison tests -------------------------------------------
local function compare()
  local out = {}
  for _, e in ipairs(ns.ImbueMath.Compare(ns.Profile.Player())) do
    out[e.key] = e
  end
  return out, ns.ImbueMath.Compare(ns.Profile.Player())[1].key
end
local base, best = compare()
print("default:", best, "WF", base.WF.calc.dps, "RB", base.RB.calc.dps, "FT", base.FT.calc.dps, "FB", base.FB.calc.dps)
assert(base.WF.calc and not base.WF.calc.fromFallback, "WF tooltip should be read now")

-- Windfury Totem on: the totem helps every buff; WF still adds on top if they stack
SlashCmdList.THEEARTHENSHRINK("wftotem on")
local t1 = compare()
print("totem on, stacks:", "WF", t1.WF.calc.dps, "RB", t1.RB.calc.dps)
assert(t1.RB.calc.dps > base.RB.calc.dps, "Rockbiter should gain from totem extra attacks")
SlashCmdList.THEEARTHENSHRINK("wfstack off")
local t2 = compare()
print("totem on, no stack:", "WF", t2.WF.calc.dps, "RB", t2.RB.calc.dps)
assert(t2.WF.calc.dps < t1.WF.calc.dps, "WF should be worth less when it turns the totem off")
SlashCmdList.THEEARTHENSHRINK("wftotem off")
SlashCmdList.THEEARTHENSHRINK("wfstack on")

-- Flametongue spell power setting
SlashCmdList.THEEARTHENSHRINK("ftcoef 0.5")
local c1 = compare()
print("ftcoef 0.5: FT", c1.FT.calc.dps)
assert(c1.FT.calc.dps > base.FT.calc.dps)
SlashCmdList.THEEARTHENSHRINK("ftcoef 0")

-- Tooltip missing: Windfury rank 1 falls back to the built-in numbers
local saved = SPELLS[8232].desc
SPELLS[8232].desc = ""
ns.SpellData.Rebuild()
local fb = compare()
print("WF no tooltip:", fb.WF.calc and fb.WF.calc.dps, fb.WF.calc and fb.WF.calc.fromFallback)
assert(fb.WF.calc and fb.WF.calc.fromFallback and math.abs(fb.WF.calc.dps - base.WF.calc.dps) < 0.01)
SPELLS[8232].desc = saved
ns.SpellData.Rebuild()

-- Rockbiter already on the weapon: its 150 AP is taken out first
local oldTT = C_TooltipInfo.GetInventoryItem
C_TooltipInfo.GetInventoryItem = function(u, slot)
  local d = oldTT(u, slot)
  if slot == 16 then table.insert(d.lines, { leftText = "Rockbiter 4 (59 min)" }) end
  return d
end
local oldAP = UnitAttackPower
function UnitAttackPower() return 450, 40, 0 end   -- 340 + 150 from Rockbiter
local rb = compare()
print("Rockbiter on:", "WF", rb.WF.calc.dps, "RB", rb.RB.calc.dps)
assert(math.abs(rb.WF.calc.dps - base.WF.calc.dps) < 0.01, "Rockbiter AP should be removed")
C_TooltipInfo.GetInventoryItem, UnitAttackPower = oldTT, oldAP
print("weapon buff tests passed")

-- Spell Power Test tab ------------------------------------------------------
-- All hit numbers here are MADE UP to check the math, not Forever data.
FAKE_SP = 64
function GetSpellBonusDamage(i) return FAKE_SP end
SlashCmdList.THEEARTHENSHRINK("test")
local ct = TheEarthenShrinkFrame.pages.coef
local CT = ns.CoefTest
local function dumpCoef(title)
  print("=== sp test: " .. title)
  for _, r in ipairs(ct.list.rows) do
    if r._shown then print(r.data.header and ("-- " .. r.data.header) or (r.name._text .. " | " .. r.sub._text .. " | " .. tostring(r.subRight._text) .. (r.data.selected and "  <selected>" or ""))) end
  end
  print("BEFORE: " .. ct.before.body._text:gsub("\n", " / ") .. "  [" .. ct.before.state._text .. "]")
  print("AFTER:  " .. ct.after.body._text:gsub("\n", " / ") .. "  [" .. ct.after.state._text .. "]")
  print("label:  " .. ct.entryLabel._text)
  print("msg:    " .. ct.msg._text)
  print("big:    " .. ct.big._text .. "   " .. ct.verdict._text)
  for l in (ct.body._text .. "\n"):gmatch("(.-)\n") do print("   | " .. l) end
  print("saved:  " .. ct.saved._text)
end
dumpCoef("empty")
-- pick Lightning Bolt
local lbRow
for _, r in ipairs(ct.list.rows) do if r._shown and r.data.name == "Lightning Bolt" then lbRow = r end end
lbRow._scripts.OnClick(lbRow)
local t = ns.Tabs.coef.target
assert(t.spell.key == "LB" and t.part == "direct")
-- Before: 20 hits spread evenly over the tooltip range
ct.before._scripts.OnClick()
local lo, hi = t.rank.dmg.min, t.rank.dmg.max
local before = {}
for i = 0, 19 do before[#before+1] = tostring(math.floor(lo + (hi - lo) * i / 19 + 0.5)) end
ns.Tabs.coef.Submit(ct, table.concat(before, " "))
ns.Tabs.coef.Submit(ct, "11")          -- typo: too small
print("typo msg:", ct.msg._text)
assert(#CT.Test(t).before.hits == 20)
ns.Tabs.coef.Submit(ct, "5000")        -- crit / typo: too big
print("crit msg:", ct.msg._text)
assert(#CT.Test(t).before.hits == 20)
dumpCoef("20 before hits")
-- Gear changed but still on BEFORE: refused
FAKE_SP = 84
ns.Tabs.coef.Submit(ct, tostring(lo + 14))
print("sp changed msg:", ct.msg._text)
assert(#CT.Test(t).before.hits == 20)
-- After: +20 SP, every hit 14 bigger (coefficient 0.7)
ct.after._scripts.OnClick()
local after = {}
for _, v in ipairs(before) do after[#after+1] = tostring(tonumber(v) + 14) end
ns.Tabs.coef.Submit(ct, table.concat(after, ", "))
dumpCoef("20 after hits, +20 SP")
local r = CT.Result(t)
assert(math.abs(r.coef - 0.7) < 1e-9, "coef should be 0.7")
assert(r.verdict == "rough", "20 hits each with +20 SP is too rough")
ct.save._scripts.OnClick()
assert(CT.Saved("LB", t.rank.rank).direct == nil, "rough results can't be saved")
-- 60 more hits in each box
FAKE_SP = 64; ct.before._scripts.OnClick()
for i = 1, 3 do ns.Tabs.coef.Submit(ct, table.concat(before, " ")) end
FAKE_SP = 84; ct.after._scripts.OnClick()
for i = 1, 3 do ns.Tabs.coef.Submit(ct, table.concat(after, " ")) end
r = CT.Result(t)
print("80 hits each:", r.coef, r.margin, r.verdict)
assert(r.verdict == "ok")
-- Save it and check the Spells math uses it
local before_calc = ns.SpellMath.Calc(t.spell, t.rank, ns.Profile.Player())
ct.save._scripts.OnClick()
local after_calc = ns.SpellMath.Calc(t.spell, t.rank, ns.Profile.Player())
print("directC rule:", before_calc.directC, "after save:", after_calc.directC, after_calc.coefSource.direct)
assert(after_calc.directC == 0.7 and after_calc.coefSource.direct == "test")
for _, l in ipairs(ns.SpellMath.Explain(t.spell, t.rank, after_calc)) do print("  explain:", type(l) == "table" and (l[1] .. " = " .. l[2]) or l) end
dumpCoef("saved")
-- Undo and Forget
ct.forget._scripts.OnClick()
assert(ns.SpellMath.Calc(t.spell, t.rank, ns.Profile.Player()).coefSource.direct == "rule")
-- Flame Shock ticks: fixed numbers, only rounding noise
local fsRow
for _, r in ipairs(ct.list.rows) do if r._shown and r.data.name == "Flame Shock" and r.sub._text:find("over time") then fsRow = r end end
fsRow._scripts.OnClick(fsRow)
local ft = ns.Tabs.coef.target
assert(ft.part == "tick")
FAKE_SP = 64
ct.before._scripts.OnClick()
dumpCoef("flame shock tick, empty")
ns.Tabs.coef.Submit(ct, "9 9 9 9 9 9 9 9")
FAKE_SP = 124
ct.after._scripts.OnClick()
ns.Tabs.coef.Submit(ct, "11 11 11 11 11 11")
dumpCoef("flame shock ticks, +60 SP")
local fr = CT.Result(ft)
print("tick coef", fr.coef, "total", fr.total, "margin", fr.totalMargin, fr.verdict)
assert(fr.ticks == 4 and math.abs(fr.total - 4 * 2 / 60) < 1e-9)
-- Planner numbers (made-up spread of 3.5 = a 12 point range)
print("hits needed +5/+20 SP:", ns.CoefMath.HitsNeeded(3.5, 5, 0.12), ns.CoefMath.HitsNeeded(3.5, 20, 0.12))
print("SP needed for 4 fixed ticks:", ns.CoefMath.SpellPowerNeeded(0.12, 4))
-- Combat log path (only if a client has it): fake one hit
CombatLogGetCurrentEventInfo = nil
SlashCmdList.THEEARTHENSHRINK("meter")
print("spell power test passed")

-- Flametongue Weapon, Searing Totem and the spell power stat weight -----------
FAKE_SP = 64
SlashCmdList.THEEARTHENSHRINK("test")
local function pick(name, part)
  for _, r in ipairs(ct.list.rows) do
    if r._shown and r.data.name == name and (not part or r.sub._text:find(part, 1, true)) then r._scripts.OnClick(r); return ns.Tabs.coef.target end
  end
end
dumpCoef("list with weapon buffs and totems")
local ftT = pick("Flametongue Weapon")
assert(ftT and ftT.part == "proc", "Flametongue Weapon is testable")
print("FT per hit guess:", ftT.avg, "every", ftT.every)
ct.before._scripts.OnClick()
ns.Tabs.coef.Submit(ct, "16 16 16 16 16 16")
FAKE_SP = 124
ct.after._scripts.OnClick()
ns.Tabs.coef.Submit(ct, "19 19 19 19 19 19")
dumpCoef("Flametongue, +60 SP")
local before_ft
for _, e in ipairs(ns.ImbueMath.Compare(ns.Profile.Player())) do if e.key == "FT" then before_ft = e.calc.dps end end
ct.save._scripts.OnClick()
local after_ft, ftLines
for _, e in ipairs(ns.ImbueMath.Compare(ns.Profile.Player())) do if e.key == "FT" then after_ft = e.calc.dps; ftLines = e.calc.lines end end
print("FT dps before save", before_ft, "after", after_ft)
assert(after_ft > before_ft, "saved Flametongue result is used by Weapon Buffs")
for _, l in ipairs(ftLines) do if type(l) == "table" and l[1]:find("Spell power") then print("  weapon tab:", l[1], l[2]) end end
local stT = pick("Searing Totem")
assert(stT and stT.part == "totem")
dumpCoef("Searing Totem, empty")
-- Sim Lab shows the stat weight rows
FAKE_SP = 64
SlashCmdList.THEEARTHENSHRINK("sim")
local LB = CT.Targets(30)[1]
CT.Test(LB).before = { sp = 64, hits = {} }
for i = 1, 4 do for _, v in ipairs(before) do table.insert(CT.Test(LB).before.hits, tonumber(v)) end end
CT.Test(LB).after = { sp = 84, hits = {} }
for i = 1, 4 do for _, v in ipairs(after) do table.insert(CT.Test(LB).after.hits, tonumber(v)) end end
assert(CT.Save(LB))
ns.UI.Update()
dumpSim("stat weights")
print("flametongue + stat weight tests passed")

-- Mental Quickness -----------------------------------------------------------
ns.SimMath.ResetTalents()
assert(ns.SimMath.Talent("MQ").points == 0, "no talent API in the fake game -> 0")
GetNumTalentTabs = function() return 1 end
GetNumTalents = function() return 2 end
GetTalentInfo = function(tab, i)
  if i == 1 then return "Mental Quickness", 0, 1, 1, 1, 5 end
  return "Mental Dexterity", 0, 1, 1, 2, 3
end
local mq = ns.SimMath.Talent("MQ")
print("mental quickness from talents:", mq.real, mq.max, mq.points)
assert(mq.real == 1 and mq.max == 5 and mq.points == 1 and not mq.changed)
assert(ns.SimMath.Talent("MD").points == 2, "Mental Dexterity 2/3 read from talents")
local p0 = ns.Profile.Player()
local q0 = ns.SimMath.Apply(p0, { int = 100 }, { mentalQuick = 1 })
print("+100 Int with 1 point: SP", p0.sp.Nature, "->", q0.sp.Nature, "healing", p0.healing, "->", q0.healing)
assert(math.abs(q0.sp.Nature - p0.sp.Nature - 15) < 1e-9 and math.abs(q0.healing - p0.healing - 15) < 1e-9)
-- Mental Dexterity: 150% split over 3 points (rule) -> 2 points = 1.0 AP per Int
local q1 = ns.SimMath.Apply(p0, { int = 10 }, { mentalDex = 2 })
assert(math.abs(q1.ap - p0.ap - 10) < 1e-9, "2 points of MD: 10 Int = 10 AP")
-- Test another build with the slider, then go back to real
ns.UI.Update()
sim.talents.MQ:Set(2, true)  -- (the fake slider has no memory, so set it directly)
assert(ns.SimMath.Talent("MQ").points == 2 and ns.SimMath.Talent("MQ").changed)
assert(sim.talents.MQ.value._text:find("2/5"), "shows 2/5")
sim.talents.MD.check:SetChecked(false); sim.talents.MD.check._scripts.OnClick(sim.talents.MD.check)
assert(ns.SimMath.Talent("MD").points == 0)
sim.talentReset._scripts.OnClick()
assert(ns.SimMath.Talent("MQ").points == 1 and ns.SimMath.Talent("MD").points == 2, "Real = back to your talents")
dumpSim("talents read from the game")
print("mental quickness tests passed")

-- Tooltip method (Forever tooltips go up with spell power) ----------------------
FAKE_SP = 64
ns.SpellData.Rebuild()
SlashCmdList.THEEARTHENSHRINK("test")
local lbT = pick("Lightning Bolt")
CT.Clear(lbT, "before"); CT.Clear(lbT, "after")
ns.db().coefSaved.LB = nil
ct.before._scripts.OnClick()
ct.readTip._scripts.OnClick()
print("read msg:", ct.msg._text)
local oldDesc = SPELLS[943].desc
SPELLS[943].desc = "Casts a bolt of lightning at the target for 1,148 to 1,166 Nature damage."
FAKE_SP = 88
ct.after._scripts.OnClick()
ct.readTip._scripts.OnClick()
dumpCoef("tooltip method, +24 SP, both ends +17")
local tr = CT.TooltipResult(lbT)
print("tooltip coef", tr.coef, "±", tr.margin, tr.verdict)
assert(math.abs(tr.coef - 17/24) < 1e-9 and tr.verdict == "good")
ct.save._scripts.OnClick()
assert(ns.db().coefSaved.LB[lbT.rank.rank].direct.method == "tooltip")
-- No double counting: at the spell power the tooltip was read with, the math
-- gives the tooltip's own average.
ns.db().tooltipIncludesSpellPower = true
ns.SpellData.Rebuild()
local rk = ns.SpellData.Best("LB", 30)
local cc = ns.SpellMath.Calc(ns.RANKS_BY_KEY.LB, rk, ns.Profile.Player())
print("spRead", rk.spRead, "direct", cc.direct, "tooltip avg", (1148 + 1166) / 2)
assert(math.abs(cc.direct - 1157) < 1e-9)
SPELLS[943].desc = oldDesc
-- Built-in Lightning Bolt rank 6 result from Angel's tooltip
local seed = CT.Saved("LB", 6).direct
print("seed LB 6:", seed.coef, seed.totalMargin, seed.note)
assert(seed.seed and math.abs(seed.coef - 0.7083) < 0.001)
print("tooltip method tests passed")

-- Flametongue Totem stacking, Stormstrike, game change check ---------------------
SPELLS[8227] = { name="Flametongue Totem", rank=1, mana=50, cast=0, desc="Summons a Flametongue Totem. Party members' weapons deal 6 to 22 additional Fire damage per hit, based on the speed of the weapon. Lasts 2 min.", lvl=28 }
SPELLS[77001].desc = "Instantly strike an enemy with both weapons for 150% weapon damage. Your next Lightning Bolt, Chain Lightning or Earth Shock deals 20% more damage."
local oldTip = C_TooltipInfo.GetSpellByID
C_TooltipInfo.GetSpellByID = function(id)
  local d = oldTip(id)
  if d and id == 77001 then table.insert(d.lines, { leftText = "Instant", rightText = "6 sec cooldown" }) end
  return d
end
FAKE_SP = 64
ns.SpellData.Rebuild()
local function ftDps()
  local out = {}
  for _, e in ipairs(ns.ImbueMath.Compare(ns.Profile.Player())) do out[e.key] = e.calc and e.calc.dps end
  return out
end
local off = ftDps()
SlashCmdList.THEEARTHENSHRINK("fttotem on")
local stack = ftDps()
SlashCmdList.THEEARTHENSHRINK("ftstack off")
local nostack = ftDps()
print("FT weapon gain: totem off", off.FT, "totem stacks", stack.FT, "totem doesn't stack", nostack.FT)
assert(math.abs(stack.FT - off.FT) < 1e-6, "stacking: the weapon adds the same on top")
assert(nostack.FT < stack.FT, "not stacking: the weapon only replaces the totem")
local fttT = ns.ImbueMath.FtTotem(ns.Profile.Player())
print("FT totem per hit", fttT.perHit, "searing dps", ns.TotemMath.SearingDps(ns.Profile.Player()))
SlashCmdList.THEEARTHENSHRINK("fttotem off"); SlashCmdList.THEEARTHENSHRINK("ftstack on")
local ss = ns.SpellData.Best("SS", 30)
print("Stormstrike", ss.strikePct, ss.cooldown)
assert(ss.strikePct == 1.5 and ss.cooldown == 6)
print("Mental Dexterity ratio", ns.SimMath.MentalDexRatio())
-- game change check: first run saves, a hotfix changes Stormstrike, next login reports it
ns.db().gameSnapshot = nil
assert(#ns.GameCheck.Check(true) == 0)
SPELLS[77001].desc = "Instantly strike an enemy with both weapons for 100% weapon damage. Your next Lightning Bolt, Chain Lightning or Earth Shock deals 20% more damage."
ns.SpellData.Rebuild()
local ch = ns.GameCheck.Check(true)
assert(#ch == 1 and ch[1].label == "Stormstrike rank 1 tooltip")
assert(#ns.GameCheck.Check(true) == 0, "reported once")
SlashCmdList.THEEARTHENSHRINK("changes")
print("hotfix check tests passed")

-- Minimap button: click toggles the window, drag saves the angle, hide/show
local mb = TheEarthenShrinkMinimapButton
assert(mb, "minimap button made")
local win = TheEarthenShrinkFrame
win:Hide()
mb._scripts.OnClick(mb, "LeftButton"); assert(win:IsShown(), "left-click opens")
mb._scripts.OnClick(mb, "LeftButton"); assert(not win:IsShown(), "left-click closes")
mb._scripts.OnDragStart(mb); mb._scripts.OnUpdate(mb); mb._scripts.OnDragStop(mb)
assert(math.abs(ns.db().minimap.angle - 90) < 0.01, "dragged to top = 90 degrees")
mb._scripts.OnClick(mb, "RightButton"); assert(TheEarthenShrinkMinimapMenu:IsShown(), "right-click menu")
ns.db().minimap.lock = true; MOUSE = { 900, 700 }
mb._scripts.OnDragStart(mb); assert(mb._scripts.OnUpdate == nil or ns.db().minimap.angle == 90, "locked")
SlashCmdList.THEEARTHENSHRINK("minimap"); assert(not mb:IsShown() and ns.db().minimap.hide)
SlashCmdList.THEEARTHENSHRINK("minimap"); assert(mb:IsShown() and not ns.db().minimap.hide)
SlashCmdList.THEEARTHENSHRINK("minimap reset"); assert(ns.db().minimap.angle == 200 and not ns.db().minimap.lock)
TheEarthenShrink_OnCompartmentClick("TheEarthenShrink", "LeftButton"); assert(win:IsShown(), "compartment opens")
print("minimap button tests passed")
