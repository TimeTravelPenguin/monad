// Hand-written narrative tutorial.
// Included from main.typ; uses the same imports and example-scope.

= A guided tour

This chapter derives the State monad from scratch --- not as an abstract
definition, but as the natural conclusion of trying to write some
ordinary stateful code cleanly. Once we have it, we look at how this
package packages the result, and at how the same recipe applies to
other useful effects.

If you have never used monads before, read this in order. If you have,
skip to the last two sections.

== The problem: threading state by hand

Suppose we want to compute a counter through a small pipeline of
operations:

```typ
#let s0 = (count: 0)
#let s1 = (count: s0.count + 5)
#let s2 = (count: s1.count + 10)
#let s3 = (count: s2.count * 2)
// s3 = (count: 30)
```

It works. But every line names the state we just produced so the next
line can read from it. The names are bookkeeping --- we don't actually
care that the intermediate values existed.

Worse, if any line forgets to thread `s2` correctly and reads `s1`
instead, we get a silent bug. The cost of the bookkeeping is real.

== Each step as a function

The first move is to make the steps reusable. Lift "add `n`" into a
function from a state to a new state:

```typ
#let add(n) = state => (count: state.count + n)
#let double = state => (count: state.count * 2)
```

Now composition is function application:

```typ
#double(add(10)(add(5)((count: 0))))
// (count: 30)
```

This reads inside-out and is awkward to scale, but at least the
intermediate names have evaporated.

== Each step returns a value too

Often a step computes something the *next* step needs --- not just a
state, but a value. So let every step return *both*: a new state and a
value.

```typ
#let add(n) = state => {
  let next = state.count + n
  ((count: next), next)
}
```

Now the previous bookkeeping comes back, but for a reason --- the next
step actually uses `v`:

```typ
#let prog = state => {
  let (s1, v1) = add(5)(state)
  let (s2, v2) = add(10)(s1)
  let (s3, v3) = ((count: s2.count * v2), s2.count * v2)
  (s3, v3)
}
#prog((count: 0))
// ((count: 150), 150)
```

Every line does the same dance: unpack `(state, value)`, feed `state`
to the next call, possibly use the value. That dance is mechanical.

== Factoring out the threading: `bind`

Whenever the same five-line dance shows up in every program, give it a
name and write it once.

```typ
#let bind(m, k) = state => {
  let (s2, v) = m(state)
  k(v)(s2)
}
```

Read it: "Run action `m` to get a new state and a value. Pass the value
to the callback `k`. `k` returns *another* action. Run it on the new
state. Return its result."

Now the pipeline:

```typ
#let prog = bind(add(5), v1 =>
  bind(add(10), v2 =>
    state => ((count: state.count * v2), state.count * v2)))
```

Still nested --- we'll address that --- but the threading is gone. Every
intermediate `(s, v)` is hidden inside `bind`.

== Lifting plain values: `pure`

What if a step doesn't need to touch the state at all --- it just wants
to return a plain value? We need to wrap it into the same `state -> (state, value)` shape.

```typ
#let pure(x) = state => (state, x)
```

That's all `pure` does. It takes a value and produces a no-op action
that yields that value.

== That's it. That's the monad.

Two functions:

```typ
#let pure(x) = state => (state, x)
#let bind(m, k) = state => {
  let (s2, v) = m(state)
  k(v)(s2)
}
```

Plus a convention --- actions have shape `state -> (state, value)` --- and
you have the State monad. Every other combinator (sequence two actions,
discard a value, repeat an action, fmap a plain function over the
inner value) can be derived from `pure` and `bind` alone. That's why
they're the foundation.

== Why "monad"?

The name is from category theory and the technical definition is
unimportant for using the package. The thing that matters is the
*contract* --- `pure` and `bind` must satisfy three laws:

+ *Left identity*. `bind(pure(a), f) == f(a)`. If you lift a plain
  value and then immediately bind, you should get the same result as
  if you had just called `f(a)` directly. Lifting then binding is a
  no-op.

+ *Right identity*. `bind(m, pure) == m`. If you bind an action with
  `pure` as the callback, nothing changes. `pure` is the identity of
  `bind`.

+ *Associativity*. `bind(bind(m, f), g) == bind(m, x => bind(f(x), g))`.
  How you parenthesize a chain of binds doesn't matter; what matters
  is the order of the actions.

These three laws are what make every derived combinator behave
predictably. A "monad" that doesn't satisfy them is a buggy monad ---
combinators built on top will not do what they claim.

The package's `laws.check-laws` will test a candidate instance against
the laws by sampling actions. We will use it later.

== Reading nested binds cleanly: `do-bind`

The biggest practical wart of `bind` is that long pipelines turn into
trees of nested callbacks. The package gives you a flattener,
`do-bind`, plus a small marker `let-bind` that tags steps which want to
capture the previous value:

```typ
#do-bind(state.monad, (
  state.put-at("x", 5),
  state.get-at("x"),
  let-bind(v => state.put-at("y", v * 2)),
  state.get-at("y"),
))
```

This is exactly the nested `bind` you would write by hand, but
linear. Read top to bottom; treat each `let-bind(v => ...)` as "the
previous value is bound to `v`".

== Block-join sugar with `free.make`

When every step is a *named command* over a shared state and you don't
need to capture per-step values (just chain commands), there's even
less ceremony. Define the commands as handlers and let `free.make`
package the rest:

```example
#let builder = free.make(handlers: (
  Set: (key, val) => state => {
    let s = state
    s.insert(key, val)
    (s, val)
  },
  Add: (key, n) => state => {
    let cur = state.at(key, default: 0)
    let s = state
    s.insert(key, cur + n)
    (s, cur + n)
  },
))
#let Set = builder.ops.Set
#let Add = builder.ops.Add
#let eval = builder.eval

#eval({ Set("x", 2); Add("x", 3) })
```

Each constructor wraps its action in a 1-tuple. Typst joins arrays via
`+`, so `{ Set(..); Add(..) }` produces `(set-action, add-action)`
which `eval` interprets in order.

`if` and `for` work inside the block too:

```example
#let builder = free.make(handlers: (
  Add: n => state => {
    let cur = state.at("count", default: 0)
    let s = state; s.insert("count", cur + n)
    (s, cur + n)
  },
))
#let Add = builder.ops.Add
#let eval = builder.eval

#eval({
  for n in (1, 2, 3, 4) { Add(n) }
  if true { Add(100) }
})
```

== Other shapes, same protocol

The recipe --- define `pure` and `bind` over some shape, check the laws,
get every derived combinator for free --- is not specific to State. The
package ships five other instances. The shape of "an action" changes;
the `pure` / `bind` contract does not.

*Maybe* --- `M a = just(a) | nothing`. Models a computation that may
produce no value. `bind` short-circuits on `nothing`:

```example
#let safe-div(a, b) = if b == 0 { maybe.nothing } else { maybe.just(a / b) }

#do-bind(maybe.monad, (
  safe-div(100, 5),
  let-bind(x => safe-div(x, 2)),
  let-bind(y => pure(maybe.monad, y + 1)),
))
```

Replace `0` with a non-zero divisor anywhere and the chain
succeeds. Try dividing by zero and the rest of the chain is skipped:

```example
#let safe-div(a, b) = if b == 0 { maybe.nothing } else { maybe.just(a / b) }

#do-bind(maybe.monad, (
  safe-div(100, 5),
  let-bind(x => safe-div(x, 0)),
  let-bind(y => pure(maybe.monad, y + 1)),
))
```

*Result* --- `M a = ok(a) | err(e)`. Like Maybe but the failure value is
typed. `bind` short-circuits on `err`, threading the error through.

*Reader* --- `M a = env -> a`. A function from an environment. Useful for
dependency injection: pass config once at the top, read it with `ask`
anywhere in the chain.

*Writer* --- `M a = (log, a)`. Accumulates a log alongside the value.
The log type must form a monoid (an identity and an associative
combine); the default is array concatenation.

*Identity* --- `M a = a`. The trivial monad. Useful for testing the
abstract combinators and as the no-effect baseline.

== Defining your own

A monad in this package is just a dict with `pure` and `bind` fields.
You can build one in a few lines, then use `check-laws` to confirm it
actually satisfies the contract. Most of your custom monads will look
like one of the six above with a small twist --- say, State with an
extra error channel, or Writer with a custom log monoid.

```typ
#let my-monad = (
  pure: x => ...,
  bind: (m, k) => ...,
)

#let report = check-laws(my-monad, my-eq, (
  values: (...),
  actions: (...),
  "arrows-f": (...),
  "arrows-g": (...),
))
#assert(report.passed, message: repr(report.failures))
```

The `examples/custom-monad.typ` file in this repository walks through
defining an *incorrect* monad --- one that counts bind invocations ---
and shows how `check-laws` catches the associativity violation. It is
worth reading once.

== What we covered

- Stateful sequencing motivates `bind` and `pure`.
- A monad is `(pure, bind)` satisfying three laws.
- Reading nested binds is helped by `do-bind` + `let-bind`.
- Sequencing named commands is helped by `free.make`.
- The same protocol covers Maybe, Result, Reader, Writer, and your
  own custom monads.

The rest of this manual is reference: every public function with its
parameter list, return type, and a runnable example.
