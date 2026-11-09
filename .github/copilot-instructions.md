# GitHub Copilot Instructions — The Last Wild Paw

## Project Context

**The Last Wild Paw Universe** grows the animated series *The Last Wild Paw* (African wildcats, prehistoric Fayum
lakeshore, told as fiction) into a universe of website, community and small games. This repository holds the first
game, **The Last Wild Paw: Survival Journey**: a short 2D side-scroller where the player is Kai.

### Key Information
- **Current Phase:** Phase 1: one-stage playable prototype (working title "The Desert")
- **Engine:** Godot 4 (2D), GDScript with static typing
- **Distribution:** desktop builds on GitHub Releases; browser demo (Godot Web export) on GitHub Pages
- **Backend:** none. No game server, accounts, login or database

---

## Product Rules (do not break)

1. **Small and polished.** One finished stage beats five unfinished ones. Don't add stages, characters or systems
   the phase file doesn't list.
2. **Original work only.** Kunio-kun and Contra are gameplay references. Never copy their sprites, sounds, music,
   level layouts or names.
3. **Canon is fixed** (series Story Bible). Kai: young male, sandy golden-brown coat, dark leg markings, amber eyes,
   ringed tail with a dark tip, dark spot below the **left** eye. Sera: Kai's mother, gray-brown sandy coat, amber eyes,
   dark tail tip, notch on the **right** ear. Nefi: Kai's younger sister. Setting ~4500 BCE Fayum lake basin (reeds,
   scrub, rocky dens; not Sahara dunes, no dynastic Egypt). Series look: Paper Collage. Cats stay wild: no cute
   proportions, smiles, upright poses or speech. Don't change appearance, relationships or story events.
4. **No Web3.** No NFT, token, wallet or Play-to-Earn code. No accounts or online services in the game.
5. **Playable without the series.** Easter eggs reward fans; nothing requires having watched an episode.
6. **Offline and private.** Saves and achievements are local (`user://`). No analytics or network calls in the game.

---

## Code Style & Conventions

- GDScript: static types (`var speed: float`), `snake_case` files and functions, `PascalCase` `class_name`;
  `gdformat` + `gdlint` clean.
- One scene per thing (`player.tscn` + `player.gd`); communicate up with signals, down with method calls.
- Input only through the Input Map actions (`move_left`, `move_right`, `jump`, `attack`, `pause`), never raw keys.
- Gameplay numbers (speed, gravity, damage) are `@export` vars or `Resource`s, not magic numbers in code.
- Rules that can be pure (damage, scoring, stage completion) are static functions so they can be tested headless.
- Open decisions live in `.claude/specs/decisions.md` (local). Do not settle one silently in code.

## Commits

`2026 <Verb> <Thing> (<Part>).` — e.g. `2026 Added Player Movement (Prototype).`
