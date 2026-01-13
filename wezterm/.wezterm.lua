-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Detect platform
local is_windows = package.config:sub(1,1) == '\\'

-- Default program
if is_windows then
    config.default_prog = { 'wsl.exe' }
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

-- Notifications
config.audible_bell = 'Disabled'
config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 0,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 0,
}

wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
    local title = tab.active_pane.title or ''

    -- Trim long titles so indicators stay visible
    if #title > 40 then
        title = title:sub(1, 37) .. '…'
    end

    local has_unseen_output = false
    for _, pane in ipairs(tab.panes) do
        if pane.has_unseen_output then
            has_unseen_output = true
            break
        end
    end

    if has_unseen_output then
        title = '● ' .. title
    end

    return title
end)

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
