// Option monad.  M a = Some(a) | None
//
// Rust-style naming: `some(x)` for the inhabited case. The `None` variant
// is exposed as `nothing` because `none` is a reserved Typst literal and
// cannot be used as a binding name. Models computations that may produce
// no value; `bind` short-circuits on `nothing` — once a chain produces
// `nothing`, every subsequent step is skipped.

/// Wrap a value as `Some`.
///
/// ```example
/// #some(42)
/// ```
///
/// -> dictionary
#let some(
  /// -> any
  x,
) = (tag: "Some", value: x)

/// The `None` sentinel — named `nothing` because `none` is a reserved
/// Typst literal and cannot be used as an identifier. Distinguishable
/// from Typst's `none` because it is a tagged dict.
///
/// -> dictionary
#let nothing = (tag: "None")

/// Test whether an Option is `Some`.
/// -> bool
#let is-some(
  /// -> dictionary
  m,
) = m.tag == "Some"

/// Test whether an Option is `None`.
/// -> bool
#let is-none(
  /// -> dictionary
  m,
) = m.tag == "None"

/// Option monad instance. `bind` short-circuits on `None`: once a chain
/// produces `None`, every subsequent step is skipped.
///
/// ```example
/// #bind(option.monad, option.some(3), x => option.some(x * 2))
/// #bind(option.monad, option.nothing, x => option.some(x * 2))
/// ```
///
/// -> dictionary
#let monad = (
  pure: some,
  bind: (m, f) => if m.tag == "Some" { f(m.value) } else { m },
  fmap: (f, m) => if m.tag == "Some" { some(f(m.value)) } else { m },
)

/// Extract the inner value or return a default for `None`.
///
/// ```example
/// #unwrap-or(0, option.some(7))
/// #unwrap-or(0, option.nothing)
/// ```
///
/// -> any
#let unwrap-or(
  /// -> any
  default,
  /// -> dictionary
  m,
) = if m.tag == "Some" { m.value } else { default }

/// Eliminator: apply `f` to the inner value, or fall back to `default`.
/// Mirrors Rust's `Option::map_or`.
///
/// -> any
#let map-or(
  /// -> any
  default,
  /// -> function
  f,
  /// -> dictionary
  m,
) = if m.tag == "Some" { f(m.value) } else { default }

/// Identity `run` for API symmetry — Option values are already concrete.
///
/// -> dictionary
#let run(
  /// -> dictionary
  m,
) = m
