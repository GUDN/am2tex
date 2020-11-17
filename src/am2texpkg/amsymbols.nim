import tables
import strutils
import options

from sequtils import toSeq

type SymbolsEntry = tuple[symbolType: string, texValue: string]

proc parseSymbolsFile(content: string): Table[string, SymbolsEntry] =
  var currentType = ""
  for line in content.splitLines:
    if line.endsWith(" :="):
      currentType = line[0..^4]
    else:
      var entry = line.split(' ', 1)
      if entry.len == 1:
        entry.add ""
      result[entry[0]] = (currentType, entry[1])

const
  Symbols = parseSymbolsFile(staticRead"../../am.symbols")
  AmSymbols* = toSeq(Symbols.keys)

proc detectType*(symbol: string): Option[string] =
  if symbol in Symbols:
    result = some(Symbols[symbol][0])


proc getTexSymbol*(amSymbol: string): string =
  if amSymbol in Symbols:
    result = Symbols[amSymbol][1]
