// Core monad protocol.
//
// A `monad` here is an instance dict with required fields:
//   pure: a -> M a
//   bind: (M a, a -> M b) -> M b
//
// Optional fields are derived from `bind` if absent:
//   fmap: (a -> b, M a) -> M b
//   join: M (M a) -> M a
//   ap:   (M (a -> b), M a) -> M b
//
// Convention for block-join sugar:
//   A "builder" constructor (one a user defines for their DSL) returns its
//   monadic value wrapped in a 1-tuple: `(action,)`. Typst code blocks join
//   arrays via `+`, so writing
//     { Set("x", 2); Add("x", 3) }
//   produces `(set-action, add-action)` which `do` flattens and folds.
//   For pure programmatic use, pass an array directly.

#let pure(monad, x) = (monad.pure)(x)

#let bind(monad, m, k) = (monad.bind)(m, k)

#let fmap(monad, f, m) = {
  if "fmap" in monad {
    return (monad.fmap)(f, m)
  }

  (monad.bind)(m, x => (monad.pure)(f(x)))
}

#let join(monad, mm) = {
  if "join" in monad {
    return (monad.join)(mm)
  }

  (monad.bind)(mm, m => m)
}

#let ap(monad, mf, ma) = {
  if "ap" in monad {
    return (monad.ap)(mf, ma)
  }

  (monad.bind)(mf, f => fmap(monad, f, ma))
}

#let _flatten(body) = {
  let out = ()
  let items = if type(body) == array { body } else { (body,) }
  for x in items {
    if type(x) == array {
      out += _flatten(x)
    } else {
      out.push(x)
    }
  }
  out
}

#let seq(monad, ms) = {
  let actions = _flatten(ms)
  if actions.len() == 0 {
    return (monad.pure)(none)
  }

  let acc = actions.first()
  for m in actions.slice(1) {
    acc = (monad.bind)(acc, _ => m)
  }

  acc
}

#let do = seq

#let sequence(monad, ms) = {
  let actions = _flatten(ms)
  let acc = (monad.pure)(())
  for m in actions {
    acc = (monad.bind)(
      acc,
      xs => (monad.bind)(m, v => (monad.pure)(xs + (v,))),
    )
  }

  acc
}

#let map-m(monad, f, xs) = sequence(monad, xs.map(f))

#let for-m(monad, xs, f) = sequence(monad, xs.map(f))

#let kleisli(monad, fs) = {
  x => {
    let acc = (monad.pure)(x)
    for f in fs {
      acc = (monad.bind)(acc, f)
    }

    acc
  }
}

#let when(monad, cond, m) = {
  if cond { m } else { (monad.pure)(none) }
}

#let unless(monad, cond, m) = when(monad, not cond, m)

#let void(monad, m) = (monad.bind)(m, _ => (monad.pure)(none))

// `let-bind(k)` tags a callback so `do-bind` can tell it apart from a plain
// monadic action. The tag is necessary because in State/Reader/Writer the
// actions themselves are functions — distinguishing by `type()` is not safe.
#let let-bind(k) = (_do-bind-cont: k)

#let _is-let-bind(step) = (
  type(step) == dictionary and "_do-bind-cont" in step
)

// `do-bind(monad, steps)` folds a flat sequence of actions and callbacks
// via `bind`. Each step is either:
//   - a monadic action M a              (its result is discarded)
//   - `let-bind(v => next(v))` arrow    (binds previous result into `v`)
//
// Read it like Haskell `do`:
//   do { Set("x", 0); v <- Get("x"); Set("y", v + 1) }
// becomes:
//   do-bind(state.monad, (
//     state.put-at("x", 0),
//     state.get-at("x"),
//     let-bind(v => state.put-at("y", v + 1)),
//   ))
//
// The first step must be an action, not a let-bind.
#let do-bind(monad, steps) = {
  if steps.len() == 0 {
    return (monad.pure)(none)
  }

  let first = steps.first()
  if _is-let-bind(first) {
    panic("do-bind: first step must be an action, not a let-bind")
  }

  let acc = first
  for step in steps.slice(1) {
    if _is-let-bind(step) {
      acc = (monad.bind)(acc, step._do-bind-cont)
    } else {
      acc = (monad.bind)(acc, _ => step)
    }
  }

  acc
}

#let replicate(monad, n, m) = {
  let acc = (monad.pure)(())
  let i = 0
  while i < n {
    acc = (monad.bind)(
      acc,
      xs => (monad.bind)(m, v => (monad.pure)(xs + (v,))),
    )
    i = i + 1
  }

  acc
}
