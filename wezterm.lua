local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ======================
-- OS DETECTION
-- ======================
local triple = wezterm.target_triple
local IS_WINDOWS = triple:find("windows") ~= nil
local IS_MAC = triple:find("apple") ~= nil
local IS_LINUX = (not IS_WINDOWS) and (not IS_MAC)

-- ======================
-- THEME
-- ======================
config.color_scheme = "Monokai Remastered"

-- ======================
-- WINDOW (title bar dark integrata)
-- ======================
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Windows"
config.integrated_title_button_color = "Auto"

config.window_padding = {
  left = 8,
  right = 14,
  top = 6,
  bottom = 3, -- un po' più basso come volevi
}

-- ======================
-- TAB BAR
-- ======================
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true

-- ======================
-- SCROLL
-- ======================
config.enable_scroll_bar = true
config.scrollback_lines = 10000

-- ======================
-- FONT / LOOK
-- ======================
config.font_size = 11.0
config.line_height = 1.05
config.font = wezterm.font("Hack Nerd Font")

-- ======================
-- DEFAULT SHELL (per-OS)
-- ======================
if IS_WINDOWS then
  -- BusyBox solo su Windows
  config.default_prog = { "C:\\opt\\busybox64u.exe", "sh", "-l" }
elseif IS_MAC then
  -- macOS: zsh
  config.default_prog = { "/bin/zsh", "-l" }
else
  -- Linux: bash
  config.default_prog = { "/bin/bash", "-l" }
end

-- ======================
-- WSL DOMAINS (solo Windows)
-- ======================
if IS_WINDOWS then
  config.wsl_domains = wezterm.default_wsl_domains()
end

-- ======================
-- KEYBINDINGS
-- ======================
config.keys = {
  -- Ctrl+W → chiude il tab corrente
  { key = "w", mods = "CTRL", action = act.CloseCurrentTab { confirm = false } },

  -- Ctrl+Q → chiude tutta l'app
  { key = "q", mods = "CTRL", action = act.QuitApplication },

  -- Ctrl+T → sempre tab "locale" (DefaultDomain)
  -- Su Windows = BusyBox, su Linux/macOS = default_prog (bash/zsh)
  { key = "t", mods = "CTRL", action = act.SpawnTab("DefaultDomain") },
}

-- Ctrl+Shift+D → WSL:DDEV SOLO su Windows
if IS_WINDOWS then
  table.insert(config.keys, {
    key = "d",
    mods = "CTRL|SHIFT",
    action = act.SpawnTab { DomainName = "WSL:DDEV" },
  })
end

-- ======================
-- MOUSE: select-to-copy + right-click copy/paste (stile Windows Terminal)
-- ======================
config.mouse_bindings = {
  -- quando rilasci selezione col sinistro -> copia su Clipboard
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
  },

  -- destro: se c'è selezione -> copy + clear, altrimenti paste
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local sel = window:get_selection_text_for_pane(pane)
      if sel ~= "" then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.PasteFrom("Clipboard"), pane)
      end
    end),
  },
}

-- ======================
-- PERFORMANCE / FEEL (leggero)
-- ======================
config.animation_fps = 1
config.max_fps = 60

-- ======================
-- TAB TITLE: icone unicode (no Nerd Font richiesto)
-- ======================
wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane

  local title = "Local"
  local icon = "🪟 "

  if pane.domain_name and pane.domain_name:match("^WSL:") then
    title = pane.domain_name:gsub("^WSL:", "")
    icon = "🐧 "
  else
    -- Su macOS/Linux non ha senso "Windows icon": scegliamo qualcosa di neutro
    if IS_MAC then
      icon = "🍎 "
      title = "Local"
    elseif IS_LINUX then
      icon = "🐧 "
      title = "Local"
    end
  end

  return { { Text = " " .. icon .. title .. " " } }
end)

return config
