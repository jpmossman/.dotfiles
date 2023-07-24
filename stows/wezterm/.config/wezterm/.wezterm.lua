-- Pull in the wezterm API
local wezterm = require 'wezterm'
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Config choices
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 12
config.color_scheme = 'OneHalfDark'
-- config.window_background_opacity = 0.95
config.enable_scroll_bar = true
config.enable_tab_bar = false

-- Disable font ligatures
config.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}

-- OS specific options
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  -- Windows
  config.default_prog = { 'wsl', '--cd', '~' }
elseif wezterm.target_triple == 'x86_64-apple-darwin' then
  -- Mac (Intel)
elseif wezterm.target_triple == 'aarch64-apple-darwin' then
  -- Mac (Apple Silicon)
elseif wezterm.target_triple == 'x86_64-unknown-linux-gnu' then
  -- Linux
end


-- Return the configuration to wezterm
return config
