return {
  update_interval_ticks = 60,
  targets = {
    {
      label = "offshore_pumps",
      entity_names = { "offshore-pump" },
      properties = { "fluidbox" },
    },
    {
      label = "steam_engines",
      entity_names = { "steam-engine" },
      properties = { "energy", "power_production", "steam" },
    },
    {
      label = "assemblers",
      entity_names = { "assembling-machine-3" },
      properties = { "crafting_progress", "status", "recipe" },
    },
    {
      label = "electric_furnaces",
      entity_names = { "electric-furnace" },
      properties = { "energy", "status", "temperature", "recipe" },
    },
    {
      label = "electric_mining_drills",
      entity_names = { "electric-mining-drill" },
      properties = { "energy", "mining_progress", "status", "resource" },
    },
    {
      label = "boilers",
      entity_names = { "boiler" },
      properties = { "temperature", "fluidbox", "energy", "steam_output", "fuel" },
    },
  }
}
