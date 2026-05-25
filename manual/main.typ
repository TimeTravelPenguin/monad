#import "@preview/tidy:0.4.3"
#import "helpers.typ": (
  example-scope, fixed-style, hidden-example, render-example,
)

#let ver = version(..sys.inputs.at("version").split(".").map(int))

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
  #text(14pt)[Build composable Typst DSLs with lawful sequencing..]
  #v(0.8cm)
  #text(10pt)[Version #ver]
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

#show raw.where(lang: "example"): it => render-example(it)

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

#include "cookbook.typ"

The rest of this manual is reference: every public function with its
parameter list, return type, and a runnable example.

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

= Option instance

`M a = some(a) | nothing`. Models computations that may produce no value
(Rust's `Option<T>`). `bind` short-circuits on `nothing`: once a chain
produces `nothing`, every subsequent step is skipped.

#render("/src/instances/option.typ", "option")

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
