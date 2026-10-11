# The Earthen Shrink: Research Notes (Step 1)

First written: October 9, 2026. **Re-checked: October 10, 2026**, after Angel asked that every fact be verified for **WoW Forever** specifically.

The game is in **beta**, so numbers change often.

## How to read this document

**Rule we follow:** only information about **World of Warcraft: Forever** counts as a fact. Classic, TBC or retail information is never listed as a fact. If we must borrow an old Classic rule to make the math work, it is tagged 🔶 and will be tested in game before the addon relies on it.

| Tag | Meaning |
|-----|---------|
| ✅ **Blizzard** | Blizzard said it about Forever (official posts or BlizzCon panel). |
| ☑️ **2 sources** | Two separate Forever guide sites agree. Likely right, but not from Blizzard. |
| 🟡 **1 source** | Only one Forever guide site says it. Needs a tooltip check by Angel. |
| 🔶 **Classic rule** | NOT verified for Forever. Old Classic value, used only as a placeholder in the math until we test it. |
| ❓ **Unknown** | Nobody has published this. We will measure it in game. |
| 🧪 **Angel to check** | Angel can confirm this from a tooltip or screenshot in the beta. See [Section 8](#8-screenshot-checklist-for-angel). |

Words in **bold** the first time are explained in the [Glossary](#glossary) at the bottom.

### What changed in the October 10 re-check

- **Haste removed as a gear stat.** Angel was right. Two Forever guides say no gear in the beta has haste ([Warcraft Tavern stats guide](https://www.warcrafttavern.com/forever/guides/stats/), [WoW Forever Builds](https://wowforeverbuilds.com/news/wow-forevers-character-panel-now-explains-your-stats-and-missed-loot-turns-up-in)). Haste only comes from a few effects, like the Troll racial Berserking and the Skyborne racial Wind Blessed.
- **Removed a stat priority list that included haste.**
- **Fixed talent numbers** that were written wrong: Maelstrom Weapon, Mental Dexterity, Mental Quickness, Lightning Overload, Mindfulness (now checked against a second Forever source).
- **Stopped using sources that weren't specific to Forever.** One expertise article mostly described TBC and WotLK numbers, so it's gone.
- **Every number now has a trust tag.** Numbers from only one site are marked 🟡 and added to Angel's screenshot checklist.

---

## 1. What is WoW Forever?

- ✅ A new, third version of WoW in the Battle.net app, next to "Modern" (retail) and "Classic". The beta installs as **"World of Warcraft: Forever Beta"**.
- ✅ The gameplay is based on **Vanilla** (the original 2004 game), with class redesigns. Shamans have no Bloodlust or Hex.
- ☑️ Dwarves can be Shamans, so both factions have them.
- ☑️ The beta level cap started at 20, then went to 30.
- ✅ Talents use Classic-style trees, with special "gold medal" talents at 11, 16, 21 and 31 points. Dual Specialization unlocks at level 40.

**Big surprise for addon makers:** the game *plays* like Classic, but the *addon code* works like modern retail WoW. See Section 6.

---

## 2. Stats

### What Forever changed

- ✅ **Hit chance** is one stat for everything (melee, spells, ranged). Classic had separate ones. (Blizzard at BlizzCon, reported by [OutputLag](https://outputlag.com/news/world-of-warcraft-forever-unifies-hit-and-crit-stats-and-gives-healing-gear-bonus-damage/).)
- ✅ **Crit chance** is also one stat for everything.
- ✅ Every healing item also gives some spell damage.
- ✅ Caster weapons give spell damage from level 10 onward.
- ✅ **Weapon skill** still exists, but one item gives less of it.
- ✅ A new effect lowers the enemy's chance to dodge or parry your melee hits (seen on Edgemaster's Handguards as "1%"). Blizzard has **not** confirmed the name "Expertise".
- ☑️ **Haste is not a gear stat** in the beta. It only comes from effects like Berserking (Troll) and Wind Blessed (Skyborne). 🧪
- ☑️ The character panel shows one combined Crit Chance, and hovering a stat explains what it does for your class. 🧪 *This tooltip is the best way to verify stat conversions.*

### Stat conversions

Only one Forever guide ([Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/stats/)) lists these, and it does not say they were tested in Forever. Some look copied from Classic. **All need checking from the character panel tooltips.** 🧪

| Stat | What 1 point gives a Shaman | Trust |
|------|-------------------|-------|
| Intellect | 15 max mana | ☑️ (Icy Veins and Warcraft Tavern agree) |
| Intellect | Spell crit: about 1% per 54 to 60 Intellect | 🟡 🧪 |
| Agility | Melee crit: 1% per 20 Agility | 🟡 🧪 |
| Strength | 2 attack power | 🟡 🧪 |
| Stamina | 10 health | 🟡 🧪 |
| Attack power | 14 attack power = +1 DPS | 🟡 🧪 |
| Spirit | Mana regen while not casting. No number published. | ❓ 🧪 |

**Good news:** the addon doesn't need most of these formulas. The game tells the addon your *final* totals (crit %, spell power, attack power) directly. We only need the formulas for "what if I had 10 more Intellect?" questions.

### Stat priority

These are guide opinions, and they disagree. Haste is left out because it isn't on gear.

| Spec | Priority (best first) | Source |
|------|------------------------|--------|
| Elemental | Spell Power > Crit > Hit > Intellect > MP5 > Spirit > Stamina | 🟡 [Icy Veins](https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-guide) |
| Enhancement | Weapon Damage > Hit and dodge/parry reduction > Crit > Strength > Intellect > Agility > Spell Power | 🟡 [wow.gg](https://wow.gg/guides/wow-forever-enhancement-shaman-beta) (their own words: "largely guesswork") |
| Restoration | Healing > Crit > Intellect > Spirit > MP5 > Stamina | 🟡 [Icy Veins](https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-guide) |

This is why the addon should calculate stat priority from **your** gear instead of copying a list.

---

## 3. The three specs

Talent descriptions are from Blizzard's [Mage and Shaman deep dive](https://worldofwarcraft.blizzard.com/en-us/news/24302097) (✅). Blizzard mostly didn't give percentages, so the numbers come from guide sites and carry their own tags.

### Elemental (casting damage)

- ✅ **Lightning Bolt** (rank 4 and up): 2.5 second cast (was 3.0). Its spell power bonus was lowered to match.
- ✅ **Chain Lightning**: 2.0 second cast (was 2.5). Spell power bonus lowered to match.
- ✅ **Lava Burst** (31-point talent): 2.5 second cast, 10 second cooldown, 20% more damage if your Flame Shock is on the target.
- ✅ **Fire Nova** is a spell now, not a totem. It explodes around your current Fire Totem.
- ✅ **Lightning Overload**: chance for Lightning Bolt or Chain Lightning to cast a free copy at half damage. ☑️ 3% / 6% / 10% chance at ranks 1 / 2 / 3.
- ✅ **Call of Thunder** (16-point talent): +3% crit for Lightning Bolt and Chain Lightning.
- ✅ **Elemental Alacrity**: up to 0.5 seconds faster Lightning Bolt and Chain Lightning at max rank (3 points).
- ✅ **Elemental Fury** moved to row 6. 🟡 Crit damage bonus: +20%. 🧪
- ✅ **Convection** also reduces Lava Burst's cost. 🟡 2% per point. 🧪
- ✅ **Elemental Focus**: lower chance when you cast low ranks. 🟡 10% chance for a free spell. 🧪
- ✅ **Elemental Mastery** was removed.

🟡 Rotation from Icy Veins: totems down, pull with Lightning Bolt, Fire Nova on 3+ enemies, Flame Shock, then Lightning Bolt.

### Enhancement (melee and spells mixed)

- ✅ **Stormstrike** (16-point talent): 8 second cooldown. Your next Lightning Bolt, Chain Lightning, or Earth Shock does 20% more damage.
- ✅ **Maelstrom Weapon**: melee hits can give stacks that make Lightning Bolt faster. With enough ranks and stacks, it becomes instant. ☑️ Up to 5 stacks. Each stack lowers cast time and mana cost by 4% per talent rank (so 20% per stack at rank 5, and 5 stacks = instant). 🧪
- ✅ **Mental Dexterity**: attack power from Intellect. 🟡 33% / 66% / 100% of your Intellect at ranks 1 / 2 / 3. 🧪
- ✅ **Mental Quickness**: spell power from Intellect. 🟡 15% / 30% of your Intellect at ranks 1 / 2. 🧪
- ✅ **Shamanistic Focus** (11-point talent): Shocks and Lightning Shield cost much less. ☑️ 45% less.
- ✅ **Flurry**: up to 25% faster attacks (was 30%).
- ✅ **Rage of the Farseer** (31-point talent): 30% faster attacks for 25 seconds, 3 minute cooldown.
- ✅ Two-handed axes and maces work without a talent.

Intellect turning into attack power AND spell power AND mana is a big reason Enhancement in Forever is different from Classic.

### Restoration (healing)

- ✅ **Riptide** (31-point talent): instant heal plus a heal over 15 seconds, 6 second cooldown. Chain Heal is 25% stronger on that target.
- ✅ **Water Shield** (11-point talent): 3 globes that give mana when you're hit or your heals crit. ☑️ Each globe gives 2% of max mana. Lasts 10 minutes.
- ✅ **Mana Tide Totem** is now the 16-point talent.
- ✅ **Mindfulness**: some mana regen keeps going while casting. ☑️ 17% / 33% / 50% at ranks 1 / 2 / 3.
- ✅ **Healing Way**: more Healing Wave healing. 🟡 8% per point. 🧪

---

## 4. Weapon buffs (imbues)

✅ From Blizzard:
- All four imbues last **60 minutes** (was 5).
- They stack with sharpening stones, weightstones and wizard oils.
- Windfury and Flametongue are **also party totems** now. If the buff is already on your weapon, the matching totem does nothing for you.
- Windfury Totem and Flametongue Totem can't both be on a party. Windfury Totem also can't be up with Grace of Air.

So the best setup is usually to "cross" them, for example Flametongue on your weapon and Windfury Totem for the party.

**Imbue numbers.** Only one site lists these ([ForeverChanges](https://foreverchanges.pro/class/shaman)), and it doesn't show where it got them. **Treat all as 🟡 until Angel sends the tooltips.** 🧪

| Imbue | Rank 1 | Highest rank listed |
|-------|--------|---------------------|
| Rockbiter | +50 attack power | ❓ |
| Flametongue | 4.71 to 18 fire damage per hit | Rank 6: 35 to 112 |
| Frostbrand | 45 frost damage per hit, plus slow | Rank 5: 169 |
| Windfury | 20% chance for 2 extra attacks with +104 attack power | ❓ (a forum player quotes +466 at top rank) |

🟡 Guide advice (wow.gg): Rockbiter for solo, Flametongue in groups.

❓ How Flametongue scales with weapon speed in Forever is unknown. We'll measure it.

---

## 5. Totems

✅ From Blizzard:
- Totems use a 1.0 second global cooldown (was 1.5).
- Buff totems last 5 minutes (was 2).
- **Call of the Elements** (level 20) drops a saved set of 4 totems with one 3 second cast. **Call of the Spirits** (30) and **Call of the Ancestors** (40) add more sets. Cost = the 4 totems added together.
- **Totemic Recall** (level 20) removes totems and refunds 25% of their mana. Known beta bug: the refund doesn't work yet.
- **Totemic Projection** (level 22) moves totems up to 30 yards. 1 minute cooldown, costs 25% of base mana.
- Resistance totems now help the whole raid group.
- Tranquil Air Totem was removed.

| Element | Totems | Unlocks at | Trust |
|---------|--------|-----------|-------|
| Earth | Stoneskin, Earthbind, Stoneclaw, Strength of Earth, Tremor | Level 4 | ☑️ |
| Fire | Searing, Magma, Flametongue, Frost Resistance | Level 10 | ☑️ |
| Water | Healing Stream, Mana Spring, Poison Cleansing, Disease Cleansing, Fire Resistance, Mana Tide (talent) | Level 20 (quest) | ☑️ |
| Air | Grounding, Windfury, Grace of Air, Nature Resistance, Windwall, Sentry | Level 30 (quest) | ☑️ |

🟡 Totem strength numbers (Strength of Earth, Windfury Totem, Grace of Air, Mana Tide) come from one site only, so they're on the screenshot checklist instead of here.

---

## 6. Addon code: what the game lets us do

### Version number

- ☑️ The **interface number** is **16001**. Our **TOC file** must say `## Interface: 16001`. (From [WoW Forever Guides](https://wowforeverguides.com/addons/developers) and the [forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit) tester repo.) 🧪 You can confirm it in game by typing `/dump select(4, GetBuildInfo())`.
- 🟡 Addons go in `World of Warcraft\_classic_beta_\Interface\AddOns\`. 🧪 Check where the Forever Beta folder is on your PC.

### It uses the modern (retail) addon system

- ✅ Blizzard said at its September 17 Q&A that Forever uses the same addon system as retail (reported by [PewPewShop](https://pewpewshop.pro/wow-boost/blog~wow-forever-addons-modern-client-api-built-in-damage-meter)).
- ☑️ Old Classic functions like `GetSpellInfo`, `GetItemInfo`, `GetTalentInfo` and `UnitAura` are **gone**. We use `C_Spell`, `C_Item`, `C_UnitAuras` instead.
- ☑️ Talents are read with `C_Traits` and `C_ClassTalents`.

So tutorials for **Classic** addons will often be wrong. **Retail** tutorials are closer.

### Functions that exist in the Forever beta

A tester saved the full list of functions in the Forever beta ([forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit), file `data/forever_api.json`). I checked our list against that file. **"Exists" doesn't mean "works"**, so the starter addon will test each one.

| What we want | Function |
|--------------|----------|
| Strength, Agility, Stamina, Intellect, Spirit | `UnitStat("player", 1..5)` |
| Spell damage | `GetSpellBonusDamage(school)` |
| Healing | `GetSpellBonusHealing()` |
| Crit chance | `GetCritChance()`, `GetSpellCritChance(school)` |
| Hit chance | `GetHitModifier()`, `GetSpellHitModifier()` |
| Dodge/parry reduction | `GetExpertise()` (❓ may not be what Forever uses) |
| Attack power | `UnitAttackPower("player")` |
| Weapon damage and speed | `UnitDamage("player")`, `UnitAttackSpeed("player")` |
| Mana | `UnitPower("player", 0)`, `UnitPowerMax("player", 0)` |
| Mana regen | `GetManaRegen()` |
| Weapon buff | `GetWeaponEnchantInfo()` |
| Totems | `GetTotemInfo(slot)` |
| Gear | `GetInventoryItemLink("player", slot)` |
| Spell cost | `C_Spell.GetSpellPowerCost(spellID)` |
| Talents | `C_ClassTalents.GetActiveConfigID()`, `C_Traits.GetTreeNodes(...)`, `C_Traits.GetNodeInfo(...)` |

(`GetHaste()` also exists in the code, but haste isn't on gear, so we'll only use it to notice Berserking or Wind Blessed.)

### Restrictions

- ☑️ **No combat log for addons.** The addon can't record your fights, so DPS has to be **calculated from your stats**.
- ☑️ **Secret values in combat.** Some numbers can't be used for math during combat. The function list includes `C_Secrets.ShouldUnitStatsBeSecret`. **Plan:** do all math out of combat.
- ✅ The game has a **built-in damage meter**. ☑️ A `C_DamageMeter` namespace exists. Later we might compare our predicted DPS with your real DPS.
- 🟡 Beta bugs from one tester: saved settings didn't load back (maybe fixed in build 70009), and `ReloadUI()` can't be called from code (type `/reload`).

---

## 7. How we will do the math (plan for Step 3)

Because the addon can't record fights, it will **calculate**. The formulas below are **🔶 Classic rules**. They are our starting guess, and the addon will test them against your real tooltips before trusting them.

```
expected damage = (base damage + spell power × coefficient) × chance to hit × (1 + crit chance × crit bonus)
damage per mana = expected damage ÷ mana cost
total damage    = (max mana + mana regained) × damage per mana
DPS             = expected damage ÷ cast time
```

How we'll check the 🔶 parts in game:
- **Coefficient**: the tooltip for Lightning Bolt shows its damage *including* your spell power. Compare the tooltip with and without a spell power item and we can calculate the real coefficient. 🧪
- **Chance to hit**: ❓ Forever's base miss chance isn't published. We'll show your hit % from the game instead of guessing.
- **Crit bonus**: ❓ We'll find out from your crit numbers on target dummies.

### Stat priority from your gear

The addon pretends you have +10 of one stat, re-runs the math, and sees how much DPS goes up. Sorting those gains gives **your** personal stat priority (called "stat weights").

### Where the base numbers come from

- Mana costs: read from the game with `C_Spell.GetSpellPowerCost`. No guessing needed.
- Spell base damage and coefficients: not readable by code. We'll keep a data table in the addon and fill it from **your tooltip screenshots**, not from websites.

---

## 8. Screenshot checklist for Angel

**Update, October 11:** screenshots are no longer needed. The helper addon in `tools/EarthenShrinkExport` saves all of these tooltips to one file. See [angel-checklist.md](angel-checklist.md). The list below is kept as a record of what we need it to capture.

**Most important (for the Weapon Buff tool):**
1. The tooltip for every **weapon imbue** rank you have: Rockbiter, Flametongue, Frostbrand, Windfury (from the spellbook or trainer).
2. **Windfury Totem** and **Flametongue Totem** tooltips.

**Stats:**
3. Your **character panel**, with the tooltip open on: Intellect, Agility, Strength, Spirit, Crit Chance, Hit Chance, Spell Power, Attack Power. (This confirms the conversions in Section 2.)
4. Any item that has a "dodge or parry" reduction effect, if you find one.

**Spells:**
5. **Lightning Bolt** (your highest rank), **Chain Lightning**, **Earth Shock**, **Flame Shock**, **Healing Wave**, **Lesser Healing Wave**, **Chain Heal**.
6. The same Lightning Bolt tooltip again **with a spell power item taken off**. The difference lets us calculate the real coefficient.

**Talents (any you can see, even if not learned):**
7. Elemental: Elemental Fury, Convection, Elemental Focus, Lightning Overload.
8. Enhancement: Maelstrom Weapon, Mental Dexterity, Mental Quickness, Flurry, Elemental Weapons.
9. Restoration: Healing Way, Mindfulness, Water Shield.

**Addon info:**
10. Type `/dump select(4, GetBuildInfo())` in chat and send what it says. This is the interface number.

---

## 9. Recommended addon structure

A proposal for Step 2. Nothing is built yet.

```
TheEarthenShrink/
  TheEarthenShrink.toc     -- tells WoW about the addon (name, interface 16001, file list)
  Core.lua                 -- starts the addon, listens for game events
  Data/Spells.lua          -- spell numbers (filled from Angel's tooltips)
  Data/Imbues.lua          -- weapon buff numbers
  Player/Stats.lua         -- reads your stats, gear, talents
  Math/Damage.lua          -- the formulas from Section 7
  UI/MainWindow.lua        -- the window with tabs
  UI/Tabs/*.lua            -- Overview, Weapon Buffs, Stat Priority, Mana & DPS, Tips
```

The first version will also have a **"Check"** button that prints which game functions work, so we verify Section 6 in your beta client.

---

## 10. Lua for a C# person (quick primer)

| C# | Lua |
|----|-----|
| `int x = 5;` | `local x = 5` |
| `if (x > 3) { ... }` | `if x > 3 then ... end` |
| `x != 3` | `x ~= 3` |
| `for (int i = 1; i <= 5; i++)` | `for i = 1, 5 do ... end` |
| `"a" + "b"` | `"a" .. "b"` |
| `null` | `nil` |
| `&&`, `\|\|`, `!` | `and`, `or`, `not` |
| `// comment` | `-- comment` |
| `List` / `Dictionary` | Both are a **table**: `{1, 2, 3}` or `{ name = "Bolt", cost = 220 }` |
| `list[0]` is the first item | `list[1]` is the first item (Lua counts from **1**) |
| `void Foo(int a) { }` | `local function Foo(a) ... end` |

---

## Glossary

- **Addon**: a small program, written in Lua, that changes or adds to the WoW screen.
- **API**: the list of functions the game gives addons to ask questions ("what is my mana?").
- **Coefficient**: how much of your spell power gets added to a spell. 0.7 means 70%.
- **Combat log**: a stream of every hit, heal and buff in a fight. Forever hides it from addons.
- **Crit**: a critical hit, which does extra damage.
- **Haste**: makes you cast or attack faster. In Forever it only comes from a few effects, not gear.
- **Imbue**: a Shaman weapon buff (Windfury, Flametongue, Frostbrand, Rockbiter).
- **Interface number**: the version number in the TOC file that tells WoW which game version the addon is for.
- **MP5**: mana per 5 seconds.
- **Rank**: older spells have levels (Rank 1, Rank 2...). Higher ranks hit harder but cost more.
- **SavedVariables**: how an addon remembers settings between game sessions.
- **Secret value**: a number the game lets an addon *show* but not *calculate with* during combat.
- **Stat weight**: how much DPS one point of a stat is worth to *you*.
- **TOC file**: the addon's "table of contents" file. WoW reads it first.
- **Vanilla**: the original 2004 version of WoW.

---

## Sources

All of these are about WoW Forever. Blizzard sources come first.

- ✅ Blizzard: [Forever Class Deep Dives: Mage and Shaman](https://worldofwarcraft.blizzard.com/en-us/news/24302097)
- [OutputLag: BlizzCon panel on hit and crit](https://outputlag.com/news/world-of-warcraft-forever-unifies-hit-and-crit-stats-and-gives-healing-gear-bonus-damage/)
- [PewPewShop: Forever uses the modern addon API](https://pewpewshop.pro/wow-boost/blog~wow-forever-addons-modern-client-api-built-in-damage-meter)
- [Warcraft Tavern: Forever Stats guide](https://www.warcrafttavern.com/forever/guides/stats/) and [Shaman guide](https://www.warcrafttavern.com/forever/guides/shaman/)
- [WoW Forever Builds: character panel and haste](https://wowforeverbuilds.com/news/wow-forevers-character-panel-now-explains-your-stats-and-missed-loot-turns-up-in)
- [Icy Veins: Elemental](https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-guide), [Restoration](https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-guide)
- [wow.gg: Enhancement (Beta)](https://wow.gg/guides/wow-forever-enhancement-shaman-beta)
- [Mobalytics: Forever Shaman overview](https://mobalytics.gg/wow-forever/guides/shaman-class-overview) (talent rank numbers)
- [ForeverChanges: Shaman changes](https://foreverchanges.pro/class/shaman) (imbue and spell numbers, one source only)
- [WoW Forever Guides: addon development](https://wowforeverguides.com/addons/developers)
- [forever-addon-kit (GitHub)](https://github.com/Thunderz96/forever-addon-kit): list of functions in the beta client
- [Blizzard forums: Flametongue vs Windfury feedback](https://us.forums.blizzard.com/en/wow/t/forever-is-forcing-enhancement-onto-flametongue-that-is-not-the-class/2375734) (player posts)
