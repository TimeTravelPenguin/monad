// Writer monad.  M a = (log, a)
//
// Accumulates a log alongside the computed value. The log type must form a
// monoid: a default `empty` plus an associative `append`. The default instance
// uses arrays under concatenation; supply your own monoid via `make(empty:,
// append:)` for strings, numeric sums, etc.

/// Construct a Writer monad for a custom log monoid. Provide an `empty`
/// value and a binary associative `append`. Returns a bundle with the
/// monad instance plus a tailored `tell`.
///
/// ```example
/// #let w = writer.make(empty: "", append: (a, b) => a + b)
/// #let tell = w.tell
/// #bind(w.monad, tell("hello "), _ => bind(w.monad, tell("world"), _ => pure(w.monad, 42)))
/// ```
///
/// -> dictionary
#let make(
  /// The monoid identity. -> any
  empty: (),
  /// Associative combine. -> function
  append: (a, b) => a + b,
) = (
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

/// Default Writer bundle: log is an array combined by concatenation.
/// -> dictionary
#let default = make()

/// Default Writer monad instance (array log).
/// -> dictionary
#let monad = default.monad

/// Append a value to the default Writer's log.
///
/// ```example
/// #writer.tell(("event-1",))
/// ```
///
/// -> array
#let tell = default.tell

/// Run an action and additionally expose its produced log as part of the
/// value: result becomes `(log, (value, log))`.
///
/// -> array
#let listen(
  /// -> array
  m,
) = {
  let (log, v) = m
  (log, (v, log))
}

/// Apply a transformation to the accumulated log post-hoc, without
/// touching the value.
///
/// -> array
#let censor(
  /// `log -> log`. -> function
  f,
  /// -> array
  m,
) = {
  let (log, v) = m
  (f(log), v)
}

/// Identity `run` — a Writer value is already `(log, value)`.
/// -> array
#let run(
  /// -> array
  m,
) = m
