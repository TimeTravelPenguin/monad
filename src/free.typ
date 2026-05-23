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

/// Build a State-backed DSL from a dictionary of named handlers.
///
/// Each handler has shape `(..args) -> state -> (state', value)` — that is,
/// it returns a State action when called with its DSL-level arguments. The
/// returned bundle exposes:
///
/// - `.ops` — a dict of *constructors*. Each wraps its action in a 1-tuple
///   so that block-join sugar `{ Op1(..); Op2(..) }` concatenates actions.
/// - `.monad` — the underlying State monad instance for use with `bind` etc.
/// - `.eval(body)` — interpret a body, returning `(state:, value:)`.
/// - `.eval-with(body, start:)` — like `eval` but with a custom initial
///   state.
/// - `.eval-state(body)` / `.eval-value(body)` — partial views.
/// - `.init` — the default initial state.
///
/// ```example
/// #let builder = free.make(handlers: (
///   Set: (k, v) => s => { let s2 = s; s2.insert(k, v); (s2, v) },
///   Add: (k, n) => s => {
///     let cur = s.at(k, default: 0)
///     let s2 = s; s2.insert(k, cur + n); (s2, cur + n)
///   },
/// ))
/// #let Set = builder.ops.Set
/// #let Add = builder.ops.Add
/// #let eval = builder.eval
/// #eval({ Set("x", 2); Add("x", 3) }).value
/// ```
///
/// -> dictionary
#let make(
  /// Dict mapping op name to handler. -> dictionary
  handlers: (:),
  /// Default initial state passed to `.eval`. -> dictionary
  init: (:),
) = {
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

/// Lift a hand-written State action into the builder action shape (a
/// 1-tuple). Use this when mixing custom State combinators with the
/// constructors returned by @make.
///
/// ```example
/// #lift(state.get-at("x"))
/// ```
///
/// -> array
#let lift(
  /// Bare State action `state -> (state, value)`. -> function
  action,
) = (action,)
