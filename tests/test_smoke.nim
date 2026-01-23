# =========================================
# | cNimWrapper Bindr Smoke Tests                   |
# |---------------------------------------|
# | Minimal compile/runtime checks.       |
# =========================================

import std/[unittest, strutils]
import ../src/cNimWrapper/backend/core

suite "cNimWrapper Bindr scaffold":
  test "backend description":
    let c = initBackend("cNimWrapper Bindr")
    check describeBackend(c).contains("cNimWrapper Bindr")

