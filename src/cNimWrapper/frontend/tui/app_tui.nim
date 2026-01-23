# =========================================
# | cNimWrapper Bindr TUI Entrypoint               |
# |---------------------------------------|
# | Minimal illwill-based terminal UI.    |
# =========================================

import illwill
import ../../backend/core

const
  AppName = "cNimWrapper Bindr"

proc runApp() =
  var
    t0: TerminalBuffer
    t1: string
  t0 = newTerminalBuffer(80, 24)
  t0.clear()
  t1 = describeBackend(initBackend(AppName))
  t0.write(2, 1, AppName)
  t0.write(2, 3, t1)
  display(t0)
  discard getKey()

when isMainModule:
  initScreen()
  defer: deinitScreen()
  setCursorVisibility(false)
  runApp()
