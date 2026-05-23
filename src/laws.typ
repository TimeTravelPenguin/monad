// Runtime monad-law verifiers.
//
// Monadic values are usually opaque (closures, structured data), so equality
// is monad-specific. Callers supply an `eq: (M a, M a) -> bool` predicate.
// For pure monads (Option, Result, Identity) `eq` is just `(a, b) => a == b`.
// For State/Reader, `eq` observes via `run` over sample states/envs.
//
// Laws checked:
//   left-identity:   bind(pure(a), f) == f(a)
//   right-identity:  bind(m, pure)    == m
//   associativity:   bind(bind(m, f), g) == bind(m, x => bind(f(x), g))
// Functor laws (derived, sanity-only):
//   fmap-identity:   fmap(id, m) == m
//   fmap-compose:    fmap(g ∘ f, m) == fmap(g, fmap(f, m))

#import "core.typ": pure, bind, fmap

/// First monad law: lifting then binding equals direct application.
/// `bind(pure(a), f) == f(a)`.
///
/// ```example
/// #check-left-identity(option.monad, (a, b) => a == b, 5, x => option.some(x + 1))
/// ```
///
/// -> bool
#let check-left-identity(
  /// -> dictionary
  monad,
  /// Equality predicate on monadic values. -> function
  eq,
  /// Sample value to pump through `pure`. -> any
  a,
  /// Kleisli arrow `a -> M b`. -> function
  f,
) = {
  let lhs = bind(monad, pure(monad, a), f)
  let rhs = f(a)
  eq(lhs, rhs)
}

/// Second monad law: binding `pure` as the continuation is a no-op.
/// `bind(m, pure) == m`.
///
/// -> bool
#let check-right-identity(
  /// -> dictionary
  monad,
  /// -> function
  eq,
  /// -> any
  m,
) = {
  let lhs = bind(monad, m, x => pure(monad, x))
  eq(lhs, m)
}

/// Third monad law: bind is associative.
/// `bind(bind(m, f), g) == bind(m, x => bind(f(x), g))`.
///
/// -> bool
#let check-associativity(
  /// -> dictionary
  monad,
  /// -> function
  eq,
  /// -> any
  m,
  /// `a -> M b`. -> function
  f,
  /// `b -> M c`. -> function
  g,
) = {
  let lhs = bind(monad, bind(monad, m, f), g)
  let rhs = bind(monad, m, x => bind(monad, f(x), g))
  eq(lhs, rhs)
}

/// Functor identity law: `fmap(id, m) == m`.
///
/// -> bool
#let check-fmap-identity(
  /// -> dictionary
  monad,
  /// -> function
  eq,
  /// -> any
  m,
) = {
  let lhs = fmap(monad, x => x, m)
  eq(lhs, m)
}

/// Functor composition law: `fmap(g ∘ f, m) == fmap(g, fmap(f, m))`.
///
/// -> bool
#let check-fmap-compose(
  /// -> dictionary
  monad,
  /// -> function
  eq,
  /// -> any
  m,
  /// -> function
  f,
  /// -> function
  g,
) = {
  let lhs = fmap(monad, x => g(f(x)), m)
  let rhs = fmap(monad, g, fmap(monad, f, m))
  eq(lhs, rhs)
}

/// Run every law across the cross-product of supplied sample arrays.
///
/// `samples` is a dict with optional keys:
/// - `values`: array of plain values `a`
/// - `actions`: array of monadic values `M a`
/// - `arrows-f`: array of `a -> M b`
/// - `arrows-g`: array of `b -> M c`
/// - `plain-fs`: array of `a -> b`
/// - `plain-gs`: array of `b -> c`
///
/// Returns `(passed: bool, failures: array)`.
///
/// ```example
/// #let report = check-laws(option.monad, (a, b) => a == b, (
///   values: (1, 2),
///   actions: (option.some(5), option.nothing),
///   "arrows-f": (x => option.some(x + 1),),
///   "arrows-g": (x => option.some(x * 2),),
/// ))
/// #report.passed
/// ```
///
/// -> dictionary
#let check-laws(
  /// -> dictionary
  monad,
  /// -> function
  eq,
  /// -> dictionary
  samples,
) = {
  let failures = ()

  for a in samples.at("values", default: ()) {
    for f in samples.at("arrows-f", default: ()) {
      if not check-left-identity(monad, eq, a, f) {
        failures.push((law: "left-identity", value: a))
      }
    }
  }

  for m in samples.at("actions", default: ()) {
    if not check-right-identity(monad, eq, m) {
      failures.push((law: "right-identity", action: m))
    }
  }

  for m in samples.at("actions", default: ()) {
    for f in samples.at("arrows-f", default: ()) {
      for g in samples.at("arrows-g", default: ()) {
        if not check-associativity(monad, eq, m, f, g) {
          failures.push((law: "associativity", action: m))
        }
      }
    }
  }

  for m in samples.at("actions", default: ()) {
    if not check-fmap-identity(monad, eq, m) {
      failures.push((law: "fmap-identity", action: m))
    }

    for f in samples.at("plain-fs", default: ()) {
      for g in samples.at("plain-gs", default: ()) {
        if not check-fmap-compose(monad, eq, m, f, g) {
          failures.push((law: "fmap-compose", action: m))
        }
      }
    }
  }

  (passed: failures.len() == 0, failures: failures)
}

/// Equality helper for State-shaped monads. Returns a predicate that
/// observes two state actions by running them across the supplied
/// initial states and comparing outputs.
///
/// ```example
/// #let eq = state-eq(state.run, ((:), (x: 1), (x: 5, y: 10)))
/// ```
///
/// -> function
#let state-eq(
  /// State `run` function. -> function
  run,
  /// Initial states to sample. -> array
  sample-states,
) = (m1, m2) => {
  for s in sample-states {
    if run(m1, s) != run(m2, s) { return false }
  }

  true
}

/// Equality helper for Reader-shaped monads. Same as @state-eq but observes
/// across sample environments.
///
/// -> function
#let reader-eq(
  /// Reader `run` function. -> function
  run,
  /// -> array
  sample-envs,
) = (m1, m2) => {
  for e in sample-envs {
    if run(m1, e) != run(m2, e) { return false }
  }

  true
}
