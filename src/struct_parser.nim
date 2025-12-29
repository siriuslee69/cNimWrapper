import name_mangle
import name_registry
import types
import utils

proc tryParseStruct*(s: var ParserState): bool =
  ## s: parser state
  ## Parses a C struct and emits a Nim object with placeholder fields.
  var
    mark: int = s.pos
    structName: string = "AnonymousStruct"
    structNameOrig: string = "AnonymousStruct"
    namePragma: string = ""
    fields: seq[string] = @[]
    currentField: string = ""
    fieldName: string = ""
    fieldPragma: string = ""
    tok: Token
    l: int = 0
    hasName: bool = false
  discard skipNewlines(s)
  if not matchText(s, "struct"):
    s.pos = mark
    result = false
    return
  if matchKind(s, tkIdentifier):
    tok = s.tokens[s.pos - 1]
    structNameOrig = tok.text
    structName = sanitizeIdent(structNameOrig, "c_")
    hasName = true
  if not hasName:
    structNameOrig = "AnonymousStruct_" & $mark
  structName = registerName(s, structName, structNameOrig, "struct")
  discard skipNewlines(s)
  if not matchText(s, "{"):
    s.pos = mark
    result = false
    return
  while not isAtEnd(s):
    if matchText(s, "}"):
      break
    tok = advanceToken(s)
    if tok.kind == tkIdentifier:
      currentField = tok.text
    if tok.text == ";":
      if currentField.len > 0:
        fields.add currentField
      currentField = ""
  discard skipNewlines(s)
  discard matchText(s, ";")
  if hasName:
    namePragma = formatImportcPragma(structName, structNameOrig)
  else:
    namePragma = ""
  emitLine(s, "type " & structName & "*" & namePragma & " = object")
  l = fields.len
  if l == 0:
    emitLine(s, "  reserved*: array[1, byte]")
  else:
    for i in 0 ..< l:
      fieldName = sanitizeIdent(fields[i], "c_")
      fieldPragma = formatImportcPragma(fieldName, fields[i])
      if fieldPragma.len > 0:
        emitLine(s, "  " & fieldName & "*" & fieldPragma & ": cint")
      else:
        emitLine(s, "  " & fieldName & "*: cint")
  result = true
