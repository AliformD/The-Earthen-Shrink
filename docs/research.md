# The Earthen Shrink: Research Notes (Step 1)

Research date: **October 9, 2026**. The game is in **beta**, so numbers change often.

## How to read this document

Every fact has a tag so you know how much to trust it:

| Tag | Meaning |
|-----|---------|
| ✅ **Official** | Blizzard said it (patch notes, official posts). |
| 🟡 **Community** | Guide sites or testers report it, but Blizzard has not confirmed it. |
| 🔶 **Classic guess** | Not known for Forever yet. We borrow the old Classic (Vanilla) value as a starting point. |
| ❓ **Unknown** | Nobody has published this yet. We will measure it in game. |

Words in **bold** the first time are explained in the [Glossary](#glossary) at the bottom.

---

## 1. What is WoW Forever?

- ✅ A new, third version of WoW in the Battle.net app, next to "Modern" (retail) and "Classic". The beta installs as **"World of Warcraft: Forever Beta"**.
- ✅ The gameplay is based on **Vanilla** (the original 2004 game), with many class redesigns. So Shamans have no Bloodlust or Hex.
- ✅ Dwarves can now be Shamans, so both factions (Alliance and Horde) have them.
- 🟡 The beta level cap started at 20, then went to 30. The full game goes to 60.
- ✅ Talents work like old Classic trees, with new "gold medal" talents at 11, 16, 21 and 31 points. Dual Specialization (two saved talent setups) unlocks at level 40.

**Big surprise for addon makers:** the game *plays* like Classic, but the *addon code* works like modern retail WoW. This changes how we build everything (see Section 6).

---

## 2. Stats: what they do

Forever changed how stats work compared to Classic:

- ✅ **Hit chance** is now one stat for everything (melee, spells, totems). Classic had separate melee hit and spell hit.
- ✅ **Crit chance** is also one stat for everything.
- ✅ Every healing item also gives some spell damage (for example "up to 42 healing and 14 damage").
- ✅ Caster weapons give spell damage from level 10 onward.
- ✅ A new stat lowers the enemy's chance to dodge or parry your melee hits. Guides call it **Expertise**, but Blizzard has not confirmed the name. 🟡
- 🟡 **Haste** (casting and attacking faster) is a new stat. How much haste you get per point is ❓.
- ✅ **Weapon skill** still exists, but items give less of it.
- 🟡 Spell power now comes mainly from gear, instead of from higher spell ranks.

### Stat values per point

| Stat | What 1 point gives | Trust |
|------|-------------------|-------|
| Intellect | 15 mana, plus a little spell crit | 🟡 (Icy Veins) |
| Stamina | 10 health | 🔶 |
| Strength | 2 attack power (Shaman) | 🔶 |
| Agility | A little melee crit (about 1% per 20 Agility at level 60) | 🔶 |
| Spirit | Mana regen when you have not cast for 5 seconds | 🔶 |
| MP5 | Mana every 5 seconds, always, even while casting | 🔶 |
| Intellect to crit | About 1% spell crit per 59.5 Intellect at level 60 | 🔶 |

**Good news:** we don't have to know all of these formulas. The game can tell the addon the *final* numbers directly (your total crit %, total spell power, total attack power, and so on). See Section 6. We only need formulas for "what if" questions, like "what if I had 10 more Intellect?"

### Stat priority (what to collect first)

These are what guide sites say right now. All are 🟡 and change as people test.

| Spec | Priority (best first) | Source |
|------|------------------------|--------|
| Elemental | Spell Power > Crit > Hit > Intellect > MP5 > Spirit > Stamina | Icy Veins |
| Elemental (other view) | Spell Power > Hit > Haste > Intellect > Crit | Warcraft Tavern |
| Enhancement | Weapon Damage > Hit/Expertise > Crit > Strength > Intellect > Agility > Spell Power | wow.gg ("largely guesswork") |
| Restoration | Healing Power > Crit > Intellect > Spirit > MP5 > Stamina | Icy Veins |

The guides disagree. That is exactly why our addon should calculate stat priority from **your** gear instead of using a fixed list.

---

## 3. The three specs

### Elemental (casting damage)

- ✅ **Lightning Bolt** (rank 4 and up): cast time is 2.5 seconds (was 3.0). Its spell power bonus was lowered to match.
- ✅ **Chain Lightning**: cast time is 2.0 seconds (was 2.5).
- ✅ **Lava Burst** (31-point talent): 2.5 second cast, 10 second cooldown, 20% more damage if your Flame Shock is on the target.
- ✅ **Fire Nova** is now a spell (not a totem). It explodes around your current Fire Totem. 🟡 10 second cooldown.
- ✅ **Lightning Overload**: chance for Lightning Bolt or Chain Lightning to fire a free second copy at half damage. 🟡 3% chance per point.
- ✅ **Call of Thunder** (16-point talent): +3% crit for Lightning Bolt and Chain Lightning.
- 🟡 **Elemental Fury**: +20% crit damage (Classic was +100%).
- 🟡 **Elemental Focus**: 10% chance that your next damage spell costs no mana (called Clearcasting).
- 🟡 **Convection**: 2% less mana per point, now also for Lava Burst.
- ✅ **Elemental Mastery** was removed.

🟡 Basic rotation (Icy Veins): put totems down, pull with Lightning Bolt, Fire Nova on 3+ enemies, Flame Shock, then Lightning Bolt until the target dies. With Lava Burst: Flame Shock first, then Lava Burst.

### Enhancement (melee and spells mixed)

- ✅ **Stormstrike** (16-point talent): 8 second cooldown (was 20). Your next Lightning Bolt, Chain Lightning, or Earth Shock does 20% more damage.
- ✅ **Maelstrom Weapon**: melee hits build stacks that make Lightning Bolt faster. 🟡 Up to 5 stacks, each one is 4% faster and 4% cheaper.
- ✅ **Mental Dexterity**: gives attack power from Intellect. 🟡 33% of your Intellect.
- ✅ **Mental Quickness**: gives spell damage from Intellect. 🟡 Up to 15% of your Intellect.
- ✅ **Shamanistic Focus** (11-point talent): Shocks and Lightning Shield cost much less mana. 🟡 45% less.
- ✅ **Flurry**: up to 25% faster attacks after a crit (was 30%).
- ✅ **Rage of the Farseer** (31-point talent): 30% faster attacks for 25 seconds, 3 minute cooldown.
- ✅ Two-handed axes and maces are now available without a talent.

**Important:** because Intellect turns into attack power AND spell damage AND mana, Intellect is much more valuable for Enhancement than in Classic.

### Restoration (healing)

- ✅ **Riptide** (31-point talent): instant heal plus a heal over 15 seconds. 6 second cooldown. Makes Chain Heal 25% stronger on that target.
- ✅ **Water Shield** (11-point talent): 3 globes that give mana when you are hit or when your heals crit. 🟡 Each globe gives 2% of your max mana.
- ✅ **Mana Tide Totem** moved to the 16-point talent.
- ✅ **Mindfulness**: some mana regen keeps going while you cast. 🟡 17% per point.
- ✅ **Healing Way**: more Healing Wave healing. 🟡 8% per point.

---

## 4. Weapon buffs (imbues)

✅ All imbues now last **60 minutes** (was 5) and can stack with sharpening stones and wizard oils.

✅ **Big change:** Windfury and Flametongue are now *also* party totems. But:
- If you have Windfury **Weapon** on, you get nothing from Windfury **Totem**. Same for Flametongue.
- Windfury Totem and Flametongue Totem can't both be active on a party.
- Windfury Totem can't be up with Grace of Air Totem.

So the smart setup is to "cross" them, for example Flametongue on your weapon and Windfury Totem for the party. Our weapon buff tool needs to know this rule.

| Imbue | Rank 1 effect | Highest rank effect | Trust |
|-------|---------------|---------------------|-------|
| Rockbiter | +50 attack power | ❓ | 🟡 |
| Flametongue | 4.71 to 18 fire damage per hit | Rank 6: 35 to 112 | 🟡 |
| Frostbrand | 45 frost damage per hit, plus slow | Rank 5: 169 | 🟡 |
| Windfury | 20% chance for 2 extra attacks with +104 attack power | 🟡 trainer text: +466 at top rank | 🟡 |

🟡 Guide advice: Rockbiter for solo play (it boosts threat with the Spirit Weapons talent), Flametongue in groups.

❓ Flametongue's exact formula (how it scales with weapon speed) is not published. In Classic it scaled with weapon speed (slower weapon = bigger hits). We will measure it.

---

## 5. Totems

✅ Totem changes:
- Totems use a 1.0 second global cooldown (was 1.5).
- Buff totems last 5 minutes (was 2).
- **Call of the Elements** (level 20) drops a saved set of 4 totems (one per element) with one 3 second cast. **Call of the Spirits** (30) and **Call of the Ancestors** (40) add more saved sets.
- **Totemic Recall** removes your totems and refunds 25% of their mana. (Known beta bug: refund does not work yet.)
- **Totemic Projection** (level 22) moves all totems up to 30 yards. 1 minute cooldown.
- Resistance totems now help the whole raid group.
- 🟡 Totems still only help your party (5 people), except resistance totems.

| Element | Totems | Unlocks at |
|---------|--------|-----------|
| Earth | Stoneskin, Earthbind, Stoneclaw, Strength of Earth, Tremor | Level 4 |
| Fire | Searing, Magma, Flametongue, Frost Resistance | Level 10 |
| Water | Healing Stream, Mana Spring, Poison Cleansing, Disease Cleansing, Fire Resistance, Mana Tide (talent) | Level 20 (quest) |
| Air | Grounding, Windfury, Grace of Air, Nature Resistance, Windwall, Sentry | Level 30 (quest) |

🟡 Some numbers: Strength of Earth rank 5 gives 53 Strength. Windfury Totem rank 3 gives 246 attack power. Grace of Air rank 3 gives 89 Agility. Mana Tide gives 88 mana every 3 seconds.

---

## 6. Addon code: what the game lets us do

This is the most important section for building the addon.

### Version number

- ✅ The **interface number** is **16001**. (Classic uses 11509. Retail uses 120100.)
- Our addon's **TOC file** must say `## Interface: 16001` or the game will mark it "out of date".
- 🟡 Addons go in: `World of Warcraft\_classic_beta_\Interface\AddOns\` (the exact folder might change at launch).

### It uses the modern (retail) addon system

✅ Blizzard confirmed Forever uses "the same addon interface as retail". That means:

- Old Classic functions are **gone**: `GetSpellInfo`, `GetItemInfo`, `GetTalentInfo`, `UnitAura`. 🟡
- We use the new versions instead: `C_Spell.GetSpellInfo`, `C_Item.GetItemInfo`, `C_UnitAuras`. 🟡
- Talents are read with `C_Traits` and `C_ClassTalents` (the retail talent system). 🟡

So tutorials for **Classic** addons will often be wrong. Tutorials for **retail** addons are closer.

### What we CAN read (good news for our plan)

A tester captured the full list of functions in the beta client ([forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit)). These exist (🟡: they exist, but we still need to test they return real numbers):

| What we want | Function |
|--------------|----------|
| Strength, Agility, Stamina, Intellect, Spirit | `UnitStat("player", 1..5)` |
| Spell damage per school | `GetSpellBonusDamage(school)` |
| Healing power | `GetSpellBonusHealing()` |
| Crit chance | `GetCritChance()`, `GetSpellCritChance(school)` |
| Hit chance | `GetHitModifier()`, `GetSpellHitModifier()` |
| Haste | `GetHaste()`, `GetMeleeHaste()` |
| Expertise | `GetExpertise()` |
| Attack power | `UnitAttackPower("player")` |
| Weapon damage and speed | `UnitDamage("player")`, `UnitAttackSpeed("player")` |
| Mana and max mana | `UnitPower("player", 0)`, `UnitPowerMax("player", 0)` |
| Mana regen | `GetManaRegen()` |
| Current weapon buff | `GetWeaponEnchantInfo()` |
| Active totems | `GetTotemInfo(slot)` |
| Equipped gear | `GetInventoryItemLink("player", slot)` |
| Spell mana cost | `C_Spell.GetSpellPowerCost(spellID)` |
| Talents | `C_ClassTalents.GetActiveConfigID()` + `C_Traits.GetTreeNodes(...)` / `GetNodeInfo(...)` |
| Known spells | `IsPlayerSpell(spellID)` |

### What we CAN'T do (the restrictions)

✅/🟡 Forever copies the newer retail **combat restrictions** (from the "Midnight" expansion):

- **No combat log for addons.** 🟡 We can't watch every hit you do during a fight like old DPS meters did. This means our "simulated DPS" must be **calculated from your stats**, not recorded from fights.
- **Secret values in combat.** 🟡 Some numbers (health, auras, maybe stats) become "secret" during combat. Addons can show them but not do math on them. There is even a check called `C_Secrets.ShouldUnitStatsBeSecret`. **Plan:** do all our math **out of combat**.
- ✅ The game has its **own built-in damage meter**. 🟡 Addons may be able to read its totals through `C_DamageMeter`. That could let us compare "our predicted DPS" with "your real DPS" later.
- 🟡 Some features are broken in beta: SavedVariables (how addons save settings) were not loading back. A tester says build 70009 fixed it, but this is unverified. `ReloadUI()` can't be called from code; type `/reload` instead.

---

## 7. How we will do the math (plan for Step 3)

Because we can't record fights, the addon will **calculate**. Here is the simple idea, written like code you'd see in C#:

### Damage of one spell

```
average hit   = (spell base damage) + (spell power × coefficient)
coefficient   = cast time ÷ 3.5        // 🔶 Classic rule, e.g. 2.5 ÷ 3.5 = 0.714 for Lightning Bolt
chance to land = hit chance             // 🔶 vs a boss 3 levels higher, Classic misses 17% of spells before hit gear
crit bonus    = 50% extra damage        // 🔶 Classic spells crit for 150%; Elemental Fury adds 20% more 🟡
expected damage = average hit × chance to land × (1 + crit chance × crit bonus)
```

### "How much damage can I do with my mana?" (your mana pool question)

```
damage per mana  = expected damage ÷ mana cost
total damage     = (max mana + mana regained during the fight) × damage per mana
```

The addon will do this for each spell and each rank, and tell you which spells give the most damage per mana. (In Classic, lower ranks were often more mana efficient. In Forever this may matter less, since spell power now comes from gear. 🟡)

### "What is my maximum DPS?"

```
DPS = expected damage ÷ cast time (after haste)
```

For Enhancement we add melee:

```
melee DPS = (weapon damage + attack power ÷ 14 × weapon speed) ÷ weapon speed   // 🔶 Classic rule
          + weapon buff damage + Windfury procs + Stormstrike + shocks
```

Then we combine the two and also find **when you run out of mana**: "You can do 180 DPS for 45 seconds, then 95 DPS after you run out of mana."

### Stat priority from your gear

The addon will pretend you have +10 of one stat, re-run the DPS math, and see how much DPS went up. Do this for each stat, sort by the gain, and you get **your** personal stat priority. (Big addons call these "stat weights".)

### Where the base numbers come from

- 🟡 Spell mana costs: from the game directly with `C_Spell.GetSpellPowerCost`.
- 🟡 Spell base damage and coefficients: not readable through code. We will store them in a data table inside the addon (from the sources in this document), and update them as the beta changes.

---

## 8. Things we still need to find out (in game)

Angel, these are things you could help test once the starter addon exists. The addon can print them for you.

1. ❓ Do `UnitStat`, `GetSpellBonusDamage`, `GetCritChance` and `GetHaste` return real numbers? (Out of combat and in combat.)
2. ❓ How much haste do you get per point?
3. ❓ Exact spell power coefficients (we'll compare tooltip numbers with and without gear).
4. ❓ How Flametongue Weapon scales with weapon speed.
5. ❓ Do talent readings through `C_Traits` show the Shaman talent trees correctly?
6. ❓ Does saving settings (SavedVariables) work in the current beta build?

---

## 9. Recommended addon structure

This is a proposal for Step 2. Nothing is built yet.

```
TheEarthenShrink/
  TheEarthenShrink.toc     -- tells WoW about the addon (name, version 16001, file list)
  Core.lua                 -- starts the addon, listens for game events
  Data/Spells.lua          -- table of spell numbers (damage, coefficients)
  Data/Imbues.lua          -- weapon buff numbers
  Player/Stats.lua         -- reads your stats, gear, talents
  Math/Damage.lua          -- the formulas from Section 7
  UI/MainWindow.lua        -- the window with tabs
  UI/Tabs/*.lua            -- Overview, Weapon Buffs, Stat Priority, Mana & DPS, Tips
```

Tabs we plan:
1. **Overview**: your spec, talents, key stats.
2. **Weapon Buffs**: your existing comparison, upgraded with the "crossing with totems" rule.
3. **Stat Priority**: stat weights from your gear.
4. **Mana & DPS**: total damage per mana pool and max DPS.
5. **Tips**: totems, spells and rotation tips for your spec.

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
- **Coefficient**: how much of your spell power gets added to a spell. 0.714 means 71.4%.
- **Combat log**: a stream of every hit, heal and buff in a fight. Forever hides it from addons.
- **Crit**: a critical hit, which does extra damage.
- **Expertise**: lowers the chance the enemy dodges or parries your melee.
- **Haste**: makes you cast and attack faster.
- **Imbue**: a Shaman weapon buff (Windfury, Flametongue, Frostbrand, Rockbiter).
- **Interface number**: the version number in the TOC file that tells WoW which game version the addon is made for.
- **MP5**: mana per 5 seconds.
- **Rank**: older spells have levels (Rank 1, Rank 2...). Higher ranks hit harder but cost more.
- **SavedVariables**: how an addon remembers settings between game sessions.
- **Secret value**: a number the game lets an addon *show* but not *calculate with*, during combat.
- **Stat weight**: how much DPS one point of a stat is worth to *you*.
- **TOC file**: the addon's "table of contents" file. WoW reads it first.
- **Vanilla**: the original 2004 version of WoW.

---

## Sources

- Blizzard: [Forever Class Deep Dives: Mage and Shaman](https://worldofwarcraft.blizzard.com/en-us/news/24302097)
- [Warcraft Tavern: WoW Forever Shaman Guide](https://www.warcrafttavern.com/forever/guides/shaman/)
- [Icy Veins: Elemental](https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-guide), [Restoration](https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-guide)
- [wow.gg: Enhancement (Beta)](https://wow.gg/guides/wow-forever-enhancement-shaman-beta)
- [ForeverChanges: Shaman changes vs Classic](https://foreverchanges.pro/class/shaman) (source of most 🟡 numbers)
- [OutputLag: Forever unifies hit and crit](https://outputlag.com/news/world-of-warcraft-forever-unifies-hit-and-crit-stats-and-gives-healing-gear-bonus-damage/)
- [Gold Boosting: Expertise explained](https://goldboosting.com/blog/understanding-expertise-wow-forever-beginners-guide)
- [WoW Forever Guides: Addon development, interface 16001](https://wowforeverguides.com/addons/developers)
- [PewPewShop: Forever addons and modern API](https://pewpewshop.pro/wow-boost/blog~wow-forever-addons-modern-client-api-built-in-damage-meter)
- [forever-addon-kit (GitHub)](https://github.com/Thunderz96/forever-addon-kit): captured list of beta API functions
- [Blizzard forums: Flametongue vs Windfury feedback](https://us.forums.blizzard.com/en/wow/t/forever-is-forcing-enhancement-onto-flametongue-that-is-not-the-class/2375734)
