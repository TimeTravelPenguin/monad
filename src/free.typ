// Operational monad construction.
//
// Given a dictionary of named handlers
//
//   (op-name: (..args) -> (state -> (state', value)))
//
// `make` returns a builder bundle:
//   .ops      — constructors, each wrapping its action in a 1-tuple so that
//               block-join sugar { Op1(..); Op2(..) } concatenates actions
//   .monad    — the underlying State monad instance (for explicit bind/seq)
//   .eval     — interpreter: (body) -> (state:, value:)
//   .eval-state, .eval-value — partial views
//   .init     — the default initial state
//
// This is the path most users will take when designing a DSL — define the
// vocabulary as handlers, then offer .ops + .eval as the public surface.
// `make` is intentionally a specialization of State; reach for `core.bind`
// when you need cross-action dataflow with named intermediate results.

#import "instances/state.typ" as state-mod
#import "core.typ": _flatten

#let make(handlers: (:), init: (:)) = {
  let constructors = (:)
  for (name, h) in handlers.pairs() {
    constructors.insert(name, (..args) => (h(..args),))
  }

  let eval-with(body, start: init) = {
    let actions = _flatten(body)
    let state = start
    let last = none
    for op in actions {
      let (s, v) = op(state)
      state = s
      last = v
    }

    (state: state, value: last)
  }

  let eval = body => eval-with(body)

  (
    ops: constructors,
    monad: state-mod.monad,
    eval: eval,
    eval-with: eval-with,
    eval-state: body => eval(body).state,
    eval-value: body => eval(body).value,
    init: init,
  )
}

// Lift an existing State action into the builder's action shape (1-tuple).
// Useful when mixing hand-written State combinators with handler-derived ops.

#let lift(action) = (action,)
