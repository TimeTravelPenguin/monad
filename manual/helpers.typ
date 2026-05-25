// Shared scope and example helpers for the manual.
//
// `main.typ` uses these to wire up tidy. `cookbook.typ` imports
// `hidden-example` so its sections can hoist repeated setup out of
// the rendered code blocks.

#import "@preview/tidy:0.4.3"

#import "/src/core.typ"
#import "/src/laws.typ"
#import "/src/free.typ"
#import "/src/instances/identity.typ" as identity
#import "/src/instances/option.typ" as option
#import "/src/instances/result.typ" as result
#import "/src/instances/state.typ" as state
#import "/src/instances/reader.typ" as reader
#import "/src/instances/writer.typ" as writer

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
  some: option.some,
  nothing: option.nothing,
  ok: result.ok,
  err: result.err,
  "map-err": result.map-err,
  "unwrap-or": result.unwrap-or,
  free: free,
  identity: identity,
  option: option,
  result: result,
  state: state,
  reader: reader,
  writer: writer,
  lift: free.lift,
)

#let _layout = tidy.show-example.default-layout-example.with(
  code-block: block.with(radius: 3pt, stroke: .5pt + luma(200)),
  preview-block: block.with(radius: 3pt, fill: rgb("#e4e5ea")),
  col-spacing: 5pt,
  scale-preview: 100%,
)

// Custom tidy style: the default style plus a layout-pinned show-example.
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
    layout: _layout,
  ),
)

// Render an `example` raw block with the shared scope.
#let render-example(body) = tidy.show-example.show-example(
  raw(body.text, block: true, lang: "typ"),
  mode: "markup",
  scope: example-scope,
  layout: _layout,
)

// Run an example with a hidden setup preamble. `setup` is a `raw` block
// whose contents are prepended invisibly before eval; only `body` is
// shown. Use when several blocks share scaffolding that should not
// repeat in the rendered manual.
#let hidden-example(setup, body) = tidy.show-example.show-example(
  raw(body.text, block: true, lang: "typ"),
  mode: "markup",
  scope: example-scope,
  preamble: setup.text + "\n",
  layout: _layout,
)

// Like `hidden-example` but for multiple bodies that share the same setup.
#let join-examples(
  ..bodies,
  setup: ``,
  sep: "\n",
) = tidy.show-example.show-example(
  raw(bodies.pos().map(it => it.text).join(sep), block: true, lang: "typ"),
  mode: "markup",
  scope: example-scope,
  preamble: setup.text + "\n",
  layout: _layout,
)
