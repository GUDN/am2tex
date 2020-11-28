# am2tex

A AsciiMath to Latex converter

## Brief overview
This tool convert AsciiMath (my dialect) to Latex. I focused on Katex and
tested with it.

## Usage
```
> am2tex '1+1/2'
1+\frac{1}{2}

> am2tex
1+1/2
^D
1+\frac{1}{2}
```

## AsciiMath dialect
My dialect has new matrix syntax, many symbol are operators. I tryed implement
soft converter, so many errors are ignored.
