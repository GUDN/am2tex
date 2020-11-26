import os

import am2texpkg/parser

when isMainModule:
  let amStream = if paramCount() > 0: paramStr(1) else: readAll(stdin)
  let result = parse(amStream)
  echo result
