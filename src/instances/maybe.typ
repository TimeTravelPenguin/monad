// Maybe monad.  M a = just(a) | nothing
//
// Models computations that can fail without an error value. `bind` short-
// circuits on `nothing` — once a chain produces nothing, the rest of the
// chain is skipped.

#let just(x) = (tag: "just", value: x)
#let nothing = (tag: "nothing")

#let is-just(m) = m.tag == "just"
#let is-nothing(m) = m.tag == "nothing"

#let monad = (
  pure: just,
  bind: (m, f) => if m.tag == "just" { f(m.value) } else { m },
  fmap: (f, m) => if m.tag == "just" { just(f(m.value)) } else { m },
)

#let from-maybe(default, m) = if m.tag == "just" { m.value } else { default }

#let maybe(default, f, m) = if m.tag == "just" { f(m.value) } else { default }

#let run(m) = m
