import os

import am2texpkg/render

export render

when isMainModule:
  let amStream = if paramCount() > 0: paramStr(1) else: readAll(stdin)
  echo render(amStream)
