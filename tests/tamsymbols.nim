import unittest
import options

import am2texpkg/amsymbols

suite "test detectType":
  test "alpha is char":
    check detectType("alpha").get("") == "char"

  test "abs is unary":
    check detectType("abs").get("") == "unary"

  test "number is none":
    check detectType("123").isNone

suite "test getTexSymbol":
  test r"alpha in tex is \alpha":
    check getTexSymbol("alpha") == r"\alpha"

  test "number is empty":
    check getTexSymbol("123") == ""
