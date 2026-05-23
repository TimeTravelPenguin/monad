// Result monad.  M a = ok(a) | err(e)
//
// Models computations that may fail with a typed error. `bind` short-circuits
// on `err`, preserving the error value untouched.

#let ok(x) = (tag: "ok", value: x)
#let err(e) = (tag: "err", value: e)

#let is-ok(m) = m.tag == "ok"
#let is-err(m) = m.tag == "err"

#let monad = (
  pure: ok,
  bind: (m, f) => if m.tag == "ok" { f(m.value) } else { m },
  fmap: (f, m) => if m.tag == "ok" { ok(f(m.value)) } else { m },
)

#let map-err(f, m) = if m.tag == "err" { err(f(m.value)) } else { m }

#let unwrap-or(default, m) = if m.tag == "ok" { m.value } else { default }

#let run(m) = m
