# This module parses the following C forms:
# typedef ExistingType Alias;
# typedef struct { ... } Alias;
# typedef struct Name { ... } Alias;
# typedef ReturnType (*FuncPtr)(...);
# It splits the typedef into:
# - full token collection up to ";" <- handled by collectTypedefTokens()
# - struct body detection and field splitting <- handled by isStructTypedef(), splitStructFields()
# - per-field type mapping <- handled by parseStructField(), mapTokensToNimType()
# - function pointer alias detection via "(*name)" <- handled by findFunctionPointerAlias()
# It emits Nim type aliases or objects, skipping function pointer fields <- handled by tryParseTypedef().
import src/cNimWrapper/name_mangle
import src/cNimWrapper/level1/level2/name_registry
import src/cNimWrapper/level1/level2/level3/struct_parser
import src/cNimWrapper/level1/level2/level3/type_mapper
import src/cNimWrapper/types
import src/cNimWrapper/level1/utils

type
  StructField* = object
    name*: string
    nimType*: string

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

proc findFunctionPointerAlias*(a: seq[Token]): string =
  ## a: typedef tokens
  ## Returns the alias name for function pointer typedefs like `(*name)`.
  var
    i: int = 0
    l: int = a.len
  while i + 2 < l:
    if a[i].text == "(" and a[i + 1].text == "*" and a[i + 2].kind == tkIdentifier:
      result = a[i + 2].text
      return
    inc i
  result = ""

proc hasTypeLine*(s: ParserState, b: string): bool =
  ## s: parser state
  ## b: type name
  ## Returns true when a type declaration for the name already exists.
  var
    i: int = s.output.len - 1
    needle: string = "type " & b & "*"
  if i < 0:
    result = false
    return
  while i >= 0:
    if s.output[i].len >= needle.len and s.output[i][0 ..< needle.len] == needle:
      result = true
      return
    dec i
  result = false

proc isStructTypedef*(a: seq[Token]): bool =
  ## a: typedef tokens
  ## Returns true when the typedef contains a struct body.
  var
    i: int = 0
    l: int = a.len
    sawStruct: bool = false
  while i < l:
    if a[i].text == "struct":
      sawStruct = true
    if a[i].text == "{" and sawStruct:
      result = true
      return
    inc i
  result = false

proc collectStructBodyTokens*(a: seq[Token]): seq[Token] =
  ## a: typedef tokens
  ## Returns the tokens contained inside the struct body braces.
  var
    items: seq[Token] = @[]
    i: int = 0
    l: int = a.len
    depth: int = 0
    started: bool = false
    sawStruct: bool = false
  while i < l:
    if a[i].text == "struct":
      sawStruct = true
    if a[i].text == "{" and sawStruct:
      started = true
      depth = 1
      inc i
      while i < l and depth > 0:
        if a[i].text == "{":
          inc depth
          items.add a[i]
        elif a[i].text == "}":
          dec depth
          if depth > 0:
            items.add a[i]
        else:
          items.add a[i]
        inc i
      break
    inc i
  if not started:
    result = @[]
  else:
    result = items

proc splitStructFields*(a: seq[Token]): seq[seq[Token]] =
  ## a: struct body tokens
  ## Splits struct body tokens into field token groups.
  var
    fields: seq[seq[Token]] = @[]
    current: seq[Token] = @[]
    i: int = 0
    l: int = a.len
    parenDepth: int = 0
    braceDepth: int = 0
    tok: Token
  while i < l:
    tok = a[i]
    if tok.text == "{":
      inc braceDepth
    elif tok.text == "}":
      if braceDepth > 0:
        dec braceDepth
    elif tok.text == "(":
      inc parenDepth
    elif tok.text == ")":
      if parenDepth > 0:
        dec parenDepth
    elif tok.text == ";" and braceDepth == 0 and parenDepth == 0:
      if current.len > 0:
        fields.add current
        current = @[]
      inc i
      continue
    current.add tok
    inc i
  if current.len > 0:
    fields.add current
  result = fields

proc parseStructField*(s: var ParserState, a: seq[Token]): StructField =
  ## s: parser state
  ## a: field tokens
  ## Parses a struct field into a name and Nim type, skipping function pointers.
  var
    fieldName: string = ""
    funcName: string = ""
    fieldType: string = ""
    info: StructField
  funcName = findFuncPtrFieldName(a)
  if funcName.len > 0:
    result = info
    return
  fieldName = fieldNameFromTokens(a)
  if fieldName.len == 0:
    result = info
    return
  fieldType = mapTokensToNimType(s, a, fieldName)
  info.name = fieldName
  info.nimType = fieldType
  result = info

proc collectStructFields*(s: var ParserState, a: seq[Token]): seq[StructField] =
  ## s: parser state
  ## a: typedef tokens
  ## Collects struct fields for a typedef struct declaration.
  var
    body: seq[Token] = collectStructBodyTokens(a)
    groups: seq[seq[Token]] = splitStructFields(body)
    items: seq[StructField] = @[]
    i: int = 0
    l: int = groups.len
    fieldInfo: StructField
  while i < l:
    fieldInfo = parseStructField(s, groups[i])
    if fieldInfo.name.len > 0 and fieldInfo.nimType.len > 0:
      items.add fieldInfo
    inc i
  result = items

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
    funcAlias: string = ""
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
    funcAlias = findFunctionPointerAlias(a)
    if funcAlias.len > 0:
      result = funcAlias
      return
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
    fields: seq[StructField] = @[]
    i: int = 0
    l: int = 0
    fieldName: string = ""
    fieldType: string = ""
    fieldPragma: string = ""
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
  if hasTypeLine(s, aliasName):
    result = true
    return
  namePragma = formatImportcPragma(aliasName, origName)
  if isStructTypedef(bodyTokens):
    fields = collectStructFields(s, bodyTokens)
    emitLine(s, "type " & aliasName & "*" & namePragma & " = object")
    l = fields.len
    if l == 0:
      emitLine(s, "  reserved*: array[1, byte]")
    else:
      while i < l:
        fieldName = sanitizeIdent(fields[i].name, "c_")
        fieldType = fields[i].nimType
        fieldPragma = formatImportcPragma(fieldName, fields[i].name)
        if fieldPragma.len > 0:
          emitLine(s, "  " & fieldName & "*" & fieldPragma & ": " & fieldType)
        else:
          emitLine(s, "  " & fieldName & "*: " & fieldType)
        inc i
  else:
    emitLine(s, "type " & aliasName & "*" & namePragma & " = distinct pointer")
    if s.config.emitComments and bodyText.len > 0:
      emitLine(s, "# typedef: " & bodyText)
  result = true
