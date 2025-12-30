-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Detect platform
local is_windows = package.config:sub(1,1) == '\\'

-- Default program
if is_windows then
    config.default_prog = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l' }
else
    config.default_prog = { '/bin/bash', '-l' }
end

-- Font and color scheme
config.color_scheme = 'GitHub Dark'
config.font = wezterm.font('Monaspace Neon Var', { weight = 'Regular' })
config.font_size = 11

-- Window configuration
config.hide_tab_bar_if_only_one_tab = false
config.initial_cols = 120
config.initial_rows = 28
config.show_tab_index_in_tab_bar = false
config.window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0,
}

-- Performance
config.max_fps = 60
config.animation_fps = 60

-- Scrollback
config.scrollback_lines = 10000

-- Load local overrides if they exist
local local_config = wezterm.config_dir .. '/.wezterm.local.lua'
local ok, local_overrides = pcall(dofile, local_config)
if ok and type(local_overrides) == 'function' then
    -- Allow the local config to modify the config table
    local_overrides(config, wezterm)
elseif ok and type(local_overrides) == 'table' then
    -- Merge the returned table into config
    for k, v in pairs(local_overrides) do
        config[k] = v
    end
end

-- Finally, return the configuration to wezterm:
return config
