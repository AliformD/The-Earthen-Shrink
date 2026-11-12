# The Earthen Shrink (addon)

A Shaman helper for World of Warcraft: Forever. Type `/es` in game to open it.

## Install

1. Copy the `TheEarthenShrink` folder into `World of Warcraft\_forever_\Interface\AddOns\`
   (not `_classic_` or `_retail_`).
2. The final path should be `...\_forever_\Interface\AddOns\TheEarthenShrink\TheEarthenShrink.toc`.
   There's also a `TheEarthenShrink_Forever.toc` next to it. Keep both; the game picks the one it wants.
3. Close the game fully and start it again (`/reload` doesn't find new addons).
4. On the character screen, open **AddOns**, set the dropdown at the top to **All characters**,
   and make sure **The Earthen Shrink** is ticked. If it says "out of date", tick **Load out of date AddOns**.

If it still doesn't show up, type `/dump select(4, GetBuildInfo())` in game. The number it prints must
match the `## Interface:` line at the top of both .toc files (currently 16001).

## Tabs

The sections are the round icon buttons down the left side of the window (like the Group Finder).

| Tab | What it shows |
|-----|---------------|
| **Weapon Buffs** | Rockbiter, Flametongue, Frostbrand and Windfury at the highest rank for your level. Each one is tested on 50 simulated main-hand swings with your real weapon, attack power and crit, and the one that adds the most damage is marked best. Shows extra damage per swing, over 50 swings, and DPS (hover a row for the math). Click the settings rows to say if Windfury Totem is in your group, whether it stacks with Windfury Weapon, and to try a Flametongue spell power bonus. "Post to chat" puts a short summary in your chat box. |
| **Spell Efficiency** | Every damage spell and every rank (including Stormstrike and Lightning Shield): level, mana, % of your mana bar, damage, damage per mana and DPS. The best damage per mana is green. You can sort by spell or by damage per mana, and show ranks you can't learn yet. |
| **Healing** | Every heal and every rank (Healing Wave, Lesser Healing Wave, Chain Heal, Riptide): mana, % of your mana, healing, healing per mana and healing per second. The most efficient useful rank gets a tick. |
| **Totems** | Every totem at your level: cost, % of your mana, and its break-even: how many hits (Searing), enemies (Magma), or seconds (Healing Stream, Mana Spring) before it beats your best spell or heal. Also Fire Nova and Lightning Shield breakpoints, and Call of the Elements vs placing totems one by one. |
| **Sim Lab** | Try stats without wearing them. Each slider adds (or takes away) Strength, Agility, Intellect, Spell Power, Healing, Attack Power, Crit % or Hit %, and the list shows each spell's damage or healing now, with the change, and the difference. You can switch the list between per cast, per mana and per second. To try an item, open the Sim Lab and **shift-click** the item anywhere (bags, a chat link, a loot-list addon), or drop it on the box at the top. It's compared with what you wear in that slot and the sliders are set to the difference (a main-hand weapon also swaps the weapon damage). Tick **Mental Dexterity** if you have that talent, so Intellect counts as attack power. |
| **SP Test** | Measures how much of your spell power each spell really gets in Forever (its "coefficient"). Pick a spell on the left. Click **BEFORE**, cast the spell, and type the number of each normal hit (not crits) into the box, then press Enter. Put on more spell power gear, click **AFTER** and do the same. The answer is `(average after - average before) / spell power added`, shown with a "±" (how sure it is). **Good** and **Okay** results can be saved, and then the Spells tab and Sim Lab use your number instead of the old Classic rule. The page also tells you how many hits you need: small spell power changes need many hits, because a spell's damage jumps around more than +5 spell power changes it. Besides spells, you can test **Flametongue Weapon** and **Flametongue Totem** (type the small fire number on each of your swings), **Searing Totem** and **Magma Totem**. A saved Flametongue result replaces the unverified Flametongue setting on the Weapon Buffs tab. Each result also shows a **stat weight**: how much DPS 1 spell power adds, and how many Strength that's worth. The Sim Lab lists all your saved results this way under "1 spell power is worth". Flame Shock ticks are tested on their own row ("over time"); ticks are usually the same number each time, so there you need a bigger spell power change rather than more ticks. Addons can't read your hits in Forever (the combat log is hidden), so you type them in. If a client ever does allow it, a "record by itself" box appears. |
| **Inspect** | Target another player and press **Inspect target**. It reads their gear and works out which weapon buff is best for them. "Post to chat" puts the result and the formula in your chat box. You pick the channel and press Enter. |

## Commands

| Type | What it does |
|------|--------------|
| `/es` | Open or close the window |
| `/es spells` | Open the Spell Efficiency tab |
| `/es healing` / `/es totems` | Open the Healing or Totems tab |
| `/es sim` | Open the Sim Lab |
| `/es test` | Open the Spell Power Test |
| `/es meter` | Prints what the game's damage meter tells addons (send a screenshot so we can read hits from it later) |
| `/es inspect` | Inspect your target and open the Inspect tab |
| `/es check` | Print what the addon could read from the game (helps find problems) |
| `/es sound` (or `on` / `off`) | Turn the Windfury proc sound on or off (on by default) |
| `/es sound test` | Test mode: prints what the game tells the addon, so you can see if Windfury procs are detected |
| `/es sptooltip on` / `off` | Tell the addon whether your spell tooltips already include spell power |
| `/es wftotem on` / `off` | Windfury Totem is (or isn't) in your group. Same as clicking the setting row |
| `/es wfstack on` / `off` | Windfury Totem does (or doesn't) stack with Windfury Weapon |
| `/es ftcoef 0.1` | Unverified: add 10% of your Fire spell power to each Flametongue hit |
| `/es swings 50` | How many swings the weapon buff test uses |

## Where the numbers come from

**From the game (real Forever data):**
- Spell names, mana costs, cast times and base damage (read from each spell's tooltip text)
- The level each rank is learned at (from the game, or from your class trainer once you open it)
- Your mana, spell power, crit, hit, attack power and weapon
- Another player's gear and weapon (when inspected)

**Old Classic rules, used until we can test them in Forever** (all in `Math/Spells.lua` and `Math/Imbues.lua` under `RULES`, so they're easy to change):
- How much spell power each spell gets (cast time ÷ 3.5), and the penalty for ranks learned before level 20. **You can replace this with your own measured number on the SP Test tab.**
- Damage over time ticks every 3 sec (so Flame Shock has 4 ticks). You can change the number of ticks on the SP Test tab
- 96% base spell hit, 5% melee miss, 5% dodge
- Crits: +50% for spells, +100% for melee
- 14 attack power = 1 DPS
- Flametongue's tooltip range covers 1.0 to 4.0 speed weapons
- Flametongue gets 0% of your spell power (people say it gets some; not tested, so it's a setting)
- Frostbrand procs about 9 times a minute when its tooltip doesn't give a chance
- Windfury's extra attacks can't proc Windfury again; with the totem stacking, each rolls its own chance
- If Rockbiter is on your weapon now, the addon takes its attack power out of your stats before testing
- For inspected players: their base stats, attack power and crit are estimated from their level and gear

**Not counted yet:** talents, and buffs on inspected players.

## "Highest rank for your level"

The addon assumes you bought the highest rank you can learn at your level. It finds ranks three ways:
1. Your spellbook (always right for ranks you know)
2. Your class trainer: **open the Shaman trainer once** and the addon saves every rank and its level
3. A starting list of old Classic spell IDs. Any ID the game doesn't recognise is skipped.

So if a rank you should have is missing, visit your trainer once.
