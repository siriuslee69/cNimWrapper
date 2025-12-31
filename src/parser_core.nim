# This module drives parsing over the token stream.
# It runs registered parsers for constructs like #define, enum, struct, typedef,
# and function prototypes <- handled by parseAll().
# When no parser matches, it emits "# unparsed: ..." and records debug info
# <- handled by parseAll().
import debugger
import types
import utils

type ParserRegistry* = object
  parsers*: seq[ParserProc]

proc initRegistry*(): ParserRegistry =
  ## returns an empty parser registry
  ## Initializes a registry with no parsers registered.
  var
    reg: ParserRegistry = ParserRegistry(parsers: @[])
  result = reg

proc addParser*(a: var ParserRegistry, b: ParserProc) =
  ## a: parser registry
  ## b: parser function
  ## Adds a parser to the registry in execution order.
  a.parsers.add b

proc parseAll*(s: var ParserState, b: ParserRegistry) =
  ## s: parser state
  ## b: parser registry
  ## Runs all registered parsers over the token stream.
  ## When no parser matches, emits a fallback "# unparsed:" line.
  var
    matched: bool = false
    i: int = 0
    l: int = b.parsers.len
    tok: Token
  if l == 0:
    while not isAtEnd(s):
      tok = advanceToken(s)
      if tok.kind != tkNewline and tok.text.len > 0:
        emitLine(s, "# unparsed: " & tok.text)
    return
  while not isAtEnd(s):
    discard skipNewlines(s)
    matched = false
    i = 0
    while i < l:
      if b.parsers[i](s):
        matched = true
        break
      inc i
    if not matched:
      tok = advanceToken(s)
      if tok.kind != tkNewline and tok.text.len > 0:
        emitLine(s, "# unparsed: " & tok.text)
        recordDebug(s, "unparsed", "no_parser", tok, tok.text)
