# =========================================
# | cNimWrapper Bindr CLI Entrypoint               |
# |---------------------------------------|
# | Prints backend status for automation. |
# =========================================

import ../../backend/core

when isMainModule:
  let c = initBackend("cNimWrapper Bindr")
  echo describeBackend(c)
