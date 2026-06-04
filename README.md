# SpriteSheet Packer & Hitbox Painter

> A high-performance Flutter utility for independent game artists and developers — pack 2D animation frames into optimized sprite sheets and paint hitboxes directly on live animations, all offline, all on your tablet or phone.

---

## Overview

SpriteSheet Packer & Hitbox Painter is a mobile-first tool designed for the **mobile workstation workflow**. Instead of switching to a desktop to run TexturePacker or Unity's sprite editor, you do everything on your iPad or Android tablet: import frames, pack them, preview the animation, and paint collision boxes with your finger or stylus — then export a production-ready PNG + JSON pair straight to your game engine project.

It is built entirely offline. No server, no subscription, no telemetry. Your assets never leave your device.

---

## Key Features

- **2D Bin Packing Engine**: Automatically arranges dozens of PNG frames into a single texture using the **MaxRects algorithm**. Minimizes wasted whitespace to keep GPU memory usage low.
- **Alpha Trimming**: Scans and strips transparent border pixels, reducing atlas size by 30–50%.
- **Live Animation Preview**: Instantly preview your animation playing back from the packed frames (1–60 FPS).
- **Hitbox & Anchor Painter**: A touch-interactive layer to place anchor points and draw hitboxes directly on the animation. All coordinates are saved as relative values (0.0–1.0) making them resolution-independent.
- **Multi-Engine Export**: Produces a `spritesheet.png` and `spritesheet.json` readable by Flutter Flame (with Godot and Unity support coming soon).
- **Max Texture Size Control**: Set hard caps on output canvas size (2048x2048 or 4096x4096).
- **SHA-256 Duplicate Detection**: Hashes imported frames to prevent duplicate inclusions.

---

## Architecture & Tech Stack

Built on **Flutter** using **Clean Architecture**.

| Concern | Package |
|---|---|
| Framework | Flutter (Skia / Impeller) |
| State Management | `flutter_bloc` |
| Image Processing | `package:image` |
| File Import | `file_picker` |
| File Output | `path_provider` |
| Hashing | `crypto` (SHA-256) |
| JSON | `dart:convert` (built-in) |

All pixel-level operations (alpha trimming, bin packing, canvas stitching, PNG encoding) run in a Dart `Isolate` via `compute()` to prevent UI freezing.

---

## Installation & Build

1. Clone the repository:
```bash
git clone git@github.com:diascii/spritesheet.git
cd spritesheet
```
2. Get dependencies:
```bash
flutter pub get
```
3. Run the project:
```bash
flutter run
```

---

## License

This project is licensed under the [MIT License](LICENSE).