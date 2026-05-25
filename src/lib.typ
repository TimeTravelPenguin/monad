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
  ap, bind, do, do-bind, fmap, for-m, join, kleisli, let-bind, map-m, pure,
  replicate, seq, sequence, unless, void, when,
)

#import "laws.typ": (
  check-associativity, check-fmap-compose, check-fmap-identity, check-laws,
  check-left-identity, check-right-identity, reader-eq, state-eq,
)

#import "free.typ" as free
#import "instances/identity.typ" as identity
#import "instances/option.typ" as option
#import "instances/result.typ" as result
#import "instances/state.typ" as state
#import "instances/reader.typ" as reader
#import "instances/writer.typ" as writer
