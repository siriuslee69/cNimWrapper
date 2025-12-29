import name_mangle
import name_registry
import types
import utils

proc findLastIdentifier*(a: seq[Token]): string =
  ## a: token list
  ## Returns the last identifier found in the token list.
  ## Example: tokens for `typedef struct Foo Bar;` return "Bar".
  var
    name: string = ""
    l: int = a.len
  for i in 0 ..< l:
    if a[i].kind == tkIdentifier:
      name = a[i].text
  result = name

proc collectTypedefTokens*(s: var ParserState): seq[Token] =
  ## s: parser state
  ## Collects typedef tokens up to the terminating semicolon, tracking braces.
  var
    items: seq[Token] = @[]
    tok: Token
    depth: int = 0
  while not isAtEnd(s):
    tok = advanceToken(s)
    if tok.text == "{":
      inc depth
      items.add tok
      continue
    if tok.text == "}":
      if depth > 0:
        dec depth
      items.add tok
      continue
    if tok.text == ";" and depth == 0:
      break
    items.add tok
  result = items

proc findTypedefAlias*(a: seq[Token]): string =
  ## a: typedef tokens
  ## Finds the alias name after a closing brace when present, otherwise uses last identifier.
  var
    i: int = 0
    l: int = a.len
    lastClose: int = -1
    name: string = ""
  while i < l:
    if a[i].text == "}":
      lastClose = i
    inc i
  if lastClose >= 0:
    i = lastClose + 1
    while i < l:
      if a[i].kind == tkIdentifier:
        name = a[i].text
      inc i
    result = name
  else:
    result = findLastIdentifier(a)

proc tryParseTypedef*(s: var ParserState): bool =
  ## s: parser state
  ## Parses a C typedef and emits a Nim type alias.
  var
    mark: int = s.pos
    bodyTokens: seq[Token] = @[]
    bodyText: string = ""
    aliasName: string = ""
    origName: string = ""
    namePragma: string = ""
  discard skipNewlines(s)
  if not matchText(s, "typedef"):
    s.pos = mark
    result = false
    return
  bodyTokens = collectTypedefTokens(s)
  bodyText = tokensToText(bodyTokens)
  origName = findTypedefAlias(bodyTokens)
  if origName.len == 0:
    emitLine(s, "# typedef: " & bodyText)
    result = true
    return
  aliasName = sanitizeIdent(origName, "c_")
  aliasName = registerName(s, aliasName, origName, "typedef")
  namePragma = formatImportcPragma(aliasName, origName)
  emitLine(s, "type " & aliasName & "*" & namePragma & " = distinct pointer")
  if s.config.emitComments and bodyText.len > 0:
    emitLine(s, "# typedef: " & bodyText)
  result = true
