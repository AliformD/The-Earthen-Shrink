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
| **Totems** | Every totem at your level: cost, % of your mana, and its break-even: how many hits (Searing), enemies (Magma), or seconds (Healing Stream, Mana Spring) before it beats your best spell or heal. Also Fire Nova and Lightning Shield breakpoints, and Call of the Elements vs placing totems one by one. At the top: a **live timer bar** for each totem you have down, and your **Mana Spring log** (see below). |
| **Sim Lab** | Try stats or items without wearing them, and see what they do to your **whole** damage. **Left side:** each slider adds (or takes away) Strength, Agility, Intellect, Spell Power, Healing, Attack Power, Crit % or Hit %. To try an item, open the Sim Lab and **shift-click** the item anywhere (bags, a chat link, a loot-list addon), or drop it on the box at the top; it's compared with what you wear in that slot and the sliders are set to the difference (a main-hand weapon also swaps the weapon damage). **Your talents**: Mental Dexterity (Intellect gives attack power) and Mental Quickness (Intellect gives spell power) each have a tick box ("I have it") and a points slider (like 2/3). They're read from your character by themselves; change them to test another build, and **Real** puts your real talents back. **How you play**: Melee, Caster or Healer picks what's in your fight mix, and the fight length slider sets how long a fight lasts, 10 to 30 sec in steps of 5, like killing mobs while questing (longer = mana matters more). **Right side**, five views: **Total**: everything you do in a fight added up (weapon swings, weapon buff, Stormstrike, shocks, Lightning Shield, Searing Totem; Lightning Bolt for casters; Healing Wave for healers), now and with your changes, with melee and spells shown apart, so "weaker swings but stronger spells" shows as one total. Also shows if your mana lasts the fight, and Flame Shock can be switched on or off. **Weights**: one **stat weight** per stat (how much 1 point adds to your total, counted in Strength for melee, Spell Power for casters, Healing for healers), including Intellect's mana, spell crit and talents, plus Weapon DPS and an estimate for Stamina. **Crit chance (per 1%)** and **Hit chance (per 1%)** are worth one percentage point of chance (like 9.6% to 10.6%), not one point on an item, so their weights look big next to 1 Intellect; the row underneath says how many Agility or Intellect make 1% crit. A **Hit and crit, explained** section shows your hit vs the hit cap (melee and spells), lets you switch the target between a same-level mob and a boss (+3 levels, higher cap), and explains crit chance vs crit damage. Hit past the cap is worth 0. Your hit is the game's own total (gear, talents and racials), and hovering the hit row lists the talents and racials whose text mentions hit. If you have the **Flurry** talent, crit also counts the faster swings it gives. At the bottom: a **Pawn scale** string and a plain list to copy into other gear addons, and an optional detail section that shows which parts of your mix each weight comes from. **Spells**: each spell's damage or healing now and with your changes (the Healing slider now changes heals). **Buffs**: which weapon buff is best and how much more spell power or attack power would change that. **Stats**: your stats now and with the changes. |
| **SP Test** | Measures how much of your spell power each spell really gets in Forever (its "coefficient"). **Quickest way:** Forever's tooltips go up with your spell power, so pick a spell, click **BEFORE** and press **Read tooltip**, put on spell power gear, click **AFTER** and press **Read tooltip** again. The change in the tooltip ÷ the change in spell power is the coefficient (the ± comes from tooltips rounding to whole numbers). Lightning Bolt rank 6 comes built in from Angel's tooltip readings (150-169 at 13 SP, 167-186 at 37 SP = 0.71 ± 0.04). Typing real hits works too, as a double-check: pick a spell on the left. Click **BEFORE**, cast the spell, and type the number of each normal hit (not crits) into the box, then press Enter. Put on more spell power gear, click **AFTER** and do the same. The answer is `(average after - average before) / spell power added`, shown with a "±" (how sure it is). **Good** and **Okay** results can be saved, and then the Spells tab and Sim Lab use your number instead of the old Classic rule. The page also tells you how many hits you need: small spell power changes need many hits, because a spell's damage jumps around more than +5 spell power changes it. Besides spells, you can test **Flametongue Weapon** and **Flametongue Totem** (type the small fire number on each of your swings), **Searing Totem** and **Magma Totem**. A saved Flametongue result replaces the unverified Flametongue setting on the Weapon Buffs tab. Each result also shows a **stat weight**: how much DPS 1 spell power adds, and how many Strength that's worth. The Sim Lab's stat weights use your saved results too. Flame Shock ticks are tested on their own row ("over time"); ticks are usually the same number each time, so there you need a bigger spell power change rather than more ticks. Addons can't read your hits in Forever (the combat log is hidden), so you type them in. If a client ever does allow it, a "record by itself" box appears. |
| **Inspect** | Target another player and press **Inspect target**. It reads their gear and works out which weapon buff is best for them. "Post to chat" puts the result and the formula in your chat box. You pick the channel and press Enter. The game only tells an addon **your own** spell power and stats, so for another player the addon adds up what's written on their gear (spell power, Strength, Intellect and so on) and estimates the rest from their level. If their talents can be read, Mental Quickness spell power from Intellect is added (untested). |

## Totem timer (v0.13.0)

When you put a totem down, the addon starts its own stopwatch and writes down what happened to it. Hover a bar (or a totem row) to see your log.

- **How long it stayed down**, and why it ended: ran its full time, replaced by another totem, killed or gone early, Totemic Recall, you died, or you changed zone.
- **Mana Spring only:** how many mana ticks you really got. A tick = your mana went up by exactly the amount the tooltip says. If you walk out of range you get no ticks, so this shows if you were really standing there.
- **Pay-off point:** mana cost ÷ mana per tick = ticks needed. Times the tick time (from the tooltip) = seconds needed. The white line on the bar marks it, and the bar turns green after it.
- **The log line:** how many of your drops paid for themselves, and mana back vs mana spent. Last 50 drops per totem are kept.

Everything (duration, mana per tick, how often it ticks, cost) is read from the game: the totem timer under your portrait and the spell tooltip. Nothing is a Classic number.

Not tested in game yet: if Forever hides your mana or the totem timer in combat, the addon skips that part instead of guessing. A tick that happens when you are already at full mana gives nothing, so it can't be seen. Type `/es totemtest` to see what works.

## Shaman patch (v0.14.0)

The shaman changes are live (Angel saw them in game on 2026-11-13). What changed in the addon:

- **Stormstrike:** 100% weapon damage, 8 sec cooldown when the tooltip doesn't say (the tooltip still wins).
- **Mental Dexterity:** 100% of Intellect as attack power at max rank (33 / 66 / 100%). The talent text still wins.
- **Mental Quickness:** 30% of Intellect as spell power at max rank, split evenly over the ranks the game says it has. The talent text still wins.
- **Windfury Totem:** the totem gives fewer extra attacks than the weapon (one instead of two). The number is read from the totem's tooltip; if the text has no number, the totem counts as 1 and the weapon as 2.
- **Totem rules:** the totem that matches your weapon buff stacks with it, but a player only gets **one** of Windfury Totem or Flametongue Totem: the one dropped **last** overwrites the other's buff (both stay on the floor). If the addon sees both of your totems down, the math counts the last one; if only the settings say both, it counts the better one.
- **Best setup** (Weapon Buffs tab, or `/es setup`): every weapon buff × every totem plan (Windfury Totem + Searing, Windfury Totem + Magma, Flametongue Totem, Searing alone, Magma alone), run through the Sim Lab's whole damage mix. Left number = your DPS, right number = plus what the totem gives the other melee in your party. Click the setting rows to change how many enemies (Magma only shows at 2+) and how many other melee are in your party.
- **Wasted totem warning:** if your Windfury Totem and Flametongue Totem are down at the same time, you get a red chat message, a red line on the Totems tab, and the wasted bar turns red. It says which one is active (the one you dropped last), which one is wasted, and whether you should drop the other one again (the one matching your weapon buff is the one to keep). `/es wastedwarn off` turns it off.

Not in the math: **Maelstrom Weapon** (its proc chance went down in the patch; the addon doesn't use it yet).

## Commands

| Type | What it does |
|------|--------------|
| `/es` | Open or close the window |
| `/es spells` | Open the Spell Efficiency tab |
| `/es healing` / `/es totems` | Open the Healing or Totems tab |
| `/es sim` | Open the Sim Lab |
| `/es test` | Open the Spell Power Test |
| `/es changes` | Checks the game values the addon watches (Stormstrike, Windfury, Rockbiter, the Mental Dexterity / Mental Quickness / Elemental Weapons / Spirit Weapons talent text if readable, and your points in talents that change tooltips) and lists any that changed since last time. This also runs by itself a few seconds after you log in, and only prints if something changed |
| `/es fttotem on` / `off` | Flametongue Totem is (or isn't) in your group |
| `/es ftstack on` / `off` | Flametongue Totem does (or doesn't) stack with Flametongue Weapon (yes since the patch) |
| `/es meter` | Prints what the game's damage meter tells addons (send a screenshot so we can read hits from it later) |
| `/es inspect` | Inspect your target and open the Inspect tab |
| `/es minimap` | Show or hide the minimap button |
| `/es minimap reset` | Put the minimap button back in its first spot and unlock it |
| `/es talents` | Print which of your talents change the spells and weapon buffs the addon uses, and by how much (read from each talent's text) |
| `/es check` | Print what the addon could read from the game (helps find problems) |
| `/es sound` (or `on` / `off`) | Turn the Windfury proc sound on or off (on by default) |
| `/es sound test` | Test mode: prints what the game tells the addon, so you can see if Windfury procs are detected |
| `/es totemtest` | Test mode for the totem timer: prints every step (totem placed, tick seen, totem gone) so we can see what Forever tells addons |
| `/es totemtest clear` | Wipe the totem log |
| `/es sptooltip on` / `off` | Tell the addon whether your spell tooltips already include spell power |
| `/es wftotem on` / `off` | Windfury Totem is (or isn't) in your group. Same as clicking the setting row |
| `/es wfstack on` / `off` | Windfury Totem does (or doesn't) stack with Windfury Weapon |
| `/es ftcoef 0.1` | Unverified: add 10% of your Fire spell power to each Flametongue hit |
| `/es swings 50` | How many swings the weapon buff test uses |
| `/es setup` | Print the best weapon buff + totem setups in chat |
| `/es aoe 3` | Enemies in the fight for the best setup (1 = one target; 2+ also tests Magma Totem) |
| `/es groupmelee 2` | Other melee players in your party (they get your Windfury or Flametongue Totem) |
| `/es wastedwarn on` / `off` | Warn when Windfury Totem and Flametongue Totem are both down |

## Where the numbers come from

**From the game (real Forever data):**
- Spell names, mana costs, cast times and base damage (read from each spell's tooltip text)
- The level each rank is learned at (from the game, or from your class trainer once you open it)
- Your mana, spell power, crit, hit, attack power and weapon
- Another player's gear and weapon (when inspected)

**Old Classic rules, used until we can test them in Forever** (all in `Math/Spells.lua` and `Math/Imbues.lua` under `RULES`, so they're easy to change):
- Tooltips already include your spell power (Angel saw this in Forever), so the math takes that part out before adding spell power back. `/es sptooltip off` turns this off.
- Stormstrike does 100% weapon damage every 8 sec if its tooltip doesn't say (Angel, in game after the patch, 2026-11-13)
- Mental Dexterity gives 100% of Intellect as attack power at max rank, Mental Quickness 30% as spell power, if the talent text can't be read (Angel, same day)
- When both Windfury Totem and Flametongue Totem are down, the one dropped last overwrites the other's buff (Angel, in game 2026-11-13). If the addon sees both of your totems down it counts the last one; from the settings alone it counts the better one (you'd drop that one last)
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

**Talents inside your tooltips (v0.12.0):** the game writes YOUR talents into YOUR spell tooltips (with Elemental Weapons, your Rockbiter tooltip shows a bigger number). The addon reads each talent's own text, finds "your Rockbiter Weapon by 14%"-style numbers, takes your talents out of the tooltip, and puts in the talents of the character it's working out: your own (no change), the Sim Lab ticks, or an inspected player's (if the game lets us read them; otherwise "counted as none", shown on the Inspect tab). Mana cost talents ("mana cost of your Shock spells by 4%") work the same way. 🔶 Unverified: that a talent's text shows the total for the points you have, and that two talents on one spell add up. `/es talents` prints what was read.

**Not counted yet:** buffs on inspected players (other totems, food), and talents that change a spell by a flat number instead of a % (they're flagged in the spell's tooltip).

## "Highest rank for your level"

The addon assumes you bought the highest rank you can learn at your level. It finds ranks three ways:
1. Your spellbook (always right for ranks you know)
2. Your class trainer: **open the Shaman trainer once** and the addon saves every rank and its level
3. A starting list of old Classic spell IDs. Any ID the game doesn't recognise is skipped.

So if a rank you should have is missing, visit your trainer once.
