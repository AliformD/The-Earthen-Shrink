# The Earthen Shrink (addon)

A Shaman helper for World of Warcraft: Forever. Type `/es` in game to open it.

## Install

1. Copy the `TheEarthenShrink` folder into `World of Warcraft\_classic_\Interface\AddOns\`
   (use the folder that has the Forever `Wow.exe` in it).
2. The final path should be `...\AddOns\TheEarthenShrink\TheEarthenShrink.toc`.
3. On the character screen, open **AddOns** and make sure **The Earthen Shrink** is ticked.

## Tabs

| Tab | What it shows |
|-----|---------------|
| **Weapon Buffs** | Rockbiter, Flametongue and Windfury at the highest rank for your level, the DPS each one adds, and the math (hover a row). "Post to chat" puts a short summary in your chat box. |
| **Spell Efficiency** | Every damage spell and every rank: level, mana, % of your mana bar, damage, damage per mana and DPS. The best damage per mana is green. You can sort by spell or by damage per mana, and show ranks you can't learn yet. |
| **Inspect** | Target another player and press **Inspect target**. It reads their gear and works out which weapon buff is best for them. "Post to chat" puts the result and the formula in your chat box. You pick the channel and press Enter. |

## Commands

| Type | What it does |
|------|--------------|
| `/es` | Open or close the window |
| `/es spells` | Open the Spell Efficiency tab |
| `/es inspect` | Inspect your target and open the Inspect tab |
| `/es check` | Print what the addon could read from the game (helps find problems) |
| `/es sptooltip on` / `off` | Tell the addon whether your spell tooltips already include spell power |

## Where the numbers come from

**From the game (real Forever data):**
- Spell names, mana costs, cast times and base damage (read from each spell's tooltip text)
- The level each rank is learned at (from the game, or from your class trainer once you open it)
- Your mana, spell power, crit, hit, attack power and weapon
- Another player's gear and weapon (when inspected)

**Old Classic rules, used until we can test them in Forever** (all in `Math/Spells.lua` and `Math/Imbues.lua` under `RULES`, so they're easy to change):
- How much spell power each spell gets (cast time ÷ 3.5), and the penalty for ranks learned before level 20
- 96% base spell hit, 5% melee miss, 5% dodge
- Crits: +50% for spells, +100% for melee
- 14 attack power = 1 DPS
- Flametongue's tooltip range covers 1.0 to 4.0 speed weapons
- For inspected players: their base stats, attack power and crit are estimated from their level and gear

**Not counted yet:** talents, and buffs on inspected players.

## "Highest rank for your level"

The addon assumes you bought the highest rank you can learn at your level. It finds ranks three ways:
1. Your spellbook (always right for ranks you know)
2. Your class trainer: **open the Shaman trainer once** and the addon saves every rank and its level
3. A starting list of old Classic spell IDs. Any ID the game doesn't recognise is skipped.

So if a rank you should have is missing, visit your trainer once.
