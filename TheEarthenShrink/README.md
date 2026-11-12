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

## Minimap button

A round lightning icon sits on the edge of your minimap.

- **Left-click**: open or close the window (same as `/es`).
- **Right-click**: options: lock it in place, or hide it.
- **Drag** (left mouse button): slide it around the minimap. The spot is saved.
- Hidden it by mistake? Type `/es minimap` to bring it back, or `/es minimap reset` to put it back in its first spot.

The addon is also listed in the game's addon list next to the minimap (the "addon compartment"), if your client shows one.

In the AddOn list (character screen) the addon sits under its own **Shaman** heading.

## Tabs

The sections are the round icon buttons down the left side of the window (like the Group Finder).

**Window size:** drag the grip in the bottom-right corner to make the whole window bigger or smaller (everything inside grows with it, so nothing moves around or overlaps). Right-click the grip to go back to normal size. The size is saved.

| Tab | What it shows |
|-----|---------------|
| **Weapon Buffs** | Rockbiter, Flametongue, Frostbrand and Windfury at the highest rank for your level. Each one is tested on 50 simulated main-hand swings with your real weapon, attack power and crit, and the one that adds the most damage is marked best. Shows extra damage per swing, over 50 swings, and DPS (hover a row for the math). Click the settings rows to say if Windfury Totem is in your group, whether it stacks with Windfury Weapon, and to try a Flametongue spell power bonus. "Post to chat" puts a short summary in your chat box. |
| **Spell Efficiency** | Every damage spell and every rank (including Stormstrike and Lightning Shield): level, mana, % of your mana bar, damage, damage per mana and DPS. The best damage per mana is green. You can sort by spell or by damage per mana, and show ranks you can't learn yet. Click a spell's title to fold its ranks away (click again to open them); **Collapse all** / **Expand all** does every spell. Your choice is saved. |
| **Healing** | Every heal and every rank (Healing Wave, Lesser Healing Wave, Chain Heal, Riptide): mana, % of your mana, healing, healing per mana and healing per second. The most efficient useful rank gets a tick. Click a spell's title to fold its ranks away (click again to open them); **Collapse all** / **Expand all** does every spell. Your choice is saved. |
| **Totems** | Every totem at your level: cost, % of your mana, and its break-even: how many hits (Searing), enemies (Magma), or seconds (Healing Stream, Mana Spring) before it beats your best spell or heal. Also Fire Nova and Lightning Shield breakpoints, and Call of the Elements vs placing totems one by one. |
| **Sim Lab** | Try stats or items without wearing them, and see what they do to your **whole** damage. **Left side:** each slider adds (or takes away) Strength, Agility, Intellect, Spell Power, Healing, Attack Power, Crit % or Hit %. To try an item, open the Sim Lab and **shift-click** the item anywhere (bags, a chat link, a loot-list addon), or drop it on the box at the top; it's compared with what you wear in that slot and the sliders are set to the difference (a main-hand weapon also swaps the weapon damage). **Your talents**: Mental Dexterity (Intellect gives attack power) and Mental Quickness (Intellect gives spell power) each have a tick box ("I have it") and a points slider (like 2/3). They're read from your character by themselves; change them to test another build, and **Real** puts your real talents back. **How you play**: Melee, Caster or Healer picks what's in your fight mix, and the fight length slider sets how long a fight lasts (longer = mana matters more). **Right side**, five views: **Total**: everything you do in a fight added up (weapon swings, weapon buff, Stormstrike, shocks, Lightning Shield, Searing Totem; Lightning Bolt for casters; Healing Wave for healers), now and with your changes, with melee and spells shown apart, so "weaker swings but stronger spells" shows as one total. Also shows if your mana lasts the fight, and Flame Shock can be switched on or off. **Weights**: one **stat weight** per stat (how much 1 point adds to your total, counted in Strength for melee, Spell Power for casters, Healing for healers), including Intellect's mana, spell crit and talents, plus Weapon DPS and an estimate for Stamina. **Crit chance (per 1%)** and **Hit chance (per 1%)** are worth one percentage point of chance (like 9.6% to 10.6%), not one point on an item, so their weights look big next to 1 Intellect; the row underneath says how many Agility or Intellect make 1% crit. A **Hit and crit, explained** section shows your hit vs the hit cap (melee and spells), lets you switch the target between a same-level mob and a boss (+3 levels, higher cap), and explains crit chance vs crit damage. Hit past the cap is worth 0. If you have the **Flurry** talent, crit also counts the faster swings it gives. At the bottom: a **Pawn scale** string and a plain list to copy into other gear addons, and an optional detail section that shows which parts of your mix each weight comes from. **Spells**: each spell's damage or healing now and with your changes (the Healing slider now changes heals). **Buffs**: which weapon buff is best and how much more spell power or attack power would change that. **Stats**: your stats now and with the changes. |
| **SP Test** | Measures how much of your spell power each spell really gets in Forever (its "coefficient"). **Quickest way:** Forever's tooltips go up with your spell power, so pick a spell, click **BEFORE** and press **Read tooltip**, put on spell power gear, click **AFTER** and press **Read tooltip** again. The change in the tooltip ÷ the change in spell power is the coefficient (the ± comes from tooltips rounding to whole numbers). Lightning Bolt rank 6 comes built in from Angel's tooltip readings (150-169 at 13 SP, 167-186 at 37 SP = 0.71 ± 0.04). Typing real hits works too, as a double-check: pick a spell on the left. Click **BEFORE**, cast the spell, and type the number of each normal hit (not crits) into the box, then press Enter. Put on more spell power gear, click **AFTER** and do the same. The answer is `(average after - average before) / spell power added`, shown with a "±" (how sure it is). **Good** and **Okay** results can be saved, and then the Spells tab and Sim Lab use your number instead of the old Classic rule. The page also tells you how many hits you need: small spell power changes need many hits, because a spell's damage jumps around more than +5 spell power changes it. Besides spells, you can test **Flametongue Weapon** and **Flametongue Totem** (type the small fire number on each of your swings), **Searing Totem** and **Magma Totem**. A saved Flametongue result replaces the unverified Flametongue setting on the Weapon Buffs tab. Each result also shows a **stat weight**: how much DPS 1 spell power adds, and how many Strength that's worth. The Sim Lab's stat weights use your saved results too. Flame Shock ticks are tested on their own row ("over time"); ticks are usually the same number each time, so there you need a bigger spell power change rather than more ticks. Addons can't read your hits in Forever (the combat log is hidden), so you type them in. If a client ever does allow it, a "record by itself" box appears. |
| **Inspect** | Target another player and press **Inspect target**. It reads their gear and works out which weapon buff is best for them. "Post to chat" puts the result and the formula in your chat box. You pick the channel and press Enter. The game only tells an addon **your own** spell power and stats, so for another player the addon adds up what's written on their gear (spell power, Strength, Intellect and so on) and estimates the rest from their level. If their talents can be read, Mental Quickness spell power from Intellect is added (untested). |

## Commands

| Type | What it does |
|------|--------------|
| `/es` | Open or close the window |
| `/es spells` | Open the Spell Efficiency tab |
| `/es healing` / `/es totems` | Open the Healing or Totems tab |
| `/es sim` | Open the Sim Lab |
| `/es test` | Open the Spell Power Test |
| `/es changes` | Checks the game values the addon watches (Stormstrike, Windfury, Rockbiter, and the Mental Dexterity / Mental Quickness talent text if readable) and lists any that changed since last time. This also runs by itself a few seconds after you log in, and only prints if something changed |
| `/es fttotem on` / `off` | Flametongue Totem is (or isn't) in your group |
| `/es ftstack on` / `off` | Flametongue Totem does (or doesn't) stack with Flametongue Weapon (unverified) |
| `/es meter` | Prints what the game's damage meter tells addons (send a screenshot so we can read hits from it later) |
| `/es inspect` | Inspect your target and open the Inspect tab |
| `/es minimap` | Show or hide the minimap button |
| `/es minimap reset` | Put the minimap button back in its first spot and unlock it |
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
- Tooltips already include your spell power (Angel saw this in Forever), so the math takes that part out before adding spell power back. `/es sptooltip off` turns this off.
- Stormstrike does 150% weapon damage if its tooltip doesn't say (Angel, 2026-11-12: the announced 100% hotfix isn't live yet)
- Mental Dexterity gives 150% of Intellect as attack power if the talent text can't be read (same: the announced lower value isn't live yet)
- Flametongue Totem stacks with Flametongue Weapon (a setting; Blizzard's notes say weapon buffs stack with totems, using Windfury as the example)
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
