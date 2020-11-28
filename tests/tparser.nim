import unittest

import am2texpkg/parser

suite "parse simple expressions":
  test "1 + 2":
    let result = parse("1 + 2")
    check:
      result.nodeType == ntOperation
      result.value == "+"
      result.children.len == 2
      result.children[0].value == "1"
      result.children[1].value == "2"

  test "sin_(2)x":
    let result = parse("sin_(2)x")
    check:
      result.nodeType == ntFunction
      result.value == "sin"
      result.children.len == 3
      result.children[0].value == "2"
      result.children[1].nodeType == ntEmpty
      result.children[2].value == "x"

  test "f(x) = x + 1":
    let result = parse("f(x) = x + 1")
    check:
      result.nodeType == ntExpr
      result.children.len == 2
      result.children[0].value == "f"
    let addOperation = result.children[1]


suite "parse matrix expressions":
  test "[1, 2; 3, 4)":
    let result = parse("[1, 2; 3, 4)")
    check:
      result.nodeType == ntMatrix
      result.children.len == 4
      result.children[0].value == "["
      result.children[3].value == ")"
    let
      line1 = result.children[1]
      line2 = result.children[2]
    check:
      line1.nodeType == ntLine
      line1.children.len == 2
      line1.children[0].value == "1"
      line1.children[1].value == "2"
      line2.nodeType == ntLine
      line2.children.len == 2
      line2.children[0].value == "3"
      line2.children[1].value == "4"

  test "(1;(2;3))":
    let result = parse("(1;(2;3))")
    check:
      result.nodeType == ntMatrix
      result.children.len == 4
      result.children[0].value == "("
      result.children[3].value == ")"
    let
      line1 = result.children[1]
      line2 = result.children[2]
    check:
      line1.nodeType == ntLine
      line1.children.len == 1
      line1.children[0].value == "1"
      line2.nodeType == ntLine
      line2.children.len == 1
    let
      innerMatrix = line2.children[0]
    check:
      innerMatrix.nodeType == ntMatrix
      innerMatrix.children.len == 4
      innerMatrix.children[0].value == "("
      innerMatrix.children[3].value == ")"
    let
      innerLine1 = innerMatrix.children[1]
      innerLine2 = innerMatrix.children[2]
    check:
      innerLine1.nodeType == ntLine
      innerLine1.children.len == 1
      innerLine1.children[0].value == "2"
      innerLine2.nodeType == ntLine
      innerLine2.children.len == 1
      innerLine2.children[0].value == "3"

suite "parse interval expressions":
  test "[1:3/2]":
    let result = parse("[1:3/2]")
    check:
      result.nodeType == ntInterval
      result.children.len == 4
      result.children[0].value == "["
      result.children[3].value == "]"
      result.children[1].value == "1"
      result.children[2].nodeType == ntFraction
      result.children[2].children[0].value == "3"
      result.children[2].children[1].value == "2"

suite "parse complex expressions":
  test "sum_(i=1)^n i^3=((n(n+1))/2)^2":
    let result = parse("sum_(i=1)^n i^3=((n(n+1))/2)^2")
    check:
      result.nodeType == ntExpr
      result.children.len == 2
    let firstChild = result.children[0]
    check:
      firstChild.nodeType == ntSubsup
      firstChild.sub.value == "="
      firstChild.sub.children[0].value == "i"
      firstChild.sub.children[1].value == "1"
      firstChild.sup.value == "n"
      firstChild.base.value == "sum"
    let secondChild = result.children[1]
    check:
      secondChild.nodeType == ntOperation
      secondChild.value == "="
      secondChild.children.len == 2
      secondChild.children[0].nodeType == ntSubsup
      secondChild.children[0].base.value == "i"
      secondChild.children[0].sup.value == "3"
    let subchild = secondChild.children[1]
    check:
      subchild.nodeType == ntSubsup
      subchild.sup.value == "2"
      subchild.sub.nodeType == ntEmpty
      subchild.base.nodeType == ntBExpr
      subchild.base.children[1].nodeType == ntFraction
