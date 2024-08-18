local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = 'iTerm2 Dark Background'
config.font_size = 23.0
config.adjust_window_size_when_changing_font_size = true
config.font = wezterm.font_with_fallback({
    { family = "Hack Nerd Font Mono" },
})
config.window_background_opacity = 0.3
config.text_background_opacity = 0.5
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- Dim inactive panes
config.inactive_pane_hsb = {
  saturation = 0.24,
  brightness = 0.5
}

config.leader = { key="s", mods="CTRL", timeout_milliseconds=1000 }
config.keys = {
    { key = 's', mods = 'LEADER|CTRL', action = act.SendKey { key = "a", mods = "CTRL"}},
    -- pane bindings
    { key = '%', mods = 'LEADER', action = act.SplitHorizontal { domain = "CurrentPaneDomain" }},
    { key = '_', mods = 'LEADER', action = act.SplitVertical { domain = "CurrentPaneDomain" }},
    { key = "LeftArrow",          mods = "ALT",      action = act.ActivatePaneDirection("Left") },
    { key = "DownArrow",          mods = "ALT",      action = act.ActivatePaneDirection("Down") },
    { key = "UpArrow",          mods = "ALT",      action = act.ActivatePaneDirection("Up") },
    { key = "RightArrow",          mods = "ALT",      action = act.ActivatePaneDirection("Right") },
     { key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
    -- tab bindings
    { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },
    {
        key = ",",
        mods = "LEADER",
        action = act.PromptInputLine {
            description = wezterm.format {
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "Renaming Tab Title...:" },
            },
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end)
        }
    },
    -- workspaces
    { key = "w", mods = "LEADER",       action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },

}
-- tab bindings
config.tab_bar_at_bottom = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = false

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#f7768e"
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "#7dcfff"
  end
  if window:leader_is_active() then
    stat = "LDR"
    stat_color = "#bb9af7"
  end

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      cwd = basename(cwd.file_path)
    else
      -- 20230712-072601-f4abf8fd or earlier version
      cwd = basename(cwd)
    end
  else
    cwd = ""
  end

  -- Current command
  local cmd = pane:get_foreground_process_name()
  -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
  cmd = cmd and basename(cmd) or ""

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Left status (left of the tab line)
  -- window:set_left_status(wezterm.format({
  --   { Foreground = { Color = stat_color } },
  --   { Text = "  " },
  --   { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
  --   { Text = " |" },
  -- }))

  -- Right status
  window:set_left_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
    { Text = " | " },
    { Foreground = { Color = "#e0af68" } },
    { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
    "ResetAttributes",
    -- { Text = " | " },
    -- { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
    { Text = "  " },
  }))
end)

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
