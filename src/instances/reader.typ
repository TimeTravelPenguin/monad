// Reader monad.  M a = env -> a
//
// Threads an immutable environment through a computation. Useful for
// dependency injection — pass config/services once via `run`, read with
// `ask` anywhere in the chain.

#let monad = (
  pure: x => (env => x),
  bind: (m, k) => (env => k(m(env))(env)),
  fmap: (f, m) => (env => f(m(env))),
)

#let ask = env => env

#let asks(f) = env => f(env)

#let local(f, m) = env => m(f(env))

#let ask-at(key, default: none) = env => env.at(key, default: default)

#let run(m, env) = m(env)
