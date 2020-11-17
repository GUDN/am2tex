import strformat, strutils
import sets
import options

import amsymbols

type
  Token* = object
    tokenType*: string
    value*: string

proc `$`*(token: Token): string = &"{token.value} ({token.tokenType} token)"

proc getNextDigits(stream: var string): string =
  if stream.len == 0: return
  var i = 0
  while stream[i].isDigit:
    result.add stream[i]
    inc i
    if i == stream.len:
      break
  stream.removePrefix(result)


proc getNextNumber(stream: var string): Option[Token] =
  if stream.len == 0: return
  let is_neg = stream[0] == '-'
  let sign = if is_neg: "-" else: ""
  if is_neg: stream.removePrefix('-')
  var a = getNextDigits(stream)
  if stream.len > 0 and stream[0] == '.':
    stream.removePrefix('.')
    var b = getNextDigits(stream)
    if a == "": a = "0"
    if b == "": b = "0"
    result = some(Token(tokenType: "number", value: &"{sign}{a}.{b}"))
  elif a != "":
    result = some(Token(tokenType: "number", value: &"{sign}{a}"))
  elif is_neg:
    stream = '-' & stream


proc getNextString(stream: var string): Option[Token] =
  if stream.len <= 1 or stream[0] != '"': return
  var
    str = ""
    i = 1
  while stream[i] != '"':
    str.add stream[i]
    inc i
    if i == stream.len: return
  stream.removePrefix(&"\"{str}\"")
  result = some(Token(tokenType: "string", value: str))


proc getNextSymbol(stream: var string): Option[Token] =
  if stream.len == 0: return
  elif stream.len == 1:
    if stream in AmSymbols:
      let tokenType = detectType(stream)
      if tokenType.isNone: return
      result = some(Token(tokenType: tokenType.get(), value: stream))
      stream = ""
  else:
    var
      symbol, resultSymbol = ""
      symbols = toHashSet(AmSymbols)
      i = 0
    while symbols.len > 0:
      if i == stream.len or stream[i] == ' ': break
      symbol.add stream[i]
      for s in symbols:
        if not s.startsWith(symbol): symbols.excl s
      if symbol in symbols: resultSymbol = symbol
      inc i
    if resultSymbol.len > 0:
      stream.removePrefix(resultSymbol)
      let tokenType = detectType(resultSymbol)
      if tokenType.isNone: return
      result = some(Token(tokenType: tokenType.get(), value: resultSymbol))


template tryGetNext(f: untyped, v: Option[Token]) =
  v = f
  if v.isSome:
    yield v.get
    continue


iterator toTokens*(stream: string): Token =
  var stream = stream.replace('\n', ' ').strip()
  while stream.len > 0:
    while stream.len > 0 and stream[0] == ' ':
      stream.removePrefix(' ')
    var token: Option[Token]
    tryGetNext(getNextNumber(stream), token)
    tryGetNext(getNextString(stream), token)
    tryGetNext(getNextSymbol(stream), token)
    break
