proc isValidIdent*(a: string): bool =
  ## a: identifier text
  ## Returns true when the name matches a basic Nim identifier shape.
  var
    i: int = 0
    l: int = a.len
    ch: char
  if l == 0:
    result = false
    return
  ch = a[0]
  if not ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or ch == '_'):
    result = false
    return
  i = 1
  while i < l:
    ch = a[i]
    if not ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or
      (ch >= '0' and ch <= '9') or ch == '_'):
      result = false
      return
    inc i
  result = true

proc isNimKeyword*(a: string): bool =
  ## a: identifier text
  ## Returns true when the name is a Nim keyword that cannot be used as an identifier.
  case a
  of "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept",
     "const", "continue", "converter", "defer", "discard", "distinct", "div",
     "do", "elif", "else", "end", "enum", "except", "export", "finally", "for",
     "from", "func", "if", "import", "in", "include", "interface", "is", "isnot",
     "iterator", "let", "macro", "method", "mixin", "mod", "nil", "not", "notin",
     "object", "of", "or", "out", "proc", "ptr", "raise", "ref", "return", "shl",
     "shr", "static", "template", "try", "tuple", "type", "using", "var", "when",
     "while", "with", "without", "xor", "yield":
    result = true
  else:
    result = false

proc stripEdgeUnderscores*(a: string): string =
  ## a: identifier text
  ## Returns the identifier with leading and trailing underscores removed.
  var
    i: int = 0
    j: int = 0
    l: int = a.len
  if l == 0:
    result = ""
    return
  i = 0
  while i < l and a[i] == '_':
    inc i
  if i >= l:
    result = ""
    return
  j = l - 1
  while j >= i and a[j] == '_':
    dec j
  if j < i:
    result = ""
  else:
    result = a[i .. j]

proc sanitizeIdent*(a: string, b: string): string =
  ## a: original identifier
  ## b: prefix to apply when the name is invalid or reserved
  ## Returns a Nim-safe identifier after stripping edge underscores.
  var
    name: string = stripEdgeUnderscores(a)
  if name.len == 0:
    result = b & "unnamed"
    return
  if isNimKeyword(name) or not isValidIdent(name):
    result = b & name
  else:
    result = name

proc formatImportcPragma*(a: string, b: string): string =
  ## a: Nim name
  ## b: original C name
  ## Returns an importc pragma for renamed identifiers, otherwise empty.
  if a == b:
    result = ""
  else:
    result = " {.importc: \"" & b & "\".}"
