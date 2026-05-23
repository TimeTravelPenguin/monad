// State monad.  M a = state -> (state, a)
//
// Threads a mutable-feeling state through a pure computation. This is the
// monad behind builder DSLs like the user's `SomeEnv { Set; Add }` pattern
// — see `src/free.typ` for the operational helper that wraps state with a
// named-op interpreter.

#let monad = (
  pure: x => (state => (state, x)),
  bind: (m, k) => (state => {
    let (s2, v) = m(state)
    k(v)(s2)
  }),
)

#let get = state => (state, state)

#let put(new) = state => (new, none)

#let modify(f) = state => (f(state), none)

#let gets(f) = state => (state, f(state))

#let get-at(key, default: none) = state => (
  state,
  state.at(key, default: default),
)

#let put-at(key, value) = state => {
  let s = state
  s.insert(key, value)
  (s, value)
}

#let modify-at(key, f, default: none) = state => {
  let cur = state.at(key, default: default)
  let next = f(cur)
  let s = state
  s.insert(key, next)
  (s, next)
}

#let run(m, init) = m(init)

#let eval(m, init) = m(init).at(1)

#let exec(m, init) = m(init).at(0)
