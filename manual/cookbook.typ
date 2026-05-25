// Hand-written cookbook chapter — one realistic use case per instance.
// Included from main.typ; uses the shared example-scope via helpers.
// Setup that is shared across multiple example blocks lives in
// `_*-setup` raw bindings and is fed to `hidden-example` so the rendered
// code shows only the call site.

#import "helpers.typ": hidden-example, join-examples

= In practice

This chapter shows a worked use case for each instance the package ships.
The point is not exhaustive coverage but a concrete answer to the
question "when would I reach for this?" — picking the wrong monad for a
problem is the single most common cause of awkward code that "uses
monads" but does not benefit from them.

The following examples are deliberately small and runnable.

== Identity --- swappable no-effect baseline

The Identity monad on its own does nothing useful. Its job is to be the
*null effect* in code that is generic over a monad instance. Write a
combinator once for an arbitrary monad; pass `identity.monad` when you
do not want effects, swap in `result.monad` or `state.monad` later when
you do.

A small example: a transformation pipeline parameterised by its
effect. With Identity, the pipeline is plain function composition.

#let _pipeline-setup = ```typ
#let pipeline(monad, steps, x) = {
  let acc = pure(monad, x)
  for f in steps {
    acc = bind(monad, acc, f)
  }
  acc
}
```
#join-examples(_pipeline-setup, ```typ
#pipeline(identity.monad, (
  x => x + 1,
  x => x * 2,
  x => x - 3,
), 10)
```)

Swap the monad and the same `pipeline` definition handles error
short-circuiting, accumulated logs, or threaded state without any
change to the calling code:

#hidden-example(_pipeline-setup, ```typ
#pipeline(result.monad, (
  x => result.ok(x + 1),
  x => if x > 100 { result.err("overflow") } else { result.ok(x * 2) },
  x => result.ok(x - 3),
), 10)
```)

== Option --- chained lookups where any step may be absent

Reach for Option when you have a sequence of lookups, each of which
could yield "nothing here". The classic shape: lookup a thing, then
look up something derived from it, then derive again. Without a monad,
this becomes a tower of `if-some` checks; with `do-bind`, the chain
reads top-to-bottom and short-circuits the moment any step is absent.

#let _option-setup = ```typ
#let users = (
  alice: (org: "acme"),
  bob: (org: "globex"),
)
#let orgs = (
  acme: (plan: "pro"),
  globex: (plan: "free"),
)
#let lookup(dict, key) = if key in dict {
  option.some(dict.at(key))
} else {
  option.nothing
}
```

#join-examples(_option-setup, ```typ
#do-bind(option.monad, (
  lookup(users, "alice"),
  let-bind(user => lookup(orgs, user.org)),
  let-bind(org => pure(option.monad, org.plan)),
))
```)

If any link in the chain is missing, the rest of the chain does not
run and the whole expression is `nothing`:

#hidden-example(_option-setup, ```typ
#do-bind(option.monad, (
  lookup(users, "carol"),
  let-bind(user => lookup(orgs, user.org)),
  let-bind(org => pure(option.monad, org.plan)),
))
```)

== Result --- validation pipeline with typed errors

Result is Option with a typed failure value. Reach for it when the
*reason* a step failed matters — when "nothing" is not enough and the
caller needs to know what went wrong. The natural use case is input
validation: each step parses or checks the input; the first failure
short-circuits and the error survives to the caller.

#let _result-setup = ```typ
#let parse-int-strict(s) = {
  if type(s) != str {
    result.err("expected a string, got " + type(s))
  } else if s.contains(regex("[^0-9]")) {
    result.err("not a valid integer: " + s)
  } else {
    let n = int(s)
    result.ok(n)
  }
}
#let must-be-positive(n) = if n > 0 {
  result.ok(n)
} else {
  result.err("must be positive, got " + str(n))
}
#let must-be-small(n) = if n < 100 {
  result.ok(n)
} else {
  result.err(
    "must be less than 100, got " + str(n)
  )
}
#let parse(s) = do-bind(
  result.monad, (
    parse-int-strict(s),
    let-bind(must-be-positive),
    let-bind(must-be-small),
))
```

#join-examples(_result-setup, ```typ
#parse("42")
```)

A bad input fails at the first violated rule and carries the message
back unchanged through every subsequent step:

#hidden-example(_result-setup, ```typ
#parse("not a number")

#parse("250")
```)

== State --- threading a counter through a build

State is the right tool whenever many disparate steps need to read or
update some shared "context" — figure numbers, section labels, a list
of registered citations, a running cost or weight. The state dict is
arbitrary; you decide what lives in it.

A common Typst use is automatic numbering. The action `next-figure`
increments the counter under `"counter"` and returns the new value.
Subsequent actions read the value and use it.

#pagebreak(weak: true)

```example
#let next-figure = state.modify-at("counter", n => n + 1, default: 0)

#let captions = do-bind(state.monad, (
  next-figure,
  let-bind(n => state.put-at(
    "intro",
    "Figure " + str(n) + ": Overview",
  )),
  next-figure,
  let-bind(n => state.put-at(
    "data",
    "Figure " + str(n) + ": Data",
  )),
  next-figure,
  let-bind(n => state.put-at(
    "summary",
    "Figure " + str(n) + ": Summary",
  )),
))

#state.run(captions, (:))
```

The runs are reproducible: feed the same initial state and you get
the same final state, every time. Nothing inside `captions` is
mutable in the usual sense — `state.put-at` returns a *new* state and
`bind` threads it through.

== Reader --- dependency injection through a config

Reader is for "I need this configuration value, but I don't want to
plumb it through every function call". Pass the environment once at
the top via `reader.run`; read it inside any action via `reader.ask`
or `reader.ask-at`. The environment is read-only — every action sees
the same value unless you scope a local override with `reader.local`.

The classic use is per-theme rendering. The same `render-heading`
action gives different output depending on which theme is supplied at
the call site.

```example
#let render-heading(text) = do-bind(reader.monad, (
  reader.ask-at("theme"),
  let-bind(theme => pure(reader.monad,
    if theme == "dark" {
      "[DARK] " + text
    } else if theme == "print" {
      "« " + text + " »"
    } else {
      "** " + text + " **"
    })),
))

#reader.run(
  render-heading("Introduction"),
  (theme: "dark"),
)

#reader.run(
  render-heading("Introduction"),
  (theme: "print"),
)
```

== Writer --- collecting warnings while validating

Writer accumulates a log alongside the value. Reach for it when a
computation needs to emit auxiliary facts as it runs: warnings, audit
records, citation entries, debug traces. The log type must form a
monoid; the default instance uses arrays under concatenation, so
`tell` appends to a list of records.

A natural fit is non-fatal validation — checks that should record a
warning rather than abort. The result is `(warnings, value)`.

#pagebreak(weak: true)

#let _writer-setup = ```typ
#let validate-field(name, value) = {
  if value == none {
    bind(writer.monad,
      writer.tell(("missing field: " + name,)),
      _ => pure(writer.monad, none))
  } else {
    pure(writer.monad, value)
  }
}

#let validate-form(data) = sequence(
  writer.monad, (
    validate-field(
      "name",
      data.at("name", default: none),
    ),
    validate-field(
      "email",
      data.at("email", default: none),
    ),
    validate-field(
      "age",
      data.at("age", default: none),
    ),
))
```

#join-examples(
  sep: "\n\n",
  _writer-setup,
  ```typ
  #validate-form((
    name: "Alice",
    email: none,
    age: 30,
  ))
  ```,
)

A clean form yields an empty warning list and the final value:

#hidden-example(_writer-setup, ```typ
#validate-form((
  name: "Alice",
  email: "a@b.c",
  age: 30,
))
```)

== Picking the right monad

The instances answer different shapes of question. A quick guide:

#table(
  columns: 2,
  inset: 6pt,
  align: (left, left),
  stroke: 0.5pt + luma(180),
  [*Use*], [*When you need*],
  [Identity], [a no-effect baseline for monad-generic code],
  [Option], [chained lookups that may produce no value],
  [Result], [chained validation/parsing with typed failure reasons],
  [State], [a counter, accumulator, or evolving context shared across steps],
  [Reader], [config or dependencies passed once, read anywhere],
  [Writer], [non-fatal warnings, audit logs, or other side records],
)

When more than one fits, you can either pick the simplest one that
covers your needs, or combine effects by writing a custom instance.
`check-laws` will tell you whether your hybrid is still a lawful
monad.
