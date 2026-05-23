// monad — public entry point.
//
// Import the whole library with a prefix:
//
//   #import "@preview/monad:0.1.0" as m
//
//   m.state.monad             // the State instance
//   m.do(m.state.monad, body) // sequence actions
//   m.free.make(handlers: ..) // operational DSL builder
//
// Or pull pieces directly:
//
//   #import "@preview/monad:0.1.0": do, bind, pure, free, state

#import "core.typ": (
  pure,
  bind,
  fmap,
  join,
  ap,
  seq,
  do,
  sequence,
  map-m,
  for-m,
  kleisli,
  when,
  unless,
  void,
  replicate,
)

#import "laws.typ": (
  check-laws,
  check-left-identity,
  check-right-identity,
  check-associativity,
  check-fmap-identity,
  check-fmap-compose,
  state-eq,
  reader-eq,
)

#import "free.typ" as free
#import "instances/identity.typ" as identity
#import "instances/maybe.typ" as maybe
#import "instances/result.typ" as result
#import "instances/state.typ" as state
#import "instances/reader.typ" as reader
#import "instances/writer.typ" as writer
