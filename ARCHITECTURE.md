# Nail Glam architecture (MVC)

The app is Flutter + Flame. Code is organized as **Model / View / Controller** so new features have a clear home. Behavior is owned by Controllers; Views only draw and forward input.

## Layout

```
lib/
  main.dart              # App bootstrap + overlay wiring
  model/                 # Data, catalogs, config (no UI)
  view/                  # Flutter overlays + Flame visual components
    components/          # Flame scene art (salon, customer, workspace)
  controller/            # Game flow, nail-care logic, camera, audio
```

## Roles

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| **Model** | Persistable / static data and definitions | `PlayerProgress`, `CustomerRoster`, `SalonCatalog`, `NailCareCatalog`, `GameConfig`, asset paths |
| **View** | Render + collect taps; no game rules | `HomeOverlay`, `NailCareOverlay`, `SalonScene`, `CustomerComponent` |
| **Controller** | Decide what happens next | `NailGlamGame`, `NailCareController`, `PlayerProgressController`, `HomeController`, `CameraDirector`, `GameAudio` |

## Data flow

```
View  --(events)-->  Controller  --(read/write)-->  Model
View  <--(state)---  Controller
```

## Where to add things

- New customer / shop item / tool definition → **model/**
- New menu screen or HUD widget → **view/**
- New gameplay phase or rule → **controller/** (usually via `NailGlamGame` or `NailCareController`)

## Notes

- Flame components under `view/components/` are visual. Phase decisions stay in Controllers.
- `PlayerProgressController` is the entry point for shop buys and daily-login claims from Views.
- `HomeController` owns home-menu flow (Start, guest pick, daily-login prompt).
- `NailCareController` owns manicure HUD copy and stage presentation flags.
- `main.dart` only wires overlays to the game; it is not a Controller of gameplay itself.
