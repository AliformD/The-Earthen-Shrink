# Earthen Shrink Export (helper addon)

A small helper addon that saves your Shaman's real WoW Forever data to a file, so we
don't need screenshots of every tooltip. It only reads data. It never casts or changes anything.

## What it saves

- Every spell and rank in your spellbook, with the full tooltip text, mana cost and cast time
- The whole talent tree (all 3 specs), with the tooltip for **every rank** of every talent
- Your stats (Strength, Intellect, crit, hit, spell power, attack power, mana regen and more)
- Your gear, with each item's tooltip
- Your weapon buff, totems and buffs
- The class trainer list (saved automatically when you open the trainer)

## Commands

| Type this | What it does |
|-----------|--------------|
| `/esx` | Save everything |
| `/esx nogear` | Save everything under the name "nogear" (any name works) |
| `/esx status` | Show what's been saved |

The file is only written to disk when you type `/reload` or log out. It lands here:

```
World of Warcraft\_classic_beta_\WTF\Account\<YOUR ACCOUNT>\SavedVariables\EarthenShrinkExport.lua
```

See [docs/angel-checklist.md](../../docs/angel-checklist.md) for the step-by-step list.
