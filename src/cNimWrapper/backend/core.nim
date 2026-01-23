# ==================================================
# | cNimWrapper Bindr Backend Core                           |
# |------------------------------------------------|
# | Core status and placeholder service scaffold.  |
# ==================================================


type
  BackendContext* = object
    name*: string
    status*: string

proc initBackend*(n: string): BackendContext =
  ## n: application name to tag the backend context.
  var c: BackendContext
  c.name = n
  c.status = "ready"
  result = c

proc describeBackend*(c: BackendContext): string =
  ## c: backend context to describe state for logs.
  var t: string = "Backend " & c.name & " is " & c.status
  result = t
