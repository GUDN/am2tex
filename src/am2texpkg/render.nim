import sequtils, strformat, strutils, re

import
  parser,
  tokenizer,
  amsymbols


let OptimizeRegex = re"(?:\\[a-zA-Z]+ [a-zA-Z]|\\text[a-z]{1,3}{[^}]+})"
const BaseTokens = [ttNumber, ttLetter]
const StringReplacements = [
  ("\\", r"\textbackslash"),
  ("%", r"\%"),
  ("#", r"\#"),
  ("&", r"\&"),
  ("_", r"\textunderscore"),
  ("---", r"\textemdash"),
  ("--", r"\textendash"),
  ("~", r"\textasciitilde"),
  ("{", r"\textbraceleft"),
  ("}", r"\textbraceright")
]


## Helper functions
proc fillTuple[T: tuple, V](input: openarray[V]): T =
  var i = 0
  for field in result.fields:
    field = input[i]
    inc i


proc prepareString(value: string): string =
  result = value.multiReplace(StringReplacements)


proc render(node: Node): string =
  case node.nodeType
  of ntEmpty: result = ""
  of ntToken:
    if node.tokenType in BaseTokens: result = node.value
    else: result = getTexSymbol(node.value)
  of ntLatex:
    result = "{" & node.value & "}"
  of ntString:
    let value = prepareString(node.value)
    result = r"\textrm{" & value & "}"
  of ntFString:
    let value = prepareString(node.value)
    result = getTexSymbol(node.font) & "{" & value & "}"
  of ntFraction:
    let (a, b) = fillTuple[(Node, Node), Node](node.children)
    result = r"\frac{" & render(a) & "}{" & render(b) & "}"
  of ntInterval:
    let (left, a, b, right) = fillTuple[(string, string, string, string), string](map(
      node.children,
      render
    ))
    result = &"{left} {a} \colon {b} {right}"
  of ntMatrix:
    var r = newSeq[string]()
    r.add [render(node.children[0]), r"\begin{matrix}"]
    for line in node.children[1..^2]:
      r.add render(line)
    r.add [r"\end{matrix}", render(node.children[^1])]
    result = join(r, " ")
  of ntLine:
    var r = newSeq[string]()
    for child in node.children:
      r.add [render(child), "&"]
    r[^1] = r"\\"
    result = join(r, " ")
  of ntFunction:
    let (sub, sup, argument) = fillTuple[(string, string, string), string](map(
      node.children,
      render
    ))
    result = getTexSymbol(node.value)
    if sub.len > 0: result &= "_{" & sub & "}"
    if sup.len > 0: result &= "^{" & sup & "}"
    if argument.len > 0: result &= "{" & argument & "}"
  of ntBinary:
    let (a, b) = fillTuple[(Node, Node), Node](node.children)
    case node.value
    of "color": result = r"\textcolor{" & a.value & "}{" & render(b) & "}"
    of "root": result = r"\sqrt[" & render(a) & "]{" & render(b) & "}"
    else: result = "\\" & node.value & "{" & render(a) & "}{" & render(b) & "}"
  of ntUnary:
    let a = render(node.children[0])
    case node.value
    of "not": result = r"\neg " & a
    of "abs": result = r"\left\lvert " & a & r"\right\rvert"
    of "floor": result = r"\left\lfloor " & a & r"\right\rfloor"
    of "ceil": result = r"\left\lceil " & a & r"\right\rceil"
    of "norm": result = r"\left\lVert " & a & r"\right\rVert"
    of "bar": result = r"\overline{" & a & "}"
    of "ul": result = r"\underline" & a & "}"
    of "ubrace": result = r"\underbrace{" & a & "}"
    of "obrace": result = r"\overbrace{" & a & "}"
    else: result = "\\" & node.value & "{" & a & "}"
  of ntBExpr:
    let (left, inner, right) = fillTuple[(string, string, string), string](map(
      node.children,
      render
    ))
    result = &"{left} {inner} {right}"
  of ntOperation:
    let (a, b) = fillTuple[(string, string), string](map(
      node.children,
      render
    ))
    return &"{a} {getTexSymbol(node.value)} {b}"
  of ntExpr: result = join(map(node.children, render), " ")
  of ntSubsup:
    let
      base = render(node.base)
      sub = render(node.sub)
      sup = render(node.sup)
    if sub == "" and sup == "": result = base
    else:
      result = "{" & base & "}"
      if sub.len > 0: result &= "_{" & sub & "}"
      if sup.len > 0: result &= "^{" & sup & "}"
  of ntBracket: result = getTexSymbol(node.value)


proc render*(stream: string, optimize = true): string =
  let root = parse(stream)
  result = render(root)
  if optimize:
    var mask = newSeq[int](result.len)
    var startIndex = 0
    while startIndex < result.len:
      let l = result.matchLen(OptimizeRegex, startIndex)
      if l > 0:
        for i in startIndex..<(startIndex + l): mask[i] = 1
        startIndex += l
      else: inc startIndex
    let resultCopy = result
    result = ""
    for i, v in mask:
      if v == 1: result &= resultCopy[i]
      elif resultCopy[i] != ' ': result &= resultCopy[i]
