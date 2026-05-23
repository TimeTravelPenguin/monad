// Runtime monad-law verifiers.
//
// Monadic values are usually opaque (closures, structured data), so equality
// is monad-specific. Callers supply an `eq: (M a, M a) -> bool` predicate.
// For pure monads (Maybe, Result, Identity) `eq` is just `(a, b) => a == b`.
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

#let check-left-identity(monad, eq, a, f) = {
  let lhs = bind(monad, pure(monad, a), f)
  let rhs = f(a)
  eq(lhs, rhs)
}

#let check-right-identity(monad, eq, m) = {
  let lhs = bind(monad, m, x => pure(monad, x))
  eq(lhs, m)
}

#let check-associativity(monad, eq, m, f, g) = {
  let lhs = bind(monad, bind(monad, m, f), g)
  let rhs = bind(monad, m, x => bind(monad, f(x), g))
  eq(lhs, rhs)
}

#let check-fmap-identity(monad, eq, m) = {
  let lhs = fmap(monad, x => x, m)
  eq(lhs, m)
}

#let check-fmap-compose(monad, eq, m, f, g) = {
  let lhs = fmap(monad, x => g(f(x)), m)
  let rhs = fmap(monad, g, fmap(monad, f, m))
  eq(lhs, rhs)
}

// Run all laws over the cross product of supplied samples.
//
// samples = (
//   values: (a1, a2, ...),         // pumped through pure / arrows
//   actions: (m1, m2, ...),        // monadic values M a
//   arrows-f: (f1, f2, ...),       // a -> M b
//   arrows-g: (g1, g2, ...),       // b -> M c
//   plain-fs: (f1, ...),           // a -> b (for functor laws)
//   plain-gs: (g1, ...),           // b -> c
// )
//
// Returns (passed: bool, failures: (label, detail)[])

#let check-laws(monad, eq, samples) = {
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

// Equality helper for State-shaped monads: observes by running over a list of
// sample initial states and comparing outputs.

#let state-eq(run, sample-states) = (m1, m2) => {
  for s in sample-states {
    if run(m1, s) != run(m2, s) { return false }
  }

  true
}

// Equality helper for Reader-shaped monads: observes by running over envs.

#let reader-eq(run, sample-envs) = (m1, m2) => {
  for e in sample-envs {
    if run(m1, e) != run(m2, e) { return false }
  }

  true
}
