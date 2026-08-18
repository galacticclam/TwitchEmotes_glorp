# Animated Emote Import Procedure

This file documents the procedure for importing animated emotes into the TwitchEmotes_glorp project.

## 1. Select the emote source

- Identify the animated emote URL, for example a 7TV `.webp` animation URL.
- Choose the local emote name, e.g. `FROG4`.

## 2. Import the animated asset

- Run the repository import script with the source URL and chosen name.
- Example:
  ```bash
  ./import-animation.sh "https://cdn.7tv.app/emote/01KG6N0PJSDP7GPCB542CCB979/2x.webp" FROG4
  ```
- The script should:
  - download the animation asset
  - extract frames
  - build a stacked texture sheet
  - place the resulting file under `emotes/`
  - optionally add fallback metadata

## 3. Verify generated image layout

- Confirm the final texture exists and inspect its dimensions.
- Example using ImageMagick:
  ```bash
  magick identify -format '%w x %h %m\n' dist/TwitchEmotes_glorp/emotes/FROG4.tga
  ```
- Confirm the sheet is laid out in a single column or the expected number of columns.

## 4. Add the emote to `emotes.lua`

- Add a lookup entry in `emotes.lua`:
  ```lua
  ["FROG4"] = basePath .. "FROG4.tga:28:28",
  ```
- The size values after the path are only a placeholder used by the parser.
- They are immediately replaced at render time with the frame-specific texture escape string for the current frame.

## 5. Add animation metadata in `animation.lua`

- Add or correct the metadata entry in `animation.lua`.
- Use the actual frame dimensions and stack layout.
- Example:
  ```lua
  TwitchEmotes_animation_metadata[basePath .. "FROG4.tga"] = {
      ["nFrames"] = 123,
      ["frameWidth"] = 64,
      ["frameHeight"] = 32,
      ["imageWidth"] = 192,
      ["imageHeight"] = 7872,
      ["framerate"] = 18,
  }
  ```
- Important: do not introduce stray syntax characters like `[` or `]` into the table literal.

## 6. Validate runtime metadata semantics

- The addon runtime uses `frameHeight` to compute frame UV offsets.
- If the imported sheet contains wide frames or extra padding, ensure `frameWidth` and `frameHeight` correctly match the actual source frame size.
- `imageFrameHeight` is not used by the current runtime build functions.

## 7. Rebuild and install the addon

- Ask before rebuilding or installing the addon locally.
- If you want the package updated, run:
  ```bash
  ./build.sh && ./install.sh retail
  ```
- This makes the updated asset and metadata available to the WoW addon.

## 8. Verify before testing

- After rebuild, confirm the generated texture and metadata are correct.
- Example: inspect `dist/TwitchEmotes_glorp/emotes/FROG4.tga` and `animation.lua`.
- Leave the actual in-game testing to the user.

## 9. Debugging notes

- Common cause of tearing: wrong `frameHeight` or invalid Lua table syntax in `animation.lua`.
- Validate that each metadata entry is a valid Lua table literal and that the field names are correct.
- If `FROG4` or another wide animation is mis-rendered, check the generated texture layout and compare to existing working wide emotes such as `buhFlipExplode`.
