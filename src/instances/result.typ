// Result monad.  M a = ok(a) | err(e)
//
// Models computations that may fail with a typed error. `bind` short-circuits
// on `err`, preserving the error value untouched.

/// Wrap a success value as `ok`.
///
/// ```example
/// #ok(42)
/// ```
///
/// -> dictionary
#let ok(
  /// -> any
  x,
) = (tag: "ok", value: x)

/// Wrap an error value as `err`.
///
/// ```example
/// #err("not found")
/// ```
///
/// -> dictionary
#let err(
  /// -> any
  e,
) = (tag: "err", value: e)

/// Test whether a Result is `ok`.
/// -> bool
#let is-ok(
  /// -> dictionary
  m,
) = m.tag == "ok"

/// Test whether a Result is `err`.
/// -> bool
#let is-err(
  /// -> dictionary
  m,
) = m.tag == "err"

/// Result monad instance. `bind` short-circuits on `err`, threading the
/// error value through unchanged.
///
/// ```example
/// #bind(result.monad, result.ok(3), x => result.ok(x * 2))
/// #bind(result.monad, result.err("oops"), x => result.ok(x * 2))
/// ```
///
/// -> dictionary
#let monad = (
  pure: ok,
  bind: (m, f) => if m.tag == "ok" { f(m.value) } else { m },
  fmap: (f, m) => if m.tag == "ok" { ok(f(m.value)) } else { m },
)

/// Transform the error value, leaving `ok` untouched.
///
/// ```example
/// #map-err(s => "ERR: " + s, result.err("boom"))
/// ```
///
/// -> dictionary
#let map-err(
  /// -> function
  f,
  /// -> dictionary
  m,
) = if m.tag == "err" { err(f(m.value)) } else { m }

/// Extract the inner value or return a default on error.
///
/// -> any
#let unwrap-or(
  /// -> any
  default,
  /// -> dictionary
  m,
) = if m.tag == "ok" { m.value } else { default }

/// Identity `run` for API symmetry.
///
/// -> dictionary
#let run(
  /// -> dictionary
  m,
) = m
