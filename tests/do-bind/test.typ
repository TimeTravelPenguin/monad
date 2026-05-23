#import "/tests/template.typ": test-page
#import "/src/lib.typ": do-bind, let-bind, pure, state, maybe, result

#show: test-page

#let prog = do-bind(state.monad, (
  state.put-at("x", 10),
  state.get-at("x"),
  let-bind(v => state.put-at("y", v * 2)),
  state.get-at("y"),
))
#let (final, last) = state.run(prog, (:))
#assert.eq(final, (x: 10, y: 20))
#assert.eq(last, 20)

#let combine = do-bind(state.monad, (
  state.put-at("a", 3),
  state.put-at("b", 4),
  state.get-at("a"),
  let-bind(a => do-bind(state.monad, (
    state.get-at("b"),
    let-bind(b => pure(state.monad, a + b)),
  ))),
))
#assert.eq(state.eval(combine, (:)), 7)

#let safe-div(a, b) = if b == 0 { maybe.nothing } else { maybe.just(a / b) }

#let chain = do-bind(maybe.monad, (
  safe-div(100, 5),
  let-bind(x => safe-div(x, 2)),
  let-bind(y => pure(maybe.monad, y + 1)),
))
#assert.eq(chain, maybe.just(11))

#let blown = do-bind(maybe.monad, (
  safe-div(100, 5),
  let-bind(x => safe-div(x, 0)),
  let-bind(y => pure(maybe.monad, y + 1)),
))
#assert.eq(blown, maybe.nothing)

#let parse-int(s) = {
  let n = int(s)
  if type(n) == int { result.ok(n) } else { result.err("not an int: " + s) }
}

#let pipeline = do-bind(result.monad, (
  parse-int("21"),
  let-bind(x => parse-int("2")),
  let-bind(y => pure(result.monad, y * 21)),
))
#assert.eq(pipeline, result.ok(42))

do-bind OK
