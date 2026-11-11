# Enhancement stat weights (draft, 2026-11-11)

> **Updated after the 2026-11-10 hotfix** (reported by Angel from in game): Stormstrike back to 100% weapon damage and 8 sec cooldown, Mental Dexterity back to 100% of Intellect, and Windfury Totem now stacks with Windfury Weapon.

Angel asked: is weapon DPS really the most important stat, and is spell power worth much for Enhancement right now?

**Short answer: yes, weapon DPS matters most, and spell power is low on the list until you have Maelstrom Weapon.**

Trust tags are the same as in `research.md`: ✅ Blizzard, ☑️ two Forever sources agree, 🟡 one source, 🔶 old Classic rule (placeholder), 🧪 needs an in-game check.

---

## 1. Checking Angel's math

| Rule | Value | Trust |
|---|---|---|
| 1 Strength | 2 attack power (AP) | 🟡 🧪 (Warcraft Tavern Forever guide) |
| 14 AP | +1 DPS on your white (auto attack) hits | 🔶 🧪 (no Forever source gives this number) |

Angel's numbers: 140 AP from gear ÷ 14 = **+10 DPS on white hits**. That math is right.

But AP also goes into **every weapon hit**, not just white hits:

- **Windfury extra attacks** use your AP (plus Windfury's own bonus AP).
- **Stormstrike** uses your weapon damage and your AP.

So 140 AP is worth a bit more than 10 DPS in total. The example below says about 18.

### Why the weapon wins anyway

**1 weapon DPS is worth about the same as 14 AP (= 7 Strength).** This stays true for Stormstrike and Windfury too, because they add weapon damage and AP together.

The weapon wins because **it carries so much more of it**. Going from a 30 DPS weapon to a 40 DPS weapon is +10 weapon DPS. That's the same as +140 AP, or +70 Strength. No other gear slot gives 70 Strength.

### Example (made-up character, 🔶 rules)

Two-hander: 40 DPS, 3.5 speed. Stormstrike every 8 sec at 100% weapon damage (Angel, in game, after the 2026-11-10 hotfix that undid the Nov 2 buff to 150% / 6 sec 🧪 tooltip).

| +1 of… | White hits | Stormstrike | Total DPS |
|---|---|---|---|
| Weapon DPS | +1.00 | +0.44 (1 × 3.5 sec ÷ 8 sec) | **≈ 1.44** |
| Attack power | +0.071 (1 ÷ 14) | +0.031 (3.5 ÷ 14 ÷ 8) | **≈ 0.10** |
| Strength (2 AP) | | | **≈ 0.20** |

1.44 ÷ 0.10 ≈ 14, so 1 weapon DPS ≈ 14 AP still holds. Windfury and crit raise both rows by the same %, so they don't change this.

⚠️ The Nov 2 notes said Stormstrike uses **normalized** weapon damage. In Classic that meant the AP part uses a fixed speed (3.3 for two-handers), not your weapon's speed. We don't know if that is still true after the hotfix. 🧪

---

## 2. Spell power for Enhancement right now

Without Maelstrom Weapon, Angel doesn't cast Lightning Bolt or Chain Lightning. Spell power then only helps:

| Spell | How often | Spell power share | Trust |
|---|---|---|---|
| Earth Shock | about every 8 to 10 sec (mana limited) | ~0.39, +20% after Stormstrike | 🔶 🧪 |
| Flame Shock | long fights only | ~0.15 hit + ~0.5 over time | 🔶 🧪 |
| Lightning Shield | only when something hits you | ~0.33 per charge | 🔶 🧪 |
| Searing Totem | every 2.5 sec | ~0.08 per hit | 🔶 🧪 |

Adding these up gives roughly **0.05 to 0.10 DPS per spell power**.

| Stat | DPS per point (example) | Compared to Strength |
|---|---|---|
| Strength | ≈ 0.20 | 1.0 |
| Spell power | ≈ 0.05 to 0.10 | **≈ 0.25 to 0.5** |

So **1 spell power ≈ ¼ to ½ of a Strength** right now. Angel is right that it should be low. Once you get Maelstrom Weapon (its proc chance was doubled in the Nov 2 notes 🟡), free instant Lightning Bolts make spell power worth a lot more. The addon should then recalculate.

---

## 3. Proposed Enhancement weights (in "Strength points")

These are a starting point for a level-ish 30 to 40 character with a two-hander and no Maelstrom Weapon. The addon should calculate them from your real stats later.

| Stat | Weight | Notes |
|---|---|---|
| Weapon DPS (per 1 DPS) | **~7** | Usually the biggest upgrade by far |
| Strength | **1.0** | |
| Attack power | **0.5** | |
| Intellect | **~0.6 with Mental Dexterity 3/3**, ~0.15 without | Angel: the 2026-11-10 hotfix put Mental Dexterity back to 100% of Int as AP (Nov 2 had 150%). 1 Int = 1 AP (0.5 Str) plus mana and a little spell power via Mental Quickness. 🧪 tooltip |
| Hit (per 1%) | ~4 | 🔶 |
| Crit (per 1%) | ~4 | 🔶, a bit more with Flurry |
| Spell power | **0.25 to 0.5** | Goes up with Maelstrom Weapon |
| Agility | ~0.2 | 🔶 Only crit (1% per 20 Agi in Classic) |

Before the hotfix, Mental Dexterity at 150% made Intellect almost as good as Strength, so cloth with Int and spell power beat Strength gear. Blizzard didn't like that and nerfed it back to 100% (Angel, 2026-11-10 hotfix). Now Intellect is about half a Strength for damage, plus mana.

---

## 4. Totems

### Windfury Totem + Windfury Weapon "double dip"

These sources disagree:
- ✅ Blizzard's Forever class post: if the buff is already on your weapon, the matching totem does nothing for you.
- 🟡 A player on the Blizzard forum (Nov 3): "Our 2h weapon enchant does not stack with Windfury Totem."
- **Newest:** Angel reports the 2026-11-10 hotfix made **Windfury Totem and Windfury Weapon stack** now. This replaces the two older notes above. 🧪 tooltip or proc count still nice to have.

🧪 **Test idea:** the Windfury sound alert (PR #2) can count procs. Do 100 swings on a training dummy with only Windfury Weapon, then 100 with the totem down too. If the proc count goes up clearly, they stack.

### Flametongue Totem vs Searing Totem

- ✅ Blizzard: **Windfury Totem and Flametongue Totem can't both be on a party.** If that's still true, Flametongue Totem would replace your Windfury Totem, not stack with it. 🧪
- Searing Totem is weak because it hits slowly and only gets a small share of spell power (🔶 0.08 per hit).
- Flametongue Totem adds fire damage to **every party melee hit**. A rogue (two weapons, fast hits) or a feral druid hits much more often than Searing Totem does. So with melee in the party it is very likely more damage than Searing. **But we need the Forever tooltip numbers to prove it.**

---

## 5. Screenshots needed from Angel (to make this real)

1. **Stormstrike** tooltip (does it say "100% weapon damage"? "normalized"? 8 sec cooldown?).
2. **Searing Totem** and **Flametongue Totem** tooltips (damage per hit, how often).
3. **Windfury Totem** and **Windfury Weapon** tooltips.
4. **Maelstrom Weapon** and **Mental Dexterity** talent tooltips.
5. **Earth Shock** tooltip, with and without one spell power item on (to work out the real share).
6. Character panel **Strength** and **Attack Power** tooltips (confirms 2 AP per Strength and 14 AP per DPS).
7. Does the character panel show **haste** anywhere?

---

## 6. Spell power coefficients (how much spell power each spell gets)

A **coefficient** is the share of your spell power added to a spell. 0.43 means "+43% of your spell power". So with 100 spell power, a 0.43 spell hits for 43 more.

**No Forever source lists coefficients for the shocks, Lightning Shield or totems yet.** Only Lightning Bolt and Chain Lightning have them. So most of this table is still the old Classic rule the addon uses (cast time ÷ 3.5, instant spells count as 1.5 sec).

| Spell | Coefficient | +damage per 100 spell power | Trust |
|---|---|---|---|
| Lightning Bolt (rank 4+, 2.5 sec cast) | 0.714 | +71 | 🟡 ForeverChanges spellbook, build 1.60.1.70888 (after the Nov 10 hotfix). Fits cast ÷ 3.5. |
| Chain Lightning | 0.714 (Nov 4) or 0.357 (Nov 11)? | +71 or +36 on the first target | ❓ ForeverDB lists both. They don't agree. |
| Earth Shock | 0.43 | +43 (+20% after Stormstrike) | 🔶 rule (instant = 1.5 ÷ 3.5) |
| Frost Shock | 0.43 | +43 | 🔶 rule |
| Flame Shock, hit | 0.15 | +15 | 🔶 rule (split between hit and burn) |
| Flame Shock, burn over 12 sec | 0.52 | +52 total | 🔶 rule |
| Lightning Shield, per charge | 0.33 | +33 | 🔶 guess |
| Searing Totem, per hit | 0.08 | +8 | 🔶 guess |
| Fire Nova, per enemy | 0.14 to 0.21 | +14 to +21 | 🟡 a player's estimate (0.143, before the Oct 16 change) / 🔶 rule |
| Stormstrike, Windfury, Flametongue Weapon | none | 0 | Weapon and attack power only. (Flametongue's fire damage depends on weapon speed.) |

### How we can measure the real numbers

This is quick to do in game, and it's the only way to be sure:

1. Hover a spell and write down its damage.
2. Take off one item that has spell power (write down how much it had).
3. Hover the spell again.
4. **Coefficient = damage change ÷ spell power change.** Example: Earth Shock drops from 420 to 399 after removing a +50 spell power item. 21 ÷ 50 = 0.42.

If the number changes, Forever tooltips already include your spell power, so type `/es sptooltip on` (otherwise the addon would add it twice). If it doesn't change, leave it off (the default).

## Sources

- [Warcraft Tavern: Forever Enhancement guide](https://www.warcrafttavern.com/forever/guides/enhancement-shaman/)
- [wow.gg: Forever Enhancement overview](https://wow.gg/guides/shaman-enhancement-forever-overview)
- [ForeverChanges spellbook (build 1.60.1.70888)](https://foreverchanges.pro/spellbook/shaman)
- [ForeverDB shaman changes](https://foreverdb.net/buffs-and-nerfs/shaman)
- [Blizzard forums: "The Big Shaman Fixlist" (player posts)](https://us.forums.blizzard.com/en/wow/t/the-big-shaman-fixlist/2378811)
- [Blizzard forums: "New enh changes" (player post quoting Nov 2 beta notes)](https://us.forums.blizzard.com/en/wow/t/new-enh-changes/2399691)
