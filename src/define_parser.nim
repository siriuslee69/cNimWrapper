import strutils
import cast_utils
import name_mangle
import name_registry
import types
import utils

proc replaceConstLine*(s: var ParserState, b: string, c: string): bool =
  ## s: parser state
  ## b: const name
  ## c: new const line text
  ## Replaces the last emitted const with the same name and returns true when replaced.
  var
    i: int = s.output.len - 1
    needle: string = "const " & b & "*"
  if i < 0:
    result = false
    return
  while i >= 0:
    if s.output[i].startsWith(needle):
      s.output[i] = c
      result = true
      return
    dec i
  result = false

proc hasTemplateLine*(s: ParserState, b: string): bool =
  ## s: parser state
  ## b: template name
  ## Returns true when a template line for the name already exists.
  var
    i: int = s.output.len - 1
    needle: string = "template " & b & "*"
  if i < 0:
    result = false
    return
  while i >= 0:
    if s.output[i].startsWith(needle):
      result = true
      return
    dec i
  result = false

proc formatTemplateParams*(a: seq[string]): string =
  ## a: parameter names
  ## Formats names into a Nim template parameter list.
  ## Example: `@["x", "y"]` becomes `"x: untyped, y: untyped"`.
  var
    parts: seq[string] = @[]
    l: int = a.len
  for i in 0 ..< l:
    if a[i].len > 0:
      parts.add a[i] & ": untyped"
  result = parts.join(", ")

proc tryParseDefine*(s: var ParserState): bool =
  ## s: parser state
  ## Parses C #define directives into Nim consts or templates.
  ## Example: `#define FOO 1` becomes `const FOO* = 1`.
  var
    mark: int = s.pos
    nameTok: Token
    origName: string = ""
    name: string = ""
    bodyTokens: seq[Token] = @[]
    bodyText: string = ""
    constLine: string = ""
    params: seq[string] = @[]
    paramsText: string = ""
    paramName: string = ""
    tok: Token
    isFunc: bool = false
  discard skipNewlines(s)
  if not matchText(s, "#"):
    s.pos = mark
    result = false
    return
  if not matchText(s, "define"):
    s.pos = mark
    result = false
    return
  if not matchKind(s, tkIdentifier):
    s.pos = mark
    result = false
    return
  nameTok = s.tokens[s.pos - 1]
  origName = nameTok.text
  name = sanitizeIdent(origName, "c_")
  if matchText(s, "("):
    isFunc = true
    while not isAtEnd(s):
      if matchText(s, ")"):
        break
      if matchKind(s, tkIdentifier):
        tok = s.tokens[s.pos - 1]
        paramName = sanitizeIdent(tok.text, "p_")
        params.add paramName
      else:
        discard advanceToken(s)
  bodyTokens = collectUntilNewline(s)
  if not isFunc:
    bodyTokens = stripLeadingCastTokens(bodyTokens)
  bodyText = tokensToText(bodyTokens)
  if isFunc:
    name = registerName(s, name, origName, "template")
    if hasTemplateLine(s, name):
      result = true
      return
    paramsText = formatTemplateParams(params)
    if paramsText.len == 0:
      emitLine(s, "template " & name & "*(): untyped =")
    else:
      emitLine(s, "template " & name & "*(" & paramsText & "): untyped =")
    if s.config.emitComments and bodyText.len > 0:
      emitLine(s, "  ## C macro: " & bodyText)
    emitLine(s, "  discard")
  else:
    name = registerName(s, name, origName, "const")
    if bodyText.len == 0:
      bodyText = "0"
    constLine = "const " & name & "* = " & bodyText
    if not replaceConstLine(s, name, constLine):
      emitLine(s, constLine)
  result = true
