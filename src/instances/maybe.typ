// Maybe monad.  M a = just(a) | nothing
//
// Models computations that can fail without an error value. `bind` short-
// circuits on `nothing` — once a chain produces nothing, the rest of the
// chain is skipped.

/// Wrap a value as `just`.
///
/// ```example
/// #just(42)
/// ```
///
/// -> dictionary
#let just(
  /// -> any
  x,
) = (tag: "just", value: x)

/// The "nothing" sentinel: a tagged dict, not Typst's `none`, so it is
/// safely distinguishable as a monadic value.
///
/// -> dictionary
#let nothing = (tag: "nothing")

/// Test whether a Maybe value is `just`.
/// -> bool
#let is-just(
  /// -> dictionary
  m,
) = m.tag == "just"

/// Test whether a Maybe value is `nothing`.
/// -> bool
#let is-nothing(
  /// -> dictionary
  m,
) = m.tag == "nothing"

/// Maybe monad instance. `bind` short-circuits on `nothing`: once a chain
/// produces nothing, every subsequent step is skipped.
///
/// ```example
/// #bind(maybe.monad, maybe.just(3), x => maybe.just(x * 2))
/// #bind(maybe.monad, maybe.nothing, x => maybe.just(x * 2))
/// ```
///
/// -> dictionary
#let monad = (
  pure: just,
  bind: (m, f) => if m.tag == "just" { f(m.value) } else { m },
  fmap: (f, m) => if m.tag == "just" { just(f(m.value)) } else { m },
)

/// Extract the inner value or return a default for `nothing`.
///
/// ```example
/// #from-maybe(0, maybe.just(7))
/// #from-maybe(0, maybe.nothing)
/// ```
///
/// -> any
#let from-maybe(
  /// -> any
  default,
  /// -> dictionary
  m,
) = if m.tag == "just" { m.value } else { default }

/// Eliminator: apply `f` to the inner value, or fall back to `default`.
///
/// -> any
#let maybe(
  /// -> any
  default,
  /// -> function
  f,
  /// -> dictionary
  m,
) = if m.tag == "just" { f(m.value) } else { default }

/// Identity `run` for API symmetry — Maybe values are already concrete.
///
/// -> dictionary
#let run(
  /// -> dictionary
  m,
) = m
