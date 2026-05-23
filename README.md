# monad

A Typst package for building **correct, lawful monadic DSLs**. Define a
vocabulary of operations; the library hands back a builder that lets your
users write programs as block-joined sequences, plus a State monad instance
for everything else.

```typ
#import "@preview/monad:0.1.0": free

#let builder = free.make(handlers: (
  Set: (key, val) => state => {
    let s = state; s.insert(key, val); (s, val)
  },
  Add: (key, n) => state => {
    let cur = state.at(key, default: 0)
    let s = state; s.insert(key, cur + n); (s, cur + n)
  },
))

#let Set = builder.ops.Set
#let Add = builder.ops.Add
#let SomeEnv = builder.eval

#let env = SomeEnv({
  Set("x", 2)
  Add("x", 3)
})

#env.value  // 5
#env.state  // (x: 5)
```

## What you get

| Module | Purpose |
| --- | --- |
| `core.typ` | `pure`, `bind`, `seq`/`do`, `do-bind`/`let-bind`, `fmap`, `join`, `ap`, `kleisli`, `sequence`, `map-m`, `when`, `replicate` |
| `laws.typ` | Runtime checkers for the three monad laws plus the two functor laws |
| `free.typ` | `make(handlers:)` — derive a State-backed builder from named ops |
| `instances/identity.typ` | The trivial monad |
| `instances/maybe.typ` | `just`/`nothing`, short-circuit on absence |
| `instances/result.typ` | `ok`/`err`, short-circuit on error |
| `instances/state.typ` | `s -> (s, a)` with `get`, `put`, `modify`, `gets`, plus keyed helpers |
| `instances/reader.typ` | `env -> a` with `ask`, `asks`, `local` |
| `instances/writer.typ` | `(log, a)` over a user-supplied monoid; default log is `array` |

## Why not just use `typst-algorithmic`'s pattern?

`typst-algorithmic` is what inspired this — it builds a clever AST from
block-joined constructors. That pattern is great for *describing* a static
structure (a pseudocode listing). It is **not a monad**:

1. Sequencing is array `+` — a *monoid* operation, not a monad bind. Earlier
   actions cannot pass values to later ones.
2. There is no `pure`. A plain value cannot be lifted into the structure.
3. There is no `bind`. `Op1 >>= \x -> Op2(x)` is unrepresentable; every node
   is independent.
4. Effects are conflated with rendering. An "op" *is* its rendered content;
   there is no "describe a computation, then interpret it" separation.
5. Node shape is ad-hoc: a node may be `array | dict | content`, dispatched
   on `type()`. There is no contract a custom op must satisfy.

This package keeps the block-join ergonomics (constructors return 1-tuples
so `{ Op1; Op2 }` concatenates) but treats those actions as **State monad
values** that thread real data through a real interpreter. The "describe vs
run" split is preserved: `builder.eval(body)` is the only thing that
observes effects.

## Three idioms

### 1. Block-joined builder — the friendly surface

Use `free.make` when your DSL is "a sequence of named commands over some
state". This covers most real-world builders: configuration assemblers,
graph constructors, animation timelines, layout DSLs.

```typ
SomeEnv({ Set("x", 2); Add("x", 3) })
```

### 2. `do-bind` — sequencing with named results

When a later op needs the *value* of an earlier op (not just shared state),
use `do-bind`. Steps that need the previous value wrap themselves in
`let-bind`:

```typ
#import "@preview/monad:0.1.0": do-bind, let-bind, pure, state, maybe

#let prog = do-bind(state.monad, (
  state.put-at("x", 10),
  state.get-at("x"),
  let-bind(v => state.put-at("y", v * 2)),
))

#state.run(prog, (:))  // ((x: 10, y: 20), 20)
```

Same shape for any monad:

```typ
#let safe-div(a, b) = if b == 0 { maybe.nothing } else { maybe.just(a / b) }

#do-bind(maybe.monad, (
  safe-div(100, 5),
  let-bind(x => safe-div(x, 2)),
  let-bind(y => pure(maybe.monad, y + 1)),
))  // maybe.just(11) — short-circuits to nothing if any step fails
```

For explicit `bind` chains (`Op1 >>= \x -> Op2 x`) the raw `bind` and
`pure` are exported too.

### Control flow in builder blocks

`if` (with or without `else`) and `for` work inside builder block bodies.
`if false { ... }` simply contributes nothing to the sequence:

```typ
SomeEnv({
  Set("count", 0)
  for n in (1, 2, 3, 4) {
    Add("count", n)
  }
  if debug-mode {
    Set("note", "hello")
  }
})
```

### 3. Define your own instance — when nothing fits

A monad is just a dict `(pure:, bind:)`. Build one, run the law checkers
against samples, ship it.

```typ
#let my-monad = (pure: ..., bind: ...)

#let report = check-laws(my-monad, eq, (
  values: (...),
  actions: (...),
  "arrows-f": (...),
  "arrows-g": (...),
))

#assert(report.passed, message: repr(report.failures))
```

## The monad laws

A monad is only a monad if `pure` and `bind` satisfy:

- **Left identity** — `bind(pure(a), f) ≡ f(a)`
- **Right identity** — `bind(m, pure) ≡ m`
- **Associativity** — `bind(bind(m, f), g) ≡ bind(m, x => bind(f(x), g))`

`laws.check-laws` checks these by sampling. For monads whose values are
closures (State, Reader), supply `state-eq` / `reader-eq` so equality can
be observed by running.

## Layout

```
src/
├── lib.typ            # re-exports — `#import "@preview/monad:0.1.0": ...`
├── core.typ           # the protocol
├── laws.typ           # runtime law verifiers
├── free.typ           # operational builder
└── instances/         # reference monad instances

examples/              # ready-to-compile demos
tests/                 # tytanic test suite
```

## License

MIT.
