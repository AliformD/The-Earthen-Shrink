# Angel's checklist

You don't need to take screenshots. A small helper addon reads the tooltips for you and saves them all into one file.

Do these steps in order. **Do them all in one play session.** The beta has a bug where addon data sometimes doesn't load back after a reload. That means a second `/reload` could wipe the first save.

## 1. Install the helper addon

1. Download `EarthenShrinkExport.zip` from the thread.
2. Unzip it. You'll get a folder called `EarthenShrinkExport`.
3. Put that folder here: `World of Warcraft\_classic_beta_\Interface\AddOns\`
   - The final path should be `...\AddOns\EarthenShrinkExport\EarthenShrinkExport.toc`
   - If you can't find `_classic_beta_`, look for the folder that has the Forever Beta's `Wow.exe` in it.
4. Start the game. On the character screen, open **AddOns** and make sure **Earthen Shrink Export** is checked. If it says "out of date", tick **Load out of date AddOns**.

## 2. In game, before you start

1. Log in on your Shaman.
2. In chat you should see: *"Earthen Shrink Export: loaded."*
3. Put on your normal gear, weapon buff and Lightning Shield.
4. Make sure you're **out of combat** for every step.

## 3. Save your normal setup

1. Type `/esx`
2. Wait about 3 seconds for *"all done!"*
3. If it says some spells had no text yet, wait a few seconds and type `/esx` again.

## 4. Visit your class trainer

1. Go to a Shaman trainer and open the training window.
2. That's it. It saves the whole list by itself (you'll see *"saved ... trainer entries"*).

## 5. Save once without your spell power gear

This lets us calculate the real spell power formulas.

1. Take off every item that has **spell damage** or **healing** on it. Also take off your weapon if it has spell power.
2. Type `/esx nogear` and wait for *"all done!"*
3. Put your gear back on.

## 6. Write the file and send it

1. Type `/reload` **once**. This writes the file.
2. Close the game (this is safest).
3. Find this file on your PC:
   `World of Warcraft\_classic_beta_\WTF\Account\<YOUR ACCOUNT NAME>\SavedVariables\EarthenShrinkExport.lua`
4. Upload that file in the thread.

## If something goes wrong

- **Chat says nothing when you log in:** the addon isn't loading. Check step 1.3 and 1.4.
- **There's no file in SavedVariables:** type `/esx` again, then `/reload`.
- **You see a red error box:** take a screenshot and send it.
- **Anything else:** just tell me what happened in your own words.
