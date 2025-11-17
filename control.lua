local config = require("config.scanner_config")

local REMOTE_NAME = "device_scanner"
local current_interval
local function ensure_global_state()
  if not global then
    ---@diagnostic disable-next-line: cast-local-type
    global = {}
  end
end

local function safe_get(entity, getter)
  local ok, value = pcall(getter, entity)
  if ok then
    return value
  end
  return nil
end

local function read_properties(entity, properties)
  local data = {}

  for _, prop in ipairs(properties) do
    if prop == "energy" then
      data.energy = safe_get(entity, function(e)
        return e.energy
      end)
    elseif prop == "power_production" then
      data.power_production = safe_get(entity, function(e)
        return e.power_production
      end)
    elseif prop == "crafting_progress" then
      data.crafting_progress = safe_get(entity, function(e)
        return e.crafting_progress
      end)
    elseif prop == "status" then
      data.status = safe_get(entity, function(e)
        return e.status
      end)
    elseif prop == "recipe" then
      local recipe = safe_get(entity, function(e)
        return e.get_recipe and e.get_recipe()
      end)
      if recipe then
        data.recipe = recipe.name
      end
    elseif prop == "fluidbox" then
      local ok, count = pcall(function()
        return entity.fluidbox and #entity.fluidbox or 0
      end)
      if ok and count > 0 then
        local fluids = {}
        for i = 1, count do
          local fluid = safe_get(entity, function(e)
            return e.fluidbox[i]
          end)
          if fluid then
            fluids[#fluids + 1] = {
              name = fluid.name,
              amount = fluid.amount,
              temperature = fluid.temperature,
              index = i,
            }
          end
        end
        data.fluidbox = fluids
      end
    elseif prop == "steam_output" then
      local output = safe_get(entity, function(e)
        return e.fluidbox and e.fluidbox[2]
      end)
      if output then
        data.steam_output = {
          name = output.name,
          amount = output.amount,
          temperature = output.temperature,
        }
      end
    elseif prop == "fuel" then
      local burner = safe_get(entity, function(e)
        return e.burner
      end)
      if burner then
        data.fuel = {
          inventory = burner.inventory and burner.inventory.get_contents() or nil,
          currently_burning = burner.currently_burning and burner.currently_burning.name or nil,
          remaining_burning_fuel = burner.remaining_burning_fuel,
          heat = burner.heat,
        }
      end
    elseif prop == "steam" then
      local steam = safe_get(entity, function(e)
        return e.fluidbox and e.fluidbox[1]
      end)
      if steam then
        data.steam = {
          name = steam.name,
          amount = steam.amount,
          temperature = steam.temperature,
        }
      end
    elseif prop == "resource" then
      local resource = safe_get(entity, function(e)
        return e.mining_target
      end)
      if resource then
        data.resource = resource.name
      end
    end
  end

  data.unit_number = entity.unit_number
  data.name = entity.name

  return data
end

local function perform_scan()
  if not (game and game.surfaces) then
    return
  end

  ensure_global_state()
  global.device_snapshot = {
    tick = game.tick,
    targets = {},
  }

  for _, target in ipairs(config.targets or {}) do
    local target_entry = {
      label = target.label or "unknown",
      entities = {},
    }

    for _, force in pairs(game.forces) do
      for _, surface in pairs(game.surfaces) do
        for _, entity_name in ipairs(target.entity_names or {}) do
          local found = surface.find_entities_filtered({ name = entity_name, force = force })
          for _, entity in ipairs(found) do
            if entity.valid then
              target_entry.entities[#target_entry.entities + 1] = read_properties(entity, target.properties or {})
            end
          end
        end
      end
    end

    target_entry.count = #target_entry.entities
    global.device_snapshot.targets[#global.device_snapshot.targets + 1] = target_entry
  end
end

local function ensure_snapshot()
  ensure_global_state()
  if not global.device_snapshot then
    perform_scan()
  end
  return global.device_snapshot
end

local function escape_string(str)
  return (
    tostring(str)
      :gsub("\\", "\\\\")
      :gsub("\"", "\\\"")
      :gsub("\n", "\\n")
      :gsub("\r", "\\r")
      :gsub("\t", "\\t")
  )
end

local function is_array(tbl)
  local max_index = 0
  local count = 0

  for k, _ in pairs(tbl) do
    if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
      return false
    end
    if k > max_index then
      max_index = k
    end
    count = count + 1
  end

  if max_index > count then
    return false
  end

  return true, count
end

local function encode_json(value)
  local t = type(value)
  if t == "string" then
    return "\"" .. escape_string(value) .. "\""
  elseif t == "number" then
    return tostring(value)
  elseif t == "boolean" then
    return value and "true" or "false"
  elseif t == "nil" then
    return "null"
  elseif t == "table" then
    local array, count = is_array(value)
    if array then
      local items = {}
      for i = 1, count do
        items[#items + 1] = encode_json(value[i])
      end
      return "[" .. table.concat(items, ",") .. "]"
    else
      local entries = {}
      for k, v in pairs(value) do
        entries[#entries + 1] = "\"" .. escape_string(k) .. "\":" .. encode_json(v)
      end
      return "{" .. table.concat(entries, ",") .. "}"
    end
  end

  return "\"\""
end

local function fresh_snapshot()
  perform_scan()
  return ensure_snapshot()
end

local function fresh_snapshot_json_string()
  return encode_json(fresh_snapshot())
end

local function refresh_interval()
  local interval = config.update_interval_ticks or 60

  if current_interval then
    script.on_nth_tick(current_interval, nil)
  end

  current_interval = interval
  if interval and interval > 0 then
    script.on_nth_tick(interval, perform_scan)
  end
end

local function register_remote()
  if remote.interfaces[REMOTE_NAME] then
    return
  end

  remote.add_interface(REMOTE_NAME, {
    get_snapshot = function()
      return fresh_snapshot()
    end,
    refresh_snapshot = function()
      return fresh_snapshot()
    end,
    get_snapshot_json = function()
      return fresh_snapshot_json_string()
    end,
    refresh_snapshot_json = function()
      return fresh_snapshot_json_string()
    end,
    get_config = function()
      return config
    end,
  })
end

script.on_init(function()
  perform_scan()
  refresh_interval()
  register_remote()
end)

script.on_configuration_changed(function()
  perform_scan()
  refresh_interval()
  register_remote()
end)

register_remote()
