# Device Scanner Mod

## What it does
- Scans configured entities on a fixed tick interval and caches the results in `global.device_snapshot`.
- Exposes the snapshot and active configuration through the `device_scanner` remote interface for use in scripts or RCON.
- Triggers a scan when the save initializes or when mod settings change, then continues on the configured interval.

## What gets scanned
- Properties this mod understands: `energy`, `power_production`, `crafting_progress`, `status`, `recipe`, `fluidbox`, `steam_output`, `fuel`, `steam`, `resource` (plus `name` and `unit_number` are always included).
- Unsupported property names in the config are ignored safely.
- Default targets from `config/scanner_config.lua`:
  - `offshore_pumps`: `fluidbox`
  - `steam_engines`: `energy`, `power_production`, `steam`
  - `assemblers`: `crafting_progress`, `status`, `recipe`
  - `electric_furnaces`: `energy`, `status`, `recipe`
  - `electric_mining_drills`: `energy`, `status`, `resource`
  - `boilers`: `fluidbox`, `energy`, `steam_output`, `fuel` 

## Applying the mod
1. Copy or zip this folder as `device-scanner_0.1.0` into your Factorio `mods` directory (works with Factorio 2.0; depends on base >= 1.1).
2. Launch Factorio and enable the mod in the Mods menu (servers: place it in `mods` and restart).
3. Optionally edit `config/scanner_config.lua` before starting the save to change the scan interval or targets.

## Configuration
```lua
return {
  update_interval_ticks = 60, -- ticks between automatic scans
  targets = {
    {
      label = "offshore_pumps",
      entity_names = { "offshore-pump" },
      properties = { "fluidbox" },
    },
    -- add more targets here
  }
}
```
- `update_interval_ticks`: How many ticks to wait between automatic scans; set to 0 or nil to disable periodic scanning.
- `targets`: Each entry is scanned for every force on every surface.
  - `label`: Name used in snapshots and RCON responses.
  - `entity_names`: Factorio entity prototypes to look for.
  - `properties`: List of property keys from the supported list above.

## Remote interface
Interface name: `device_scanner`
- `get_snapshot()` – Return the latest cached snapshot (runs a scan first if none exists).
- `refresh_snapshot()` – Run a scan immediately and return the snapshot.
- `get_snapshot_json()` – Return the cached snapshot as a JSON string.
- `refresh_snapshot_json()` – Run a scan and return a JSON string.
- `get_config()` – Return the active configuration table.

Examples (console or RCON):
- `/sc rcon.print(remote.call("device_scanner", "refresh_snapshot_json"))`
- `/sc game.write_file("device_snapshot.json", remote.call("device_scanner", "get_snapshot_json"))`

## Snapshot shape
```lua
{
  tick = 123456,
  targets = {
    {
      label = "offshore_pumps",
      count = 2,
      entities = {
        { name = "offshore-pump", unit_number = 1, fluidbox = { ... } },
        -- ...
      }
    }
  }
}
```
`entities` entries include only the properties requested for that target, plus `name` and `unit_number`.
