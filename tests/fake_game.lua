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
function print(...) io.write(table.concat({...}, " "), "\n") end
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
  [8232]= { name="Windfury Weapon", rank=1, mana=95, cast=0, desc="Imbue the Shaman's weapon with wind. Each hit has a 20% chance of dealing additional damage equal to two extra attacks with 104 extra attack power.", lvl=30 },
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
