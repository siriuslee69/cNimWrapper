import strutils
import name_mangle
import name_registry
import types
import utils

type ParamInfo* = object
  name*: string
  nimType*: string

proc sanitizeParamName*(a: string, b: int): string =
  ## a: original name
  ## b: parameter index
  ## Returns a Nim-safe parameter name, prefixing or using a fallback index.
  var
    name: string = stripEdgeUnderscores(a)
  if name.len == 0:
    result = "p" & $b
    return
  if isNimKeyword(name) or not isValidIdent(name):
    result = "p_" & name
  else:
    result = name

proc formatProcImportc*(a: string, b: string): string =
  ## a: Nim name
  ## b: original C name
  ## Returns a Nim importc pragma for a proc, using a name override when needed.
  if a == b:
    result = "{.importc.}"
  else:
    result = "{.importc: \"" & b & "\".}"

proc looksLikeFunctionPrototype*(s: ParserState): bool =
  ## s: parser state
  ## Checks for a function prototype shape: parens and semicolon without a body.
  var
    i: int = s.pos
    l: int = s.tokens.len
    tok: Token
    seenParen: bool = false
    seenClose: bool = false
    seenSemicolon: bool = false
    seenBrace: bool = false
  while i < l:
    tok = s.tokens[i]
    if tok.text == "{":
      seenBrace = true
      break
    if tok.text == "(":
      seenParen = true
    if tok.text == ")":
      if seenParen:
        seenClose = true
    if tok.text == ";":
      seenSemicolon = true
      break
    inc i
  result = seenParen and seenClose and seenSemicolon and not seenBrace

proc findFunctionName*(s: ParserState): string =
  ## s: parser state
  ## Finds the identifier immediately before the opening parenthesis.
  var
    i: int = s.pos
    l: int = s.tokens.len
    tok: Token
    lastIdent: string = ""
  while i < l:
    tok = s.tokens[i]
    if tok.text == "(":
      break
    if tok.kind == tkIdentifier:
      lastIdent = tok.text
    inc i
  result = lastIdent

proc paramNameFromTokens*(a: seq[Token]): string =
  ## a: parameter tokens
  ## Returns the last identifier, skipping "void" only signatures.
  var
    i: int = 0
    l: int = a.len
    tok: Token
    name: string = ""
  while i < l:
    tok = a[i]
    if tok.kind == tkIdentifier:
      name = tok.text
    inc i
  if name == "void" and l == 1:
    result = ""
  else:
    result = name

proc paramTypeFromTokens*(a: seq[Token]): string =
  ## a: parameter tokens
  ## Returns the Nim type for known C types, defaulting to pointer.
  var
    i: int = 0
    l: int = a.len
    tok: Token
    hasSizeT: bool = false
  while i < l:
    tok = a[i]
    if tok.kind == tkIdentifier and tok.text == "size_t":
      hasSizeT = true
    inc i
  if hasSizeT:
    result = "csize_t"
  else:
    result = "pointer"

proc paramInfoFromTokens*(a: seq[Token]): ParamInfo =
  ## a: parameter tokens
  ## Builds a ParamInfo with a name and Nim type.
  var
    info: ParamInfo
  info.name = paramNameFromTokens(a)
  info.nimType = paramTypeFromTokens(a)
  result = info

proc collectParamInfos*(s: ParserState): seq[ParamInfo] =
  ## s: parser state
  ## Collects parameter infos between parentheses.
  ## Example: `int foo(int a, size_t n)` yields `@["a: pointer", "n: csize_t"]`.
  var
    i: int = s.pos
    l: int = s.tokens.len
    tok: Token
    params: seq[ParamInfo] = @[]
    current: seq[Token] = @[]
    info: ParamInfo
    inParen: bool = false
  while i < l:
    tok = s.tokens[i]
    if not inParen:
      if tok.text == "(":
        inParen = true
      inc i
      continue
    if tok.text == ")":
      if current.len > 0:
        info = paramInfoFromTokens(current)
        if info.name.len > 0:
          params.add info
      break
    if tok.text == ",":
      info = paramInfoFromTokens(current)
      if info.name.len > 0:
        params.add info
      current = @[]
      inc i
      continue
    current.add tok
    inc i
  result = params

proc formatProcParams*(a: seq[ParamInfo]): string =
  ## a: parameter infos
  ## Maps parameter infos to a Nim proc signature stub.
  ## Example: `@["a: pointer", "n: csize_t"]` yields `"a: pointer, n: csize_t"`.
  var
    parts: seq[string] = @[]
    l: int = a.len
    name: string = ""
  for i in 0 ..< l:
    name = sanitizeParamName(a[i].name, i)
    if name.len > 0:
      parts.add name & ": " & a[i].nimType
  result = parts.join(", ")

proc tryParseFunction*(s: var ParserState): bool =
  ## s: parser state
  ## Parses a C function prototype and emits an importc Nim proc.
  ## Example: `int foo(void);` becomes `proc foo*(): cint {.importc.}`.
  var
    mark: int = s.pos
    name: string = ""
    origName: string = ""
    params: seq[ParamInfo] = @[]
    paramsText: string = ""
    pragmaText: string = ""
    tok: Token
    parenDepth: int = 0
  discard skipNewlines(s)
  tok = peekToken(s)
  if tok.text == "typedef":
    s.pos = mark
    result = false
    return
  if not looksLikeFunctionPrototype(s):
    s.pos = mark
    result = false
    return
  origName = findFunctionName(s)
  if origName.len == 0:
    s.pos = mark
    result = false
    return
  name = sanitizeIdent(origName, "c_")
  name = registerName(s, name, origName, "proc")
  params = collectParamInfos(s)
  paramsText = formatProcParams(params)
  pragmaText = formatProcImportc(name, origName)
  while not isAtEnd(s):
    tok = advanceToken(s)
    if tok.text == "(":
      inc parenDepth
    elif tok.text == ")":
      if parenDepth > 0:
        dec parenDepth
    elif tok.text == ";" and parenDepth == 0:
      break
  if paramsText.len == 0:
    emitLine(s, "proc " & name & "*(): cint " & pragmaText)
  else:
    emitLine(s, "proc " & name & "*(" & paramsText & "): cint " & pragmaText)
  result = true
