# Device Scanner Mod

## 개요
- `config/scanner_config.lua`에 정의된 엔티티를 주기적으로 스캔하여 `global.device_snapshot`에 저장합니다.
- RCON에서 `remote.call("device_scanner", ...)`로 상태를 가져올 수 있습니다.

## 설정
```lua
return {
  update_interval_ticks = 300,
  targets = {
    {
      label = "offshore_pumps",
      entity_names = { "offshore-pump" },
      properties = { "position", "surface", "fluidbox" },
    },
    -- ...
  }
}
```
- `update_interval_ticks`: 몇 틱마다 자동 스캔할지 설정합니다.
- `targets`: 스캔 대상 그룹.
  - `label`: RCON에서 구분할 이름.
  - `entity_names`: 감시할 Factorio 엔티티 이름 목록.
  - `properties`: 추출할 속성 목록(`position`, `surface`, `health`, `energy`, `fluidbox`, `crafting_progress`, `status`, `power_production`, `electric_network_id`).

## Remote 인터페이스
- `device_scanner.get_snapshot()` – 마지막 스냅샷 반환.
- `device_scanner.refresh_snapshot()` – 즉시 스캔 후 결과 반환.
- `device_scanner.get_snapshot_json()` – 마지막 스냅샷을 JSON 문자열로 반환.
- `device_scanner.refresh_snapshot_json()` – 즉시 스캔 후 JSON 문자열 반환.
- `device_scanner.get_config()` – 현재 설정(config 파일) 반환.

스냅샷 구조 예시는 다음과 같습니다.
```lua
{
  tick = 123456,
  targets = {
    {
      label = "offshore_pumps",
      count = 2,
      entities = {
        { name = "offshore-pump", unit_number = 1, position = {x=0,y=0}, fluidbox = {...} },
        -- ...
      }
    }
  }
}
```
