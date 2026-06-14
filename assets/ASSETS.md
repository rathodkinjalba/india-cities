# Game Assets — Sources & Licenses

Free, properly-licensed assets for the Monopoly board game (Godot 4.4).

## ✅ Already downloaded & installed (all CC0)

| Pack | Folder | Contents |
|------|--------|----------|
| Kenney Board Game Pack | `models/kenney_boardgame/` | **2D PNG sprites**: dice faces (7 colors), tokens/pieces (7 colors), chips, cards, spritesheets + vector |
| Kenney UI Pack | `ui/kenney_ui/` | 870 PNGs: buttons, panels, sliders, checkboxes |
| Kenney Casino Audio | `audio/sfx/kenney_casino/` | `dice-throw`, `dice-shake`, `dice-grab`, chip & card sounds (.ogg) |
| Kenney Interface Sounds | `audio/sfx/kenney_interface/` | 100 UI click/confirm/error sounds (.ogg) |

> **Note:** The Board Game Pack is **2D sprite art**, not 3D models. Your game currently
> uses procedural 3D dice. Options: (a) keep 3D dice + use these PNGs as dice-face textures,
> or (b) download a free **3D** pack manually — see [Voxel Board Games](https://kytric.itch.io/board-game-assets) (CC0, has Godot demo).
> Still TODO (manual download): **fonts** (`fonts/`) and **background music** (`audio/music/`).

---


**License legend**
- **CC0** = public domain. No attribution required. Commercial use OK. ✅ Safest.
- **OFL** = SIL Open Font License. Free for any use; don't sell the font file by itself.
- **Pixabay / Royalty-free** = free to use, no attribution required (check the per-file note).

> ⚠️ **Trademark note:** these assets are free, but the *Monopoly* name, logo, and the
> specific board/property names are Hasbro trademarks. Fine for personal/learning use.
> If you publish commercially, rename the game and use generic property names.

---

## Folder layout

```
assets/
  models/      → 3D dice, tokens, board pieces (.glb / .gltf / .obj)
  ui/          → buttons, panels, icons (.png / sprite sheets)
  audio/
    sfx/       → dice roll, coin, button clicks (.ogg / .wav / .mp3)
    music/     → background loops (.ogg / .mp3)
  fonts/       → display + body fonts (.ttf / .otf)
```

Godot tip: prefer **`.glb`** for models and **`.ogg`** for audio — both import cleanly.

---

## 1. 3D models — dice, tokens, pieces  → `assets/models/`

| Source | License | Notes |
|--------|---------|-------|
| [Kenney — Board Game Pack](https://kenney.nl/assets/boardgame-pack) | CC0 | ⭐ 490 assets, GLB format, imports straight into Godot |
| [Voxel Board Games (itch.io)](https://kytric.itch.io/board-game-assets) | CC0 | Includes Monopoly-style board, tokens, dice + a Godot demo scene |
| [Kenney → Godot 3D import guide](https://kenney.nl/knowledge-base/game-assets-3d/importing-3d-models-into-game-engines) | — | How to bring GLB into Godot cleanly |

## 2. UI — buttons, panels, icons  → `assets/ui/`

| Source | License | Notes |
|--------|---------|-------|
| [Kenney — UI Pack](https://kenney.nl/assets/ui-pack) | CC0 | 430 buttons / panels / sliders |
| [Kenney — Board Game Icons](https://kenney-assets.itch.io/board-game-icons) | CC0 | Dice, money, property icons |
| [Kenney — Board Game Info](https://kenney.nl/assets/board-game-info) | CC0 | Info/status icons |

## 3. Audio — SFX & music  → `assets/audio/`

| Source | License | Notes |
|--------|---------|-------|
| [Pixabay — dice roll SFX](https://pixabay.com/sound-effects/search/roll-dice/) | Royalty-free | → `audio/sfx/` |
| [Pixabay — CC0 SFX](https://pixabay.com/sound-effects/search/cc0/) | CC0 | coins, clicks → `audio/sfx/` |
| [Free-Stock-Music — retro coin](https://www.free-stock-music.com/sound-effects-library-coin.html) | CC0 | → `audio/sfx/` |
| [CC0 Game Music Vol. 1 (itch.io)](https://duckhive.itch.io/game-music-1/purchase) | CC0 | background loops → `audio/music/` |

## 4. Fonts  → `assets/fonts/`

| Source | License | Notes |
|--------|---------|-------|
| [Google Fonts](https://fonts.google.com) | OFL / Apache | Filter Display + Bold. Board-game picks: Bungee, Passion One, Anton, Oswald |

## 5. General catalogs (browse for anything else)

| Source | License | Notes |
|--------|---------|-------|
| [OpenGameArt — Boardgame Pack](https://opengameart.org/content/boardgame-pack) | Mixed | 19 pieces × 7 colors, dice, cards — check per-asset license |
| [itch.io — CC0 game assets](https://itch.io/game-assets/assets-cc0) | CC0 | Huge index |
| [awesome-cc0 (GitHub)](https://github.com/madjin/awesome-cc0) | — | Curated list of CC0 sources |

---

## How to add a downloaded pack

1. Unzip into the matching subfolder, e.g. `assets/models/kenney_boardgame/`.
2. Keep the pack's own `License.txt` next to it.
3. Add a row to this file noting which pack went where.
4. Let Godot import it (open the editor once so `.import` files generate).
