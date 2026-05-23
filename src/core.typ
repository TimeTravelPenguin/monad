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
