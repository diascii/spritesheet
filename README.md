# SpriteSheet Packer & Hitbox Painter

> A high-performance Flutter utility for independent game artists and developers — pack 2D animation frames into optimized sprite sheets and paint hitboxes directly on live animations, all offline, all on your tablet or phone.

---

## Overview

SpriteSheet Packer & Hitbox Painter is a mobile-first tool designed for the **mobile workstation workflow**. Instead of switching to a desktop to run TexturePacker or Unity's sprite editor, you do everything on your iPad or Android tablet: import frames, pack them, preview the animation, and paint collision boxes with your finger or stylus — then export a production-ready PNG + JSON pair straight to your game engine project.

It is built entirely offline. No server, no subscription, no telemetry. Your assets never leave your device.

---

## Key Features

### 2D Bin Packing Engine
Automatically arranges dozens of PNG frames into a single texture using the **MaxRects algorithm** — one of the most space-efficient bin packing algorithms available. Minimizes wasted whitespace to keep GPU memory usage low.

### Alpha Trimming
Before packing, each frame is scanned to detect and strip transparent border pixels. The original source size is recorded in the metadata so your game engine can reconstruct the correct position. Trimming can reduce atlas size by 30–50% for character animations with lots of empty space.

### Live Animation Preview
Instantly preview your animation playing back from the packed frames. Adjust playback speed with a real-time FPS slider (1–60 FPS). Scrub through frames manually or loop continuously.

### Hitbox & Anchor Painter
The defining feature of this tool. A touch-interactive layer sits directly on top of the animation preview:
- **Tap** to place an anchor point (pivot) for the character
- **Drag** to draw hitbox rectangles — body box, attack box, hurt box, etc.
- Each hitbox type is color-coded for clarity
- All data is stored per-frame, not globally

All coordinates are saved as **relative values (0.0–1.0)** against the original frame dimensions, making them resolution-independent and engine-portable.

### Multi-Engine Export
Produces two output files per session:
- `spritesheet.png` — the packed texture atlas
- `spritesheet.json` — frame metadata, trim data, anchor points, and hitboxes

The JSON schema is designed to be readable by Flutter Flame, Godot, and Unity with minimal adapter code. The initial release targets Flutter Flame natively; Godot and Unity export presets are on the roadmap.

### Max Texture Size Control
Set a hard cap on the output canvas (2048×2048 or 4096×4096 px). If your frames exceed the limit, the app warns you and automatically splits overflow into a second page.

### SHA-256 Duplicate Detection
Before packing, each imported frame is hashed. Exact duplicates are flagged so you don't accidentally include the same frame twice under different filenames.

---

## Target Platforms

| Platform | Status |
|---|---|
| Android (Tablet) | Primary target |
| iPad / iOS | Primary target |
| Android (Phone) | Supported, adapted layout |
| iPhone | Supported, adapted layout |
| Desktop (macOS / Windows) | Future consideration |

The UI layout adapts: tablets get a split-panel view (asset list left, canvas right), phones get a tab-based navigation.

---

## Architecture

The app is built on Flutter using a **Clean Architecture** (Layered Architecture) approach, strictly separating algorithm logic from UI concerns.

```
lib/
├── data/
│   ├── repositories/        # File I/O, JSON read/write
│   └── sources/             # file_picker, path_provider adapters
├── domain/
│   ├── entities/            # SpriteFrame, PackResult, HitboxData, AnchorData
│   ├── repositories/        # Abstract interfaces
│   └── usecases/            # PackSprites, TrimAlpha, ExportSheet, etc.
└── presentation/
    ├── bloc/                # State management (flutter_bloc)
    ├── pages/               # Main screens
    └── widgets/             # CustomPainter, AnimationPreview, HitboxPainter
```

### Core Technical Decisions

**1. Isolate-first image processing**
All pixel-level operations (alpha trimming, bin packing, canvas stitching, PNG encoding) run in Dart `Isolate` via `compute()`. This is a hard requirement — processing 50+ high-resolution frames on the main thread will freeze the UI. The Isolate boundary is enforced from day one, not added as a later optimization.

**2. Relative coordinates only**
All hitbox and anchor data is stored as float values in the range `0.0–1.0` relative to the original frame size. Conversion to screen pixels happens only at render time. This ensures coordinates remain accurate regardless of device resolution, zoom level, or the target game's screen size.

**3. RepaintBoundary isolation**
The hitbox painter layer, the animation preview layer, and the packed sheet preview layer are each wrapped in `RepaintBoundary`. Moving a single hitbox handle does not trigger a repaint of the entire canvas.

**4. Streaming canvas write for large textures**
A 4096×4096 RGBA canvas occupies 64MB in memory. Instead of buffering the entire output image before writing, the stitching pipeline writes rows progressively to disk to avoid out-of-memory crashes on 3–4GB RAM devices.

---

## Tech Stack

| Concern | Package |
|---|---|
| Framework | Flutter (Skia / Impeller) |
| State Management | `flutter_bloc` |
| Image Processing | `package:image` |
| File Import | `file_picker` |
| File Output | `path_provider` |
| Hashing | `crypto` (SHA-256) |
| JSON | `dart:convert` (built-in) |

---

## JSON Output Schema

The exported `.json` file follows this schema. All spatial values in the `hitboxes` array use **relative coordinates (0.0–1.0)**. The `frame` and `spriteSourceSize` fields use absolute pixel values within the packed texture, as expected by sprite rendering APIs.

```json
{
  "meta": {
    "app": "SpriteSheet Packer Mobile",
    "version": "1.0.0",
    "image": "hero_spritesheet.png",
    "format": "RGBA8888",
    "size": { "w": 2048, "h": 2048 },
    "targetEngine": "flame"
  },
  "frames": {
    "hero_run_01.png": {
      "frame": { "x": 0, "y": 0, "w": 120, "h": 150 },
      "trimmed": true,
      "sourceSize": { "w": 200, "h": 200 },
      "spriteSourceSize": { "x": 40, "y": 25, "w": 120, "h": 150 },
      "anchor": { "x": 0.5, "y": 1.0 },
      "hitboxes": [
        { "type": "body",   "x": 0.15, "y": 0.10, "w": 0.70, "h": 0.85 },
        { "type": "attack", "x": 0.60, "y": 0.20, "w": 0.35, "h": 0.40 },
        { "type": "hurt",   "x": 0.20, "y": 0.15, "w": 0.60, "h": 0.70 }
      ]
    }
  }
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `frame` | px rect | Position and size of the trimmed sprite inside the packed texture |
| `trimmed` | bool | Whether alpha trimming was applied |
| `sourceSize` | px size | Original frame dimensions before trimming |
| `spriteSourceSize` | px rect | Position of the trimmed region within the original frame |
| `anchor` | relative | Pivot point for rotation/scaling (0.0–1.0 per axis) |
| `hitboxes[].type` | string | `body`, `attack`, `hurt` — extensible |
| `hitboxes[].x/y/w/h` | relative | Collision rectangle, relative to source frame size (0.0–1.0) |

---

## Development Roadmap

The plan below is written for a solo developer or a team of two. Each phase has a **Gate Review** — a concrete, testable condition that must pass before the next phase begins. Skipping gates creates compounding problems that are expensive to debug later.

Total estimated duration: **14 weeks**.

---

### Phase 1 — Engine Core (Weeks 1–3)
**Goal: A working algorithm pipeline with zero UI dependency.**

**Week 1 — Architecture & Domain Entities**
- Set up Clean Architecture folder structure
- Define core domain entities: `SpriteFrame`, `PackResult`, `HitboxData`, `AnchorData`
- Define abstract repository interfaces (no implementations yet)
- Set up unit testing framework

**Week 2 — MaxRects Bin Packing**
- Implement the MaxRects 2D bin packing algorithm in pure Dart
- Reference: *"A Thousand Ways to Pack the Bin"* by Jylänki (2010)
- Write unit tests covering edge cases:
  - Single frame
  - 100 frames
  - Frame larger than canvas
  - Frames with extreme aspect ratios (e.g., 1×200 px)
  - Canvas exactly full
- The algorithm must be callable from a test with no Flutter dependencies

**Week 3 — Alpha Trimming & Canvas Stitching**
- Alpha trimming: scan pixel borders, return `Rect` bounding box of non-transparent content
- Stitching: place sub-images onto a large canvas using coordinates from `PackResult`
- Both operations must run inside a Dart `Isolate` via `compute()`
- Benchmark target: 80 frames at 256×256 px completes in under 3 seconds on a mid-range device

> **🔴 Gate Review 1:** The packing pipeline must accept 80 images, produce a correctly stitched output, and complete in under 3 seconds — with no UI involvement whatsoever. Run this as a pure Dart test. Do not proceed to Phase 2 until this passes.

---

### Phase 2 — File I/O (Weeks 4–5)
**Goal: A complete import and export pipeline, validated against a real game engine.**

**Week 4 — Import Pipeline**
- Multi-file PNG import via `file_picker`
- File validation: format check, corrupt file detection
- Actionable error messages ("File X is not a valid PNG")
- Image decode runs in Isolate — no UI freeze during bulk import
- SHA-256 hashing per frame for duplicate detection
- Decoded frames stored as `SpriteFrame` domain entities

**Week 5 — Export Pipeline**
- JSON generator producing the schema defined above
- PNG export of stitched canvas to device storage via `path_provider`
- Both `.png` and `.json` written to the same output directory
- Max texture size enforcement with clear user warning when frames exceed the limit
- Auto page-split when frame count overflows a single texture
- Immediate `Uint8List` disposal after export to prevent memory leaks

> **🔴 Gate Review 2:** The exported `.json` + `.png` pair must load successfully in a Flutter Flame test project using `SpriteAnimationData.fromFrameData()`. If Flame cannot parse the output, Phase 2 is not complete.

---

### Phase 3 — Presentation Layer (Weeks 6–8)
**Goal: A functional, responsive UI with working animation preview.**

**Week 6 — Layout & Asset Panel**
- Tablet layout: split panel (left: asset list, right: canvas)
- Phone layout: tab-based navigation fallback
- Asset list with:
  - Thumbnail per frame
  - Drag-to-reorder
  - Swipe-to-remove
- Settings panel: sheet name, max texture size, frame padding, trim toggle

**Week 7 — Packed Canvas Preview**
- `CustomPainter` rendering the packed texture preview
- Visual grid overlay showing frame boundaries
- Pinch-to-zoom and scroll on the canvas
- Progress indicator while Isolate processes frames in background
- Error state handling for failed packs

**Week 8 — Animation Preview**
- Frame-by-frame animation renderer using imported frame order
- FPS slider (range: 1–60, default: 24)
- Play / pause / loop controls
- `RepaintBoundary` applied to all independent render layers
- Animation preview must not affect the performance of the left panel

---

### Phase 4 — Hitbox & Anchor Painter (Weeks 9–12)
**Goal: A precise, per-frame interactive painter layer with data integrated into the JSON export.**

This is the most complex phase. Each week has a hard dependency on the previous one.

**Week 9 — Coordinate System (Foundation)**
- Map touch position on screen → relative coordinate within the frame (0.0–1.0)
- The mapping must account for: canvas zoom level, scroll offset, and widget position in the layout tree
- Unit test the conversion at multiple zoom levels and display resolutions (360 px, 768 px, 1024 px wide)
- **Do not proceed to Week 10 until coordinate conversion is accurate.** A painter built on top of a broken coordinate system will require a full rewrite.

**Week 10 — Anchor Point Painter**
- Tap to place an anchor point on the current frame
- Visual: crosshair rendered at the anchor position
- Optional snap-to-grid (configurable grid size)
- Anchor data stored per-frame, not globally shared
- Tap existing anchor to move it; long-press to remove

**Week 11 — Hitbox Painter**
- Drag to draw a rectangle hitbox on the current frame
- Minimum drag threshold of 8 px before rectangle starts (prevents accidental boxes from taps)
- Support three hitbox types with distinct colors:
  - `body` — green (bounding/pushbox)
  - `hurt` — blue (hurtbox)
  - `attack` — red (attackbox / damagebox)
- Select an existing hitbox to show resize handles at corners
- Drag handles to resize; drag center to move
- Delete button in toolbar removes selected hitbox

**Week 12 — Export Integration & Debugging Buffer**
- Integrate hitbox + anchor data into JSON export
- Verify that coordinates saved in JSON are accurate when reloaded in a fresh session
- Implement zoom mode: tap a magnifier button to enter 2×–4× zoom specifically for painter precision
- This week is also explicitly reserved as a debugging buffer for gesture edge cases — touch input on small targets almost always needs iteration

> **🔴 Gate Review 3:** Load the exported JSON into a Flutter Flame game. The collision bodies derived from the hitbox coordinates must match the visual frames in-game. "Looks correct in the painter UI" is not sufficient — verify with actual in-game collision detection.

---

### Phase 5 — Polish & Release (Weeks 13–14)
**Goal: Stable, performant, release-ready build.**

**Week 13 — Performance Profiling**
- Profile on a real device (not the emulator):
  - UI frame rate while animation preview is playing
  - Memory usage with 100 frames loaded simultaneously
  - End-to-end export time (import → pack → JSON + PNG write)
- Test on a low-end device (3 GB RAM) to verify no out-of-memory crashes
- Fix all bottlenecks found — performance problems found in testing are not backlog items

**Week 14 — Final Polish & Release Preparation**
- Comprehensive error handling: corrupt files, out of memory, unsupported format, storage full
- Undo / redo for painter operations (minimum 10 steps)
- Simple onboarding flow for first-time users (3-step tooltip walkthrough)
- Release build preparation: app icon, splash screen, store metadata
- Internal beta with 2–3 working game developers for real-world validation

---

## Risk Register

| Risk | Severity | Mitigation |
|---|---|---|
| `package:image` decode speed insufficient | High | Benchmark in Phase 1 Week 1. If decoding 100 frames exceeds 5 seconds, evaluate `flutter_image_compress` or a `dart:ffi` native wrapper. |
| Touch precision too low for small hitboxes | High | Mandatory zoom mode (Week 12) before the painter is considered complete. |
| OOM crash on 4096×4096 canvas | Medium | Implement streaming row-by-row write to disk. Do not buffer the full canvas in memory. |
| MaxRects edge cases with extreme aspect ratios | Medium | Dedicated test suite in Phase 1 before any dependent work begins. |
| Coordinate drift at different zoom levels | Medium | Unit-test coordinate mapping at all zoom levels before Week 10. |

---

## Developer Notes

### Memory Management
When processing large batches of high-resolution frames, `Uint8List` objects accumulate fast. Establish a strict lifecycle: allocate in Isolate → pass result to main isolate → dispose source data immediately. Never hold references to raw decoded images longer than necessary.

### CustomPainter Optimization
Do not redraw the entire canvas on every interaction. Use `RepaintBoundary` to isolate:
- The packed spritesheet background (redraws only on repack)
- The animation preview frame (redraws on FPS tick)
- The hitbox painter layer (redraws only on gesture)

Passing a `Listenable` to `CustomPainter`'s `repaint` parameter gives precise control over when each layer repaints.

### Coordinate System Contract
There are three coordinate spaces in this app:
1. **Screen space** — raw touch input in device pixels
2. **Canvas space** — position on the visible canvas after accounting for zoom and scroll
3. **Frame space** — relative position (0.0–1.0) within the logical frame

All persistent data is stored in **frame space**. Conversions between spaces must always go through explicit, unit-tested transformation functions — never ad-hoc inline math.

---

## Roadmap Beyond MVP

These features are intentionally excluded from the initial release to keep the MVP shippable. They are planned for subsequent releases in roughly this order:

1. **Godot 4 export preset** — `.tres` SpriteFrames resource with hitbox shapes
2. **Unity export preset** — `.png` + `.json` in Unity's Sprite Atlas format
3. **Multiple hitbox types per frame** — extend painter to support unlimited named types
4. **SHA-256 duplicate detection UI** — visual warning before packing, not just console log
5. **Cloud storage import** — iCloud Drive, Google Drive picker integration
6. **Stylus pressure support** — use Apple Pencil / S Pen pressure data for hitbox confidence weighting
7. **Multi-page auto-split UI** — visual navigation between overflow pages
8. **Frame copy/paste across animations** — reuse hitbox data between similar animations

---

## License

To be determined.

---

## Contributing

This project is in active pre-release development. Contribution guidelines will be published after the Phase 2 Gate Review is passed and the core export pipeline is stable.