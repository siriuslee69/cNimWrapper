import src/types

proc isTypeToken*(a: Token): bool =
  ## a: token to inspect
  ## Returns true when the token looks like part of a C type name.
  if a.kind == tkIdentifier:
    result = true
  elif a.kind == tkSymbol and a.text == "*":
    result = true
  else:
    result = false

proc stripLeadingCastTokens*(a: seq[Token]): seq[Token] =
  ## a: token list
  ## Strips a leading C-style cast like `(long)` or `((long)0)` when detected.
  var
    l: int = a.len
    i: int = 0
    endPos: int = -1
  if l == 0:
    result = a
    return
  if a[0].text != "(":
    result = a
    return
  i = 0
  while i < l and a[i].text == "(":
    endPos = i + 1
    while endPos < l:
      if a[endPos].text == ")":
        break
      if not isTypeToken(a[endPos]):
        endPos = -1
        break
      inc endPos
    if endPos > i:
      if endPos >= 0 and endPos < l and a[endPos].text == ")":
        result = @[]
        if i > 0:
          result.add a[0 ..< i]
        if endPos + 1 < l:
          result.add a[endPos + 1 ..< l]
        return
    inc i
  result = a
