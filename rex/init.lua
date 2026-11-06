-- Rex config, migrated from zellij (~/.config/zellij/config.kdl) and
-- iTerm2 (profiles Dark-v2 / Dark-v2-Browser). tmux, Herdr and Ghostty
-- had no key bindings to migrate.

-- Runs an action, then leaves every mode (zellij's SwitchToMode "Normal").
rex.action{
  name  = "then_normal",
  title = "Run an action and return to normal mode",
  args  = { action = "string", args = "object?" },
  run   = function(ctx, args)
    rex.client.queue(args.action, args.args or {})
    rex.client.queue("client.mode.exit_all")
  end,
}

-- Modes the user stays in until leaving them, as in zellij.
local modes = { "resize", "pane", "move", "tab", "tmux" }
for _, m in ipairs(modes) do
  rex.mode(m, { exclusive = true })
end

---------------------------------------------------------------------------
-- zellij: keys shared by normal mode and the other modes
---------------------------------------------------------------------------

-- Keys that enter a mode (shared_except "<mode>" "locked"), config.kdl:148,174-192
local enter = {
  ["ctrl+g"] = "locked",
  ["ctrl+p"] = "pane",
  ["ctrl+n"] = "resize",
  ["ctrl+t"] = "tab",
  ["ctrl+h"] = "move",
  ["`"]      = "tmux",
}
for key, name in pairs(enter) do
  rex.bind(key, "client.mode.enter", { name = name })
  for _, m in ipairs(modes) do
    if m == name then
      -- The key that enters a mode leaves it again (config.kdl:11,24,41,50).
      rex.bind(m .. "/" .. key, "client.mode.exit_all")
    else
      rex.bind(m .. "/" .. key, "client.mode.enter", { name = name })
    end
  end
end

-- shared_except "locked", config.kdl:150-156 (alt+arrows stay with Rex, by decision)
local shared = {
  { "alt+n", "pane.split",      { direction = "auto" } },
  { "alt+i", "client.tab.move", { direction = "backward" } },
  { "alt+o", "client.tab.move", { direction = "forward" } },
  { "alt+h", "pane.focus",      { direction = "left" } },
  { "alt+l", "pane.focus",      { direction = "right" } },
  { "alt+j", "pane.focus",      { direction = "down" } },
  { "alt+k", "pane.focus",      { direction = "up" } },
}
for _, b in ipairs(shared) do
  rex.bind(b[1], b[2], b[3])
  for _, m in ipairs(modes) do
    rex.bind(m .. "/" .. b[1], b[2], b[3])
  end
end

-- shared_except "normal" "locked", config.kdl:171
for _, m in ipairs(modes) do
  rex.bind(m .. "/enter", "client.mode.exit_all")
  rex.bind(m .. "/esc", "client.mode.exit_all")
end

---------------------------------------------------------------------------
-- zellij: locked mode passes every key to the program, config.kdl:7-9
---------------------------------------------------------------------------
rex.bind("locked/ctrl+g", "client.mode.exit_all")
for key, name in pairs(enter) do
  if name ~= "locked" then
    rex.bind("locked/" .. key, "pane.send_key", { key = key })
  end
end
for _, b in ipairs(shared) do
  rex.bind("locked/" .. b[1], "pane.send_key", { key = b[1] })
end

---------------------------------------------------------------------------
-- zellij: resize mode, config.kdl:10-22
---------------------------------------------------------------------------
for _, d in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
  rex.bind("resize/" .. d[1], "pane.resize", { direction = d[2] })
  rex.bind("resize/" .. d[2], "pane.resize", { direction = d[2] })
end

---------------------------------------------------------------------------
-- zellij: pane mode, config.kdl:23-39
---------------------------------------------------------------------------
for _, d in ipairs({ { "h", "left" }, { "l", "right" }, { "j", "down" }, { "k", "up" } }) do
  rex.bind("pane/" .. d[1], "pane.focus", { direction = d[2] })
  rex.bind("pane/" .. d[2], "pane.focus", { direction = d[2] })
end
rex.bind("pane/p", "pane.focus_next")
rex.bind("pane/n", "then_normal", { action = "pane.split", args = { direction = "auto" } })
rex.bind("pane/d", "then_normal", { action = "pane.split", args = { direction = "down" } })
rex.bind("pane/r", "then_normal", { action = "pane.split", args = { direction = "right" } })
rex.bind("pane/x", "then_normal", { action = "pane.close" })
rex.bind("pane/f", "then_normal", { action = "pane.zoom" })
rex.bind("pane/c", "then_normal", { action = "pane.rename" })

---------------------------------------------------------------------------
-- zellij: move mode, config.kdl:40-48
---------------------------------------------------------------------------
for _, d in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
  rex.bind("move/" .. d[1], "pane.move", { direction = d[2] })
  rex.bind("move/" .. d[2], "pane.move", { direction = d[2] })
end

---------------------------------------------------------------------------
-- zellij: tab mode, config.kdl:49-70
---------------------------------------------------------------------------
rex.bind("tab/r", "then_normal", { action = "client.tab.rename" })
for _, key in ipairs({ "h", "left", "up", "k" }) do
  rex.bind("tab/" .. key, "client.tab.previous")
end
for _, key in ipairs({ "l", "right", "down", "j" }) do
  rex.bind("tab/" .. key, "client.tab.next")
end
rex.bind("tab/n", "then_normal", { action = "client.tab.new" })
rex.bind("tab/x", "then_normal", { action = "client.tab.close" })
rex.bind("tab/b", "then_normal", { action = "pane.move_to_new_tab" })
for i = 1, 9 do
  rex.bind("tab/" .. i, "then_normal", { action = "client.tab.goto", args = { index = i } })
end

---------------------------------------------------------------------------
-- zellij: tmux mode, config.kdl:124-146
---------------------------------------------------------------------------
rex.bind("tmux/ctrl+b", "then_normal", { action = "pane.send_key", args = { key = "ctrl+b" } })
rex.bind("tmux/shift+'", "then_normal", { action = "pane.split", args = { direction = "down" } })
rex.bind("tmux/shift+5", "then_normal", { action = "pane.split", args = { direction = "right" } })
rex.bind("tmux/z", "then_normal", { action = "pane.zoom" })
rex.bind("tmux/c", "then_normal", { action = "client.tab.new" })
rex.bind("tmux/,", "then_normal", { action = "client.tab.rename" })
rex.bind("tmux/p", "then_normal", { action = "client.tab.previous" })
rex.bind("tmux/n", "then_normal", { action = "client.tab.next" })
for _, d in ipairs({ { "h", "left" }, { "l", "right" }, { "j", "down" }, { "k", "up" } }) do
  rex.bind("tmux/" .. d[1], "then_normal", { action = "pane.focus", args = { direction = d[2] } })
  rex.bind("tmux/" .. d[2], "then_normal", { action = "pane.focus", args = { direction = d[2] } })
end
rex.bind("tmux/o", "pane.focus_next")
rex.bind("tmux/x", "then_normal", { action = "pane.close" })

---------------------------------------------------------------------------
-- iTerm2: single-byte hex codes (Keyboard Map of Dark-v2 / Dark-v2-Browser)
---------------------------------------------------------------------------
rex.bind("ctrl+2", "pane.send_key", { key = "ctrl+space" })     -- 0x32-0x40000 → 0x00
rex.bind("ctrl+3", "pane.send_key", { key = "esc" })            -- 0x33-0x40000 → 0x1b
rex.bind("ctrl+4", "pane.send_key", { key = "ctrl+\\" })        -- 0x34-0x40000 → 0x1c
rex.bind("ctrl+5", "pane.send_key", { key = "ctrl+]" })         -- 0x35-0x40000 → 0x1d
rex.bind("ctrl+6", "pane.send_key", { key = "ctrl+shift+6" })   -- 0x36-0x40000 → 0x1e
rex.bind("ctrl+7", "pane.send_key", { key = "ctrl+shift+-" })   -- 0x37-0x40000 → 0x1f
rex.bind("ctrl+8", "pane.send_key", { key = "backspace" })      -- 0x38-0x40000 → 0x7f
rex.bind("ctrl+-", "pane.send_key", { key = "ctrl+shift+-" })   -- 0x2d-0x40000 → 0x1f
