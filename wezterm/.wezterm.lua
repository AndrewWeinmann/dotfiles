-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Detect platform
local is_windows = package.config:sub(1, 1) == '\\'

-- Configurable paths (overridden in .wezterm.local.lua)
local paths = {
    git_bash = 'C:\\Program Files\\Git\\bin\\bash.exe',
    git_bash_cwd = 'C:\\',
    wsl_start_dir = '/root/projects',
}

-- Load local overrides if they exist
local local_config = wezterm.config_dir .. '/.wezterm.local.lua'
local ok, local_overrides = pcall(dofile, local_config)
if ok and type(local_overrides) == 'table' then
    -- Override paths first
    if local_overrides.paths then
        for k, v in pairs(local_overrides.paths) do
            paths[k] = v
        end
    end
end

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

-- Key bindings
config.keys = {}

if is_windows then
    config.keys = {
        {
            key = 'b',
            mods = 'CTRL|SHIFT|ALT',
            action = wezterm.action.SpawnCommandInNewTab {
                args = { paths.git_bash, '-i', '-l' },
                cwd = paths.git_bash_cwd,
            },
        },
        {
            key = 'u',
            mods = 'CTRL|SHIFT|ALT',
            action = wezterm.action.SpawnCommandInNewTab {
                args = { 'wsl.exe', '--distribution', 'Ubuntu', '--cd', paths.wsl_start_dir },
            },
        },
    }
end

-- Apply any additional config overrides from local file
if ok and type(local_overrides) == 'function' then
    local_overrides(config, wezterm)
elseif ok and type(local_overrides) == 'table' then
    -- Merge non-paths config values
    for k, v in pairs(local_overrides) do
        if k ~= 'paths' then
            config[k] = v
        end
    end
end

-- Finally, return the configuration to wezterm:
return config
