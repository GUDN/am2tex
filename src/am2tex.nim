import os

import am2texpkg/tokenizer

when isMainModule:
  let amStream = if paramCount() > 0: paramStr(1) else: readAll(stdin)
  for token in toTokens(amStream):
    echo token
