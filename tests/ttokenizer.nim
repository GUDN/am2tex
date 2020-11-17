import unittest
import sequtils

import am2texpkg/tokenizer

template ttest(input: string, result: seq[Token]) =
  test input:
    let tokens = toSeq toTokens(input)
    check tokens == result

suite "test number tokenization":
  ttest("123 123 123", @[
    Token(tokenType: "number", value: "123"),
    Token(tokenType: "number", value: "123"),
    Token(tokenType: "number", value: "123"),
  ])

  ttest("-123 123 -123", @[
    Token(tokenType: "number", value: "-123"),
    Token(tokenType: "number", value: "123"),
    Token(tokenType: "number", value: "-123"),
  ])

  ttest("-12.3 .123 -123.", @[
    Token(tokenType: "number", value: "-12.3"),
    Token(tokenType: "number", value: "0.123"),
    Token(tokenType: "number", value: "-123.0"),
  ])

suite "test symbol tokenization":
  ttest("sumprodabc", @[
    Token(tokenType: "char", value: "sum"),
    Token(tokenType: "char", value: "prod"),
    Token(tokenType: "letter", value: "a"),
    Token(tokenType: "letter", value: "b"),
    Token(tokenType: "letter", value: "c"),
  ])

  ttest("/_ (/)abs", @[
    Token(tokenType: "char", value: "/_"),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "operator", value: "/"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "unary", value: "abs"),
  ])

suite "complex tokenization":
  ttest("f(x) = 2x + 1", @[
    Token(tokenType: "letter", value: "f"),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "letter", value: "x"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "operator", value: "="),
    Token(tokenType: "number", value: "2"),
    Token(tokenType: "letter", value: "x"),
    Token(tokenType: "operator", value: "+"),
    Token(tokenType: "number", value: "1"),
  ])

  ttest("sum_(i=1)^n i^3=((n(n+1))/2)^2", @[
    Token(tokenType: "char", value: "sum"),
    Token(tokenType: "operator", value: "_"),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "letter", value: "i"),
    Token(tokenType: "operator", value: "="),
    Token(tokenType: "number", value: "1"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "operator", value: "^"),
    Token(tokenType: "letter", value: "n"),
    Token(tokenType: "letter", value: "i"),
    Token(tokenType: "operator", value: "^"),
    Token(tokenType: "number", value: "3"),
    Token(tokenType: "operator", value: "="),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "letter", value: "n"),
    Token(tokenType: "left_bracket", value: "("),
    Token(tokenType: "letter", value: "n"),
    Token(tokenType: "operator", value: "+"),
    Token(tokenType: "number", value: "1"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "operator", value: "/"),
    Token(tokenType: "number", value: "2"),
    Token(tokenType: "right_bracket", value: ")"),
    Token(tokenType: "operator", value: "^"),
    Token(tokenType: "number", value: "2"),
  ])
