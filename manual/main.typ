#import "@preview/tidy:0.4.3"

#import "/src/core.typ"
#import "/src/laws.typ"
#import "/src/free.typ"
#import "/src/instances/identity.typ" as identity
#import "/src/instances/maybe.typ" as maybe
#import "/src/instances/result.typ" as result
#import "/src/instances/state.typ" as state
#import "/src/instances/reader.typ" as reader
#import "/src/instances/writer.typ" as writer

#set document(
  title: "monad — user manual",
  author: "Phillip Smith",
)
#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm), numbering: "1")
#set par(justify: true)
#set text(size: 10pt)
#show heading.where(level: 1): it => pagebreak(weak: true) + it
#show link: set text(fill: blue.darken(20%))

#align(center)[
  #v(3cm)
  #text(28pt, weight: 700)[monad]
  #v(0.4cm)
  #text(14pt)[Build correct, lawful monadic DSLs in Typst.]
  #v(0.8cm)
  #text(10pt)[Version 0.1.0]
]

#v(1fr)

#align(center, block(width: 80%)[
  #set text(9pt)
  #set par(justify: false)
  This manual is generated with #link("https://github.com/Mc-Zen/tidy")[tidy].
  Every module of the library is rendered below with parameter types,
  return types, and runnable code examples. Pair this with the
  `README.md` for design rationale and the `examples/` directory for
  end-to-end programs.
])

#v(1fr)

#pagebreak()

#outline(depth: 2, indent: auto)

#let example-scope = (
  pure: core.pure,
  bind: core.bind,
  fmap: core.fmap,
  join: core.join,
  ap: core.ap,
  seq: core.seq,
  do: core.do,
  sequence: core.sequence,
  "map-m": core.map-m,
  "for-m": core.for-m,
  kleisli: core.kleisli,
  when: core.when,
  unless: core.unless,
  void: core.void,
  replicate: core.replicate,
  "let-bind": core.let-bind,
  "do-bind": core.do-bind,
  "check-laws": laws.check-laws,
  "check-left-identity": laws.check-left-identity,
  "check-right-identity": laws.check-right-identity,
  "check-associativity": laws.check-associativity,
  "check-fmap-identity": laws.check-fmap-identity,
  "check-fmap-compose": laws.check-fmap-compose,
  "state-eq": laws.state-eq,
  "reader-eq": laws.reader-eq,
  just: maybe.just,
  nothing: maybe.nothing,
  ok: result.ok,
  err: result.err,
  "from-maybe": maybe.from-maybe,
  "map-err": result.map-err,
  "unwrap-or": result.unwrap-or,
  free: free,
  identity: identity,
  maybe: maybe,
  result: result,
  state: state,
  reader: reader,
  writer: writer,
  lift: free.lift,
)

#let fixed-style = (
  show-outline: tidy.styles.default.show-outline,
  show-type: tidy.styles.default.show-type,
  show-function: tidy.styles.default.show-function,
  show-parameter-list: tidy.styles.default.show-parameter-list,
  show-parameter-block: tidy.styles.default.show-parameter-block,
  show-variable: tidy.styles.default.show-variable,
  show-reference: tidy.styles.default.show-reference,
  show-example: (..args) => tidy.show-example.show-example(
    ..args,
    layout: tidy.show-example.default-layout-example.with(
      code-block: block.with(radius: 3pt, stroke: .5pt + luma(200)),
      preview-block: block.with(radius: 3pt, fill: rgb("#e4e5ea")),
      col-spacing: 5pt,
      scale-preview: 100%,
    ),
  ),
)

#show raw.where(lang: "example"): it => tidy.show-example.show-example(
  raw(it.text, block: true, lang: "typ"),
  mode: "markup",
  scope: example-scope,
  layout: tidy.show-example.default-layout-example.with(
    code-block: block.with(radius: 3pt, stroke: .5pt + luma(200)),
    preview-block: block.with(radius: 3pt, fill: rgb("#e4e5ea")),
    col-spacing: 5pt,
    scale-preview: 100%,
  ),
)

#let render(path, name) = {
  let docs = tidy.parse-module(
    read(path),
    name: name,
    scope: example-scope,
  )
  tidy.show-module(
    docs,
    style: fixed-style,
    show-outline: false,
  )
}

= Introduction

The `monad` package gives you the building blocks for designing monadic
DSLs in Typst — like the State-flavored "builder" pattern popularized by
packages such as `typst-algorithmic`, but with proper monad structure
(`pure`, `bind`, the three monad laws) so your DSLs compose predictably.

There are three usage idioms:

+ *Block-joined builder* (`free.make`) — define your vocabulary as a dict
  of handlers; users write programs like `SomeEnv({ Op1; Op2 })`.
+ *Sequenced with named results* (`do-bind` + `let-bind`) — when later
  steps depend on earlier *values*, not just shared state. Works for
  every instance.
+ *Define your own instance* — a monad is just a dict
  `(pure: .., bind: ..)`. Build one; verify it with `check-laws`.

The next chapter (#emph[A guided tour]) walks through the abstraction
from scratch — recommended on a first read. The remaining chapters are
auto-generated reference documentation for every public symbol.

#include "tutorial.typ"

= Core combinators

The combinators in `src/core.typ` operate over an opaque *monad instance*:
a dict with at minimum `pure: a -> M a` and `bind: (M a, a -> M b) -> M b`.
Optional fields `fmap`, `join`, and `ap` are derived from `bind` if
absent.

#render("/src/core.typ", "core")

= Monad-law verifiers

Runtime checkers for the three monad laws (`bind`/`pure` interactions)
and the two functor laws (`fmap` interactions). Equality on monadic
values is supplied as a predicate — use `state-eq` / `reader-eq` for
monads whose values are closures.

#render("/src/laws.typ", "laws")

= Free / operational builder

`free.make` turns a dict of named state handlers into a State-backed
DSL. The resulting bundle exposes constructors (returning 1-tuples so
block-join sugar works), an interpreter, and the underlying State monad
instance.

#render("/src/free.typ", "free")

= Identity instance

The trivial monad: `M a = a`. Useful as a baseline and for tests.

#render("/src/instances/identity.typ", "identity")

= Maybe instance

`M a = just(a) | nothing`. Models computations that can absent without a
typed error. `bind` short-circuits on `nothing`.

#render("/src/instances/maybe.typ", "maybe")

= Result instance

`M a = ok(a) | err(e)`. Models computations that may fail with a typed
error value, threaded through `bind` unchanged on the error path.

#render("/src/instances/result.typ", "result")

= State instance

`M a = state -> (state, a)`. Threads a mutable-feeling state through a
pure computation. This is the engine behind every `free.make`-derived
builder.

#render("/src/instances/state.typ", "state")

= Reader instance

`M a = env -> a`. Threads an immutable environment — useful for
dependency injection without explicit parameter passing.

#render("/src/instances/reader.typ", "reader")

= Writer instance

`M a = (log, a)`. Accumulates a log alongside the computed value. The
log type must form a monoid; the default instance uses array
concatenation.

#render("/src/instances/writer.typ", "writer")
