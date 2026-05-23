// Identity monad.  M a = a
//
// The trivial monad: `pure` is identity, `bind` is reverse application.
// Useful as a baseline for testing core combinators and as the "no-effect"
// case when composing monad transformers.

/// Identity monad instance. `pure` is the identity function, `bind` is
/// reverse application. `M a` is just `a`.
///
/// ```example
/// #pure(identity.monad, 7)
/// #bind(identity.monad, 3, x => x + 1)
/// ```
///
/// -> dictionary
#let monad = (
  pure: x => x,
  bind: (m, f) => f(m),
  fmap: (f, m) => f(m),
  join: mm => mm,
)

/// Extract the value from an Identity action. Trivial — it is the action
/// itself — but provided for API symmetry with the other instances.
///
/// -> any
#let run(
  /// -> any
  m,
) = m
