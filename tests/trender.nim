import unittest

import am2texpkg/render


suite "render simple expressions":
  test "1+1/2":
    check render("1+1/2") == r"1+\frac{1}{2}"

  test "sin^2x + cos^2x = 1":
    check render("sin^2x + cos^2x = 1") == r"\sin^{2}{x}+\cos^{2}{x}=1"

suite "render complex expressions":
  test "sum_(i=1)^n i^3=((n(n+1))/2)^2":
    check render("sum_(i=1)^n i^3=((n(n+1))/2)^2") ==
      r"{\sum}_{i=1}^{n}{i}^{3}={\left(\frac{n\left(n+1\right)}{2}\right)}^{2}"

suite "render latex literal":
  test r"1 + $\frac{1}{2}$":
    check render(r"1 + $\frac{1}{2}$") == r"1+{\frac{1}{2}}"

  test "1$&=$2":
    check render("1$&=$2") == "1{&=}2"
