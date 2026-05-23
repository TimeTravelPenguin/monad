// Writer monad.  M a = (log, a)
//
// Accumulates a log alongside the computed value. The log type must form a
// monoid: a default `empty` plus an associative `append`. The default instance
// uses arrays under concatenation; supply your own monoid via `make(empty:,
// append:)` for strings, numeric sums, etc.

#let make(empty: (), append: (a, b) => a + b) = (
  monad: (
    pure: x => (empty, x),
    bind: (m, k) => {
      let (log1, v) = m
      let (log2, v2) = k(v)
      (append(log1, log2), v2)
    },
    fmap: (f, m) => (m.at(0), f(m.at(1))),
  ),
  tell: w => (w, none),
  empty: empty,
  append: append,
)

// Default Writer instance: log is an array, combined via concatenation.

#let default = make()

#let monad = default.monad

#let tell = default.tell

#let listen(m) = {
  let (log, v) = m
  (log, (v, log))
}

#let censor(f, m) = {
  let (log, v) = m
  (f(log), v)
}

#let run(m) = m
