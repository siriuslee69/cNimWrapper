# This module parses the following C forms:
# #include <stdio.h>
# #include "local.h"
# It captures everything after "include" and emits a comment marker in the
# output stream <- handled by tryParseInclude().
import src/types
import src/level1/utils

proc tryParseInclude*(s: var ParserState): bool =
  ## s: parser state
  ## Parses C #include lines and emits a Nim comment marker.
  ## Example: `#include <stdio.h>` becomes `# c include: <stdio.h>`.
  var
    mark: int = s.pos
    bodyTokens: seq[Token] = @[]
    bodyText: string = ""
  discard skipNewlines(s)
  if not matchText(s, "#"):
    s.pos = mark
    result = false
    return
  if not matchText(s, "include"):
    s.pos = mark
    result = false
    return
  bodyTokens = collectUntilNewline(s)
  bodyText = tokensToText(bodyTokens)
  emitLine(s, "# c include: " & bodyText)
  result = true
