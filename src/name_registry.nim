import tables
import debugger
import types

proc altNameForKind*(a: string, b: string): string =
  ## a: base Nim name
  ## b: symbol kind
  ## Returns a kind-specific suffix name when available.
  case b
  of "struct":
    result = a & "_str"
  of "typedef":
    result = a & "_tyd"
  else:
    result = ""

proc registerName*(s: var ParserState, a: string, b: string, c: string): string =
  ## s: parser state
  ## a: desired Nim name
  ## b: original C name
  ## c: name kind for stable mapping
  ## Reserves a unique Nim name, logging collisions when needed.
  var
    key: string = c & ":" & b
    name: string = ""
    alt: string = ""
    base: string = ""
    count: int = 0
  if s.nameMap.hasKey(key):
    result = s.nameMap[key]
    return
  if not s.usedNames.hasKey(a):
    s.usedNames[a] = 1
    s.nameMap[key] = a
    result = a
    return
  alt = altNameForKind(a, c)
  if alt.len > 0 and not s.usedNames.hasKey(alt):
    s.usedNames[alt] = 1
    s.nameMap[key] = alt
    recordCollision(s, a, b, alt)
    result = alt
    return
  base = a
  if alt.len > 0:
    base = alt
  if s.usedNames.hasKey(base):
    count = s.usedNames[base]
  else:
    count = 1
  name = base & "_" & $count
  while s.usedNames.hasKey(name):
    inc count
    name = base & "_" & $count
  s.usedNames[base] = count + 1
  s.usedNames[name] = 1
  s.nameMap[key] = name
  recordCollision(s, a, b, name)
  result = name
