import name_mangle
import name_registry
import types
import utils

proc tryParseEnum*(s: var ParserState): bool =
  ## s: parser state
  ## Parses a C enum and emits a Nim enum type with placeholder members.
  var
    mark: int = s.pos
    enumName: string = "AnonymousEnum"
    enumNameOrig: string = "AnonymousEnum"
    namePragma: string = ""
    members: seq[string] = @[]
    currentName: string = ""
    memberName: string = ""
    memberPragma: string = ""
    tok: Token
    l: int = 0
    hasName: bool = false
  discard skipNewlines(s)
  if not matchText(s, "enum"):
    s.pos = mark
    result = false
    return
  if matchKind(s, tkIdentifier):
    tok = s.tokens[s.pos - 1]
    enumNameOrig = tok.text
    enumName = sanitizeIdent(enumNameOrig, "c_")
    hasName = true
  if not hasName:
    enumNameOrig = "AnonymousEnum_" & $mark
  enumName = registerName(s, enumName, enumNameOrig, "enum")
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
      currentName = tok.text
    if tok.text == ",":
      if currentName.len > 0:
        members.add currentName
      currentName = ""
  if currentName.len > 0:
    members.add currentName
  discard skipNewlines(s)
  discard matchText(s, ";")
  if hasName:
    namePragma = formatImportcPragma(enumName, enumNameOrig)
  else:
    namePragma = ""
  emitLine(s, "type " & enumName & "*" & namePragma & " = enum")
  l = members.len
  if l == 0:
    emitLine(s, "  enumPlaceholder")
  else:
    for i in 0 ..< l:
      memberName = sanitizeIdent(members[i], "c_")
      memberName = registerName(s, memberName, members[i], "enumMember")
      memberPragma = formatImportcPragma(memberName, members[i])
      if memberPragma.len > 0:
        emitLine(s, "  " & memberName & memberPragma)
      else:
        emitLine(s, "  " & memberName)
  result = true
