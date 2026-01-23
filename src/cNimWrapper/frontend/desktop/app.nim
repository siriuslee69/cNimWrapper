# ================================================
# | cNimWrapper Bindr Desktop UI                           |
# |----------------------------------------------|
# | Minimal GTK4/owlkettle window for scaffolds. |
# ================================================

import std/os
import owlkettle
import ../../backend/core

const
  AppName = "cNimWrapper Bindr"

proc resolveStylesheetPath(): string =
  var
    t0: string = getAppDir()
    ts: seq[string] = @[
      "tungsten-themes/themes/gtk/theme.css",
      "tungsten-themes/src/themes/gtk/theme.css",
      "../tungsten-themes/themes/gtk/theme.css",
      "../tungsten-themes/src/themes/gtk/theme.css",
      "../../tungsten-themes/themes/gtk/theme.css",
      "../../tungsten-themes/src/themes/gtk/theme.css",
      joinPath(t0, "tungsten-themes", "themes", "gtk", "theme.css"),
      joinPath(t0, "tungsten-themes", "src", "themes", "gtk", "theme.css"),
      joinPath(t0, "..", "tungsten-themes", "themes", "gtk", "theme.css"),
      joinPath(t0, "..", "tungsten-themes", "src", "themes", "gtk", "theme.css"),
      joinPath(t0, "..", "..", "tungsten-themes", "themes", "gtk", "theme.css"),
      joinPath(t0, "..", "..", "tungsten-themes", "src", "themes", "gtk", "theme.css")
    ]
  for t in ts:
    if fileExists(t):
      return t
  result = ""

viewable DesktopApp:
  ctx: BackendContext = initBackend(AppName)

method view(s: DesktopAppState): Widget =
  ## s: desktop application state to render.
  var
    t0: string = describeBackend(s.ctx)
  result = gui:
    Window:
      title = AppName
      defaultSize = (960, 640)
      Grid:
        spacing = 12
        margin = 16
        Label {.x: 0, y: 0, hAlign: AlignStart.}:
          text = AppName
          xAlign = 0
        Label {.x: 0, y: 1, hAlign: AlignStart.}:
          text = t0
          xAlign = 0

when isMainModule:
  let stylesheetPath = resolveStylesheetPath()
  let stylesheets = if stylesheetPath.len > 0: @[loadStylesheet(stylesheetPath)] else: @[]
  brew(gui(DesktopApp()), stylesheets = stylesheets)
