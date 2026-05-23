#import "../src/lib.typ": bind, option, pure

#let safe-div(a, b) = if b == 0 { option.nothing } else { option.some(a / b) }

#let result = bind(option.monad, safe-div(100, 5), x => bind(
  option.monad,
  safe-div(x, 2),
  y => pure(option.monad, y + 1),
))

The chained computation gives #result.

#let bad = bind(option.monad, safe-div(100, 5), x => bind(
  option.monad,
  safe-div(x, 0),
  y => pure(option.monad, y + 1),
))

Dividing by zero short-circuits to #bad.
