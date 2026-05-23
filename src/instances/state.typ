// State monad.  M a = state -> (state, a)
//
// Threads a mutable-feeling state through a pure computation. This is the
// monad behind builder DSLs like the user's `SomeEnv { Set; Add }` pattern
// — see `src/free.typ` for the operational helper that wraps state with a
// named-op interpreter.

/// State monad instance. Values are functions `state -> (state, a)`. Threads
/// the state through `bind` while producing values per step.
///
/// ```example
/// #let prog = bind(state.monad, state.put-at("x", 5), _ =>
///   state.get-at("x"))
/// #state.run(prog, (:))
/// ```
///
/// -> dictionary
#let monad = (
  pure: x => (state => (state, x)),
  bind: (m, k) => (
    state => {
      let (s2, v) = m(state)
      k(v)(s2)
    }
  ),
)

/// Action that returns the current state without modifying it.
/// -> function
#let get = state => (state, state)

/// Action that overwrites the state, discarding the previous value.
/// -> function
#let put(
  /// New state. -> dictionary
  new,
) = state => (new, none)

/// Apply a transformation to the state.
///
/// ```example
/// #state.run(state.modify(s => s + (touched: true)), (a: 1))
/// ```
///
/// -> function
#let modify(
  /// `state -> state`. -> function
  f,
) = state => (f(state), none)

/// Read a projected view of the state.
/// -> function
#let gets(
  /// `state -> a`. -> function
  f,
) = state => (state, f(state))

/// Read a single key from a dict-shaped state.
///
/// ```example
/// #state.run(state.get-at("x", default: 0), (x: 9))
/// ```
///
/// -> function
#let get-at(
  /// -> any
  key,
  /// Fallback when key is missing. -> any
  default: none,
) = state => (
  state,
  state.at(key, default: default),
)

/// Write a single key in a dict-shaped state. Returns the written value.
///
/// ```example
/// #state.run(state.put-at("x", 10), (:))
/// ```
///
/// -> function
#let put-at(
  /// -> any
  key,
  /// -> any
  value,
) = state => {
  let s = state
  s.insert(key, value)
  (s, value)
}

/// Apply `f` to a single key of the dict-shaped state. Returns the new
/// value.
///
/// ```example
/// #state.run(
///   state.modify-at("count", x => x + 1, default: 0),
///   (count: 4),
/// )
/// ```
///
/// -> function
#let modify-at(
  /// -> any
  key,
  /// `value -> value`. -> function
  f,
  /// -> any
  default: none,
) = state => {
  let cur = state.at(key, default: default)
  let next = f(cur)
  let s = state
  s.insert(key, next)
  (s, next)
}

/// Run a State action against an initial state and return `(state, value)`.
///
/// ```example
/// #state.run(state.put-at("x", 1), (:))
/// ```
///
/// -> array
#let run(
  /// -> function
  m,
  /// -> dictionary
  init,
) = m(init)

/// Run a State action and return only the produced value.
/// -> any
#let eval(
  /// -> function
  m,
  /// -> dictionary
  init,
) = m(init).at(1)

/// Run a State action and return only the final state.
/// -> dictionary
#let exec(
  /// -> function
  m,
  /// -> dictionary
  init,
) = m(init).at(0)
