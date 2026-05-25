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

/// Lift a plain value into a monadic context.
///
/// ```example
/// #pure(option.monad, 7)
/// ```
///
/// -> any
#let pure(
  /// The monad instance dict (with `pure` and `bind` fields).
  /// -> dictionary
  monad,
  /// The value to inject. -> any
  x,
) = (monad.pure)(x)

/// Sequence two computations, feeding the result of the first into a
/// callback that produces the second. The bedrock combinator of every
/// monad; everything else in this file is derived from `pure` and `bind`.
///
/// ```example
/// #bind(option.monad, option.some(3), x => option.some(x + 1))
/// ```
///
/// -> any
#let bind(
  /// -> dictionary
  monad,
  /// First monadic value. -> any
  m,
  /// Callback `value -> M b`. -> function
  k,
) = (monad.bind)(m, k)

/// Apply a plain function to the value inside a monadic context, without
/// flattening. Equivalent to `bind(m, x => pure(f(x)))`; instances may
/// provide a faster implementation via the optional `fmap` field.
///
/// ```example
/// #fmap(option.monad, x => x * 10, option.some(4))
/// ```
///
/// -> any
#let fmap(
  /// -> dictionary
  monad,
  /// Plain transformation. -> function
  f,
  /// Source monadic value. -> any
  m,
) = {
  if "fmap" in monad {
    return (monad.fmap)(f, m)
  }

  (monad.bind)(m, x => (monad.pure)(f(x)))
}

/// Collapse a nested monadic value `M (M a)` into `M a`.
/// Useful when a callback produces an already-wrapped value and you want
/// to unwrap a layer.
///
/// ```example
/// #join(option.monad, option.some(option.some(5)))
/// ```
///
/// -> any
#let join(
  /// -> dictionary
  monad,
  /// Doubly-wrapped value. -> any
  mm,
) = {
  if "join" in monad {
    return (monad.join)(mm)
  }

  (monad.bind)(mm, m => m)
}

/// Applicative application: run a monadic function and a monadic argument,
/// then apply.
///
/// ```example
/// #ap(option.monad, option.some(x => x + 1), option.some(4))
/// ```
///
/// -> any
#let ap(
  /// -> dictionary
  monad,
  /// Function-valued monadic. -> any
  mf,
  /// Argument-valued monadic. -> any
  ma,
) = {
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

/// Sequence a list of monadic values, discarding intermediate results.
/// Returns the final value. Accepts nested arrays (from Typst block-join)
/// and flattens them before folding.
///
/// ```example
/// #seq(option.monad, (option.some(1), option.some(2), option.some(3)))
/// ```
///
/// -> any
#let seq(
  /// -> dictionary
  monad,
  /// Array (possibly nested) of monadic values. -> array
  ms,
) = {
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

/// Alias for @seq. Reads more naturally inside builder blocks:
/// `do(state.monad, { ... })`.
///
/// -> any
#let do = seq

/// Sequence a list of monadic values, *collecting* every intermediate
/// result into an array. The returned action yields a tuple of length
/// `ms.len()`.
///
/// ```example
/// #state.run(
///   sequence(state.monad, (state.put-at("a", 1), state.put-at("b", 2))),
///   (:),
/// )
/// ```
///
/// -> any
#let sequence(
  /// -> dictionary
  monad,
  /// Array of monadic values. -> array
  ms,
) = {
  let acc = (monad.pure)(())

  for m in ms {
    acc = (monad.bind)(
      acc,
      xs => (monad.bind)(m, v => (monad.pure)(xs + (v,))),
    )
  }

  acc
}

/// Map a monad-producing function across an array, then sequence the
/// results. `mapM` from Haskell.
///
/// ```example
/// #map-m(option.monad, x => option.some(x * 2), (1, 2, 3))
/// ```
///
/// -> any
#let map-m(
  /// -> dictionary
  monad,
  /// `a -> M b`. -> function
  f,
  /// Array of inputs. -> array
  xs,
) = sequence(monad, xs.map(f))

/// Like @map-m with the array and function arguments swapped — convenient
/// when the function is a multi-line closure.
///
/// -> any
#let for-m(
  /// -> dictionary
  monad,
  /// -> array
  xs,
  /// -> function
  f,
) = sequence(monad, xs.map(f))

/// Compose a list of Kleisli arrows (`a -> M b`, `b -> M c`, ...) into a
/// single `a -> M z` arrow.
///
/// ```example
/// #let inc = x => option.some(x + 1)
/// #let double = x => option.some(x * 2)
/// #(kleisli(option.monad, (inc, double)))(3)
/// ```
///
/// -> function
#let kleisli(
  /// -> dictionary
  monad,
  /// Array of Kleisli arrows. -> array
  fs,
) = {
  x => {
    let acc = (monad.pure)(x)

    for f in fs {
      acc = (monad.bind)(acc, f)
    }

    acc
  }
}

/// Run an action only if a condition holds, otherwise produce `pure(none)`.
///
/// ```example
/// #when(option.monad, 5 > 3, option.some("yes"))
/// ```
///
/// -> any
#let when(
  /// -> dictionary
  monad,
  /// -> bool
  cond,
  /// -> any
  m,
) = {
  if cond { m } else { (monad.pure)(none) }
}

/// Inverse of @when — run the action only when the condition is `false`.
///
/// -> any
#let unless(
  /// -> dictionary
  monad,
  /// -> bool
  cond,
  /// -> any
  m,
) = when(monad, not cond, m)

/// Discard the value produced by an action while keeping its effect.
///
/// -> any
#let void(
  /// -> dictionary
  monad,
  /// -> any
  m,
) = (monad.bind)(m, _ => (monad.pure)(none))

/// Repeat an action `n` times and collect every produced value into an
/// array.
///
/// ```example
/// #replicate(option.monad, 3, option.some("hi"))
/// ```
///
/// -> any
#let replicate(
  /// -> dictionary
  monad,
  /// Number of repetitions (zero or negative produces `pure(())`). -> int
  n,
  /// -> any
  m,
) = {
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

/// Wrap a callback so @do-bind can tell it apart from a plain action.
/// Required because in State/Reader/Writer monads, *actions* are themselves
/// functions — `type()` alone cannot disambiguate.
///
/// ```example
/// #let-bind(v => option.some(v + 1))
/// ```
///
/// -> dictionary
#let let-bind(
  /// `value -> M b`. -> function
  k,
) = (_do-bind-cont: k)

#let _is-let-bind(step) = (
  type(step) == dictionary and "_do-bind-cont" in step
)

/// Fold a flat sequence of actions and callbacks via @bind. Each step is
/// either a monadic action (its value is discarded) or `let-bind(v => ...)`
/// (the previous value is bound to `v`).
///
/// Reads like Haskell `do`: write actions and `let-bind`-wrapped arrows in
/// the order they should fire.
///
/// ```example
/// #let prog = do-bind(state.monad, (
///   state.put-at("x", 10),
///   state.get-at("x"),
///   let-bind(v => state.put-at("y", v * 2)),
/// ))
/// #state.run(prog, (:))
/// ```
///
/// -> any
#let do-bind(
  /// -> dictionary
  monad,
  /// Steps in execution order. First must be an action, not a let-bind.
  /// -> array
  steps,
) = {
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
