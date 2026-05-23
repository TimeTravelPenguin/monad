// Identity monad.  M a = a
//
// The trivial monad: `pure` is identity, `bind` is reverse application.
// Useful as a baseline for testing core combinators and as the "no-effect"
// case when composing monad transformers.

#let monad = (
  pure: x => x,
  bind: (m, f) => f(m),
  fmap: (f, m) => f(m),
  join: mm => mm,
)

#let run(m) = m
