import unittest
import sequtils

import am2texpkg/tokenizer

template ttest(input: string, result: seq[Token]) =
  test input:
    let tokens = toSeq toTokens(input)
    check tokens == result

suite "test number tokenization":
  ttest("123 123 123", @[
    Token(tokenType: ttNumber, value: "123"),
    Token(tokenType: ttNumber, value: "123"),
    Token(tokenType: ttNumber, value: "123"),
  ])

  ttest("-123 123 -123", @[
    Token(tokenType: ttNumber, value: "-123"),
    Token(tokenType: ttNumber, value: "123"),
    Token(tokenType: ttNumber, value: "-123"),
  ])

  ttest("-12.3 .123 -123.", @[
    Token(tokenType: ttNumber, value: "-12.3"),
    Token(tokenType: ttNumber, value: "0.123"),
    Token(tokenType: ttNumber, value: "-123.0"),
  ])

suite "test symbol tokenization":
  ttest("sumprodabc", @[
    Token(tokenType: ttChar, value: "sum"),
    Token(tokenType: ttChar, value: "prod"),
    Token(tokenType: ttLetter, value: "a"),
    Token(tokenType: ttLetter, value: "b"),
    Token(tokenType: ttLetter, value: "c"),
  ])

  ttest("/_ (/)abs", @[
    Token(tokenType: ttChar, value: "/_"),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttOperator, value: "/"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttUnary, value: "abs"),
  ])

suite "complex tokenization":
  ttest("f(x) = 2x + 1", @[
    Token(tokenType: ttLetter, value: "f"),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttLetter, value: "x"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttOperator, value: "="),
    Token(tokenType: ttNumber, value: "2"),
    Token(tokenType: ttLetter, value: "x"),
    Token(tokenType: ttOperator, value: "+"),
    Token(tokenType: ttNumber, value: "1"),
  ])

  ttest("sum_(i=1)^n i^3=((n(n+1))/2)^2", @[
    Token(tokenType: ttChar, value: "sum"),
    Token(tokenType: ttOperator, value: "_"),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttLetter, value: "i"),
    Token(tokenType: ttOperator, value: "="),
    Token(tokenType: ttNumber, value: "1"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttOperator, value: "^"),
    Token(tokenType: ttLetter, value: "n"),
    Token(tokenType: ttLetter, value: "i"),
    Token(tokenType: ttOperator, value: "^"),
    Token(tokenType: ttNumber, value: "3"),
    Token(tokenType: ttOperator, value: "="),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttLetter, value: "n"),
    Token(tokenType: ttLeft_bracket, value: "("),
    Token(tokenType: ttLetter, value: "n"),
    Token(tokenType: ttOperator, value: "+"),
    Token(tokenType: ttNumber, value: "1"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttOperator, value: "/"),
    Token(tokenType: ttNumber, value: "2"),
    Token(tokenType: ttRight_bracket, value: ")"),
    Token(tokenType: ttOperator, value: "^"),
    Token(tokenType: ttNumber, value: "2"),
  ])
