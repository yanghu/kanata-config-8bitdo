-- ============================================================================
-- Hammerspoon module for 8BitDo Retro Keyboard Super Stick & Dual Super Buttons
--
-- Hardware mapping (configured once via 8BitDo Ultimate Software V2):
--   Super Stick: Up = F13, Left = F14, Down = F15, Right = F16
--   Super Buttons: A = F17, B = F18
--
-- Installation in ~/.hammerspoon/init.lua:
--   package.path = os.getenv("HOME") .. "/path/to/kanata-config-8bitdo/hammerspoon/?.lua;" .. package.path
--   require("8bitdo_super")
--   -- (Or symlink 8bitdo_super.lua into ~/.hammerspoon/ and just call `require("8bitdo_super")`)
-- ============================================================================

local M = {}

-- ============================================================================
-- USER CONFIGURATION — tweak shortcuts & app names here
-- ============================================================================
local CONFIG = {
  -- Long-press threshold (seconds):
  --   Button A (F17): tap (< threshold) = toggle dictation; hold (>= threshold) = push-to-talk
  --   Button B (F18): tap (< threshold) = Google Meet mute; hold (>= threshold) = raise/lower hand
  holdThreshold = 0.35,

  -- Antigravity voice dictation shortcut (default: Ctrl+M)
  antigravity = {
    appNames = { "Antigravity", "Google Antigravity" },
    voiceMods = { "ctrl" },
    voiceKey  = "m",
  },

  -- Claude Code CLI terminals (after running `/voice`, holding Space records)
  claudeTerminals = {
    "Terminal", "iTerm2", "Ghostty", "WezTerm", "Warp", "Alacritty", "kitty",
  },

  -- Claude Desktop app (tries Accessibility API mic button click first)
  claudeDesktopNames = { "Claude" },

  -- Fallback global voice / AI shortcut when in any other app (e.g. Gemini for Mac)
  -- >>> Set this to your actual Gemini for Mac voice/launch hotkey! <<<
  -- Example: Option+Space -> mods = { "alt" }, key = "space"
  geminiFallback = {
    mods = { "alt" },
    key  = "space",
    -- Set true if Gemini for Mac uses toggle (press once to start, press again to stop)
    -- so holding Button A >= holdThreshold will automatically press again on release.
    isToggle = false,
  },

  -- Browser used for Google Meet ("Google Chrome", "Arc", "Brave Browser", "Chromium")
  meetBrowser = "Google Chrome",

  -- Set true if you enabled Chrome -> View -> Developer -> "Allow JavaScript from Apple Events"
  -- (enables silent background Meet control with zero window focus flicker).
  -- When false, briefly bounces to the Meet tab, sends native Cmd+D / Ctrl+Cmd+H, and restores focus.
  meetUseAppleEventsJS = false,

  -- Super Stick (F13 Up / F14 Left / F15 Down / F16 Right)
  -- Default: macOS Spaces & Mission Control
  -- Alternative ideas: Browser/IDE tabs ({ "cmd", "shift" }, "[" / "]") or PageUp/PageDown
  stick = {
    up    = { mods = { "ctrl" }, key = "up" },    -- F13: Mission Control
    left  = { mods = { "ctrl" }, key = "left" },  -- F14: Previous Desktop Space
    down  = { mods = { "ctrl" }, key = "down" },  -- F15: App Exposé
    right = { mods = { "ctrl" }, key = "right" }, -- F16: Next Desktop Space
  },
}

-- ============================================================================
-- Helpers
-- ============================================================================
local function contains(list, val)
  if not val then return false end
  for _, item in ipairs(list) do
    if item == val then return true end
  end
  return false
end

local function toast(msg)
  hs.alert.closeAll(0)
  hs.alert.show(msg, 0.9)
end

-- Recursively search macOS Accessibility tree for a mic / dictation button (used for Claude Desktop)
local function findMicButton(element, depth)
  if not element or depth > 12 then return nil end
  local role = element:attributeValue("AXRole")
  if role == "AXButton" then
    local fields = {
      element:attributeValue("AXDescription"),
      element:attributeValue("AXTitle"),
      element:attributeValue("AXHelp"),
    }
    for _, text in ipairs(fields) do
      if type(text) == "string" then
        local lower = text:lower()
        if lower:find("dictat") or lower:find("mic") or lower:find("voice")
          or text:find("语音") or text:find("听写") or text:find("麦克风") then
          return element
        end
      end
    end
  end
  local children = element:attributeValue("AXChildren")
  if children then
    for _, child in ipairs(children) do
      local found = findMicButton(child, depth + 1)
      if found then return found end
    end
  end
  return nil
end

local function clickClaudeMicButton(app)
  local axApp = hs.axuielement.applicationElement(app)
  local win = axApp and axApp:attributeValue("AXFocusedWindow")
  local btn = findMicButton(win, 0)
  if btn then
    btn:performAction("AXPress")
    return true
  end
  return false
end

-- ============================================================================
-- Button A (F17): App-aware Voice Input (Antigravity / Claude / Gemini fallback)
--   - Antigravity:   tap = toggle Ctrl+M; hold >= 350ms = push-to-talk (press+release Ctrl+M)
--   - Claude CLI:    hold = hold Space (for Claude Code `/voice`)
--   - Claude App:    clicks UI mic button via Accessibility (fallback: Gemini hotkey)
--   - Other apps:    triggers CONFIG.geminiFallback (Gemini for Mac)
-- ============================================================================
local f17State = {
  pressedAt = 0,
  mode = nil, -- "antigravity" | "claude_cli" | "claude_app" | "gemini"
}

local function onF17Press()
  f17State.pressedAt = hs.timer.secondsSinceEpoch()
  local app = hs.application.frontmostApplication()
  local name = app and app:name() or ""

  if contains(CONFIG.antigravity.appNames, name) then
    f17State.mode = "antigravity"
    hs.eventtap.keyStroke(CONFIG.antigravity.voiceMods, CONFIG.antigravity.voiceKey, 0)
    toast("🎙️ Antigravity Voice")
  elseif contains(CONFIG.claudeTerminals, name) then
    f17State.mode = "claude_cli"
    hs.eventtap.event.newKeyEvent("space", true):post()
    toast("🎙️ Claude Code PTT")
  elseif contains(CONFIG.claudeDesktopNames, name) then
    f17State.mode = "claude_app"
    if clickClaudeMicButton(app) then
      toast("🎙️ Claude Voice")
    else
      -- Fallback to Gemini for Mac if mic button isn't exposed in AX tree
      f17State.mode = "gemini"
      hs.eventtap.keyStroke(CONFIG.geminiFallback.mods, CONFIG.geminiFallback.key, 0)
      toast("🎙️ Gemini Voice")
    end
  else
    f17State.mode = "gemini"
    hs.eventtap.keyStroke(CONFIG.geminiFallback.mods, CONFIG.geminiFallback.key, 0)
    toast("🎙️ Gemini Voice")
  end
end

local function onF17Release()
  local held = hs.timer.secondsSinceEpoch() - f17State.pressedAt
  local mode = f17State.mode
  f17State.mode = nil

  if mode == "claude_cli" then
    hs.eventtap.event.newKeyEvent("space", false):post()
  elseif mode == "antigravity" and held >= CONFIG.holdThreshold then
    -- Push-to-talk release: send Ctrl+M again to finish dictation
    hs.eventtap.keyStroke(CONFIG.antigravity.voiceMods, CONFIG.antigravity.voiceKey, 0)
  elseif mode == "claude_app" and held >= CONFIG.holdThreshold then
    local app = hs.application.frontmostApplication()
    if app then clickClaudeMicButton(app) end
  elseif mode == "gemini" and CONFIG.geminiFallback.isToggle and held >= CONFIG.holdThreshold then
    hs.eventtap.keyStroke(CONFIG.geminiFallback.mods, CONFIG.geminiFallback.key, 0)
  end
end

hs.hotkey.bind({}, "f17", onF17Press, onF17Release)

-- ============================================================================
-- Button B (F18): Background Google Meet Controller
--   - Tap (< 350ms):  Toggle Mute       (Cmd + D)
--   - Hold (>= 350ms): Toggle Raise Hand (Ctrl + Cmd + H)
-- Works even when Chrome/Meet is in the background while coding!
-- ============================================================================
local function triggerMeetAction(action)
  local browser = CONFIG.meetBrowser
  local prevApp = hs.application.frontmostApplication()

  if CONFIG.meetUseAppleEventsJS then
    -- Silent background JS click (requires Chrome: View -> Developer -> Allow JavaScript from Apple Events)
    local selector = action == "mute"
      and 'button[aria-label*="microphone" i], button[aria-label*="麦克风"]'
      or  'button[aria-label*="hand" i], button[aria-label*="举手"], button[aria-label*="放下手"]'

    local script = string.format([[
      tell application "%s"
        repeat with w in windows
          repeat with t in tabs of w
            if URL of t contains "meet.google.com" then
              execute t javascript "var b = document.querySelector('%s'); if (b) b.click();"
              return "ok"
            end if
          end repeat
        end repeat
      end tell
      return "not_found"
    ]], browser, selector)

    local ok, res = hs.osascript.applescript(script)
    if ok and res == "ok" then
      toast(action == "mute" and "🔇 Meet: Toggle Mute" or "✋ Meet: Toggle Hand")
    else
      toast("⚠️ No Google Meet tab found")
    end
    return
  end

  -- Default zero-config path: locate the Meet tab, switch to it if needed, send native shortcut, restore
  local findAndFocusScript = string.format([[
    tell application "%s"
      if (count of windows) is 0 then return "not_found"
      set curWinId to id of front window
      set curTabIdx to active tab index of front window
      set curUrl to URL of active tab of front window
      if curUrl contains "meet.google.com" then
        return "already_active"
      end if
      repeat with w in windows
        set i to 1
        repeat with t in tabs of w
          if URL of t contains "meet.google.com" then
            set active tab index of w to i
            set index of w to 1
            activate
            return "switched:" & (curWinId as string) & ":" & (curTabIdx as string)
          end if
          set i to i + 1
        end repeat
      end repeat
    end tell
    return "not_found"
  ]], browser)

  local ok, res = hs.osascript.applescript(findAndFocusScript)
  if not ok or res == "not_found" then
    toast("⚠️ No Google Meet tab found")
    return
  end

  local function sendMeetKeys()
    if action == "mute" then
      hs.eventtap.keyStroke({ "cmd" }, "d", 0)
      toast("🔇 Meet: Toggle Mute")
    else
      hs.eventtap.keyStroke({ "ctrl", "cmd" }, "h", 0)
      toast("✋ Meet: Toggle Hand")
    end
  end

  -- Fast path: browser is frontmost AND active tab is already Google Meet
  if res == "already_active" and prevApp and prevApp:name() == browser then
    sendMeetKeys()
    return
  end

  -- If browser was in background on the Meet tab, activate briefly
  if res == "already_active" then
    hs.application.launchOrFocus(browser)
  end

  local prevWinId, prevTabIdx = res:match("^switched:(%d+):(%d+)$")

  hs.timer.doAfter(0.06, function()
    sendMeetKeys()
    hs.timer.doAfter(0.06, function()
      if prevWinId and prevTabIdx and prevApp and prevApp:name() == browser then
        local restoreTabScript = string.format([[
          tell application "%s"
            repeat with w in windows
              if (id of w as string) is "%s" then
                set active tab index of w to %s
                set index of w to 1
                exit repeat
              end if
            end repeat
          end tell
        ]], browser, prevWinId, prevTabIdx)
        hs.osascript.applescript(restoreTabScript)
      elseif prevApp then
        prevApp:activate()
      end
    end)
  end)
end

local f18Timer = nil
local f18Held = false

local function onF18Press()
  f18Held = false
  if f18Timer then f18Timer:stop() end
  f18Timer = hs.timer.doAfter(CONFIG.holdThreshold, function()
    f18Held = true
    triggerMeetAction("hand")
  end)
end

local function onF18Release()
  if f18Timer then
    f18Timer:stop()
    f18Timer = nil
  end
  if not f18Held then
    triggerMeetAction("mute")
  end
end

hs.hotkey.bind({}, "f18", onF18Press, onF18Release)

-- ============================================================================
-- Super Stick (F13 Up / F14 Left / F15 Down / F16 Right)
-- ============================================================================
local function bindStick(key, cfg)
  hs.hotkey.bind({}, key, function()
    hs.eventtap.keyStroke(cfg.mods, cfg.key, 0)
  end)
end

bindStick("f13", CONFIG.stick.up)
bindStick("f14", CONFIG.stick.left)
bindStick("f15", CONFIG.stick.down)
bindStick("f16", CONFIG.stick.right)

-- Utility: uncomment temporarily to print the exact frontmost app name in Hammerspoon Console
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "i", function()
--   local app = hs.application.frontmostApplication()
--   hs.alert.show("App: " .. (app and app:name() or "nil"))
--   print("Frontmost app:", app and app:name(), app and app:bundleID())
-- end)

return M
