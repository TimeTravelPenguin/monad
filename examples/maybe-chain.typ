#import "../src/lib.typ": bind, pure, maybe

#let safe-div(a, b) = if b == 0 { maybe.nothing } else { maybe.just(a / b) }

#let result = bind(maybe.monad, safe-div(100, 5), x =>
  bind(maybe.monad, safe-div(x, 2), y =>
    pure(maybe.monad, y + 1)))

The chained computation gives #result.

#let bad = bind(maybe.monad, safe-div(100, 5), x =>
  bind(maybe.monad, safe-div(x, 0), y =>
    pure(maybe.monad, y + 1)))

Dividing by zero short-circuits to #bad.
