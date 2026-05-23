// Reader monad.  M a = env -> a
//
// Threads an immutable environment through a computation. Useful for
// dependency injection — pass config/services once via `run`, read with
// `ask` anywhere in the chain.

/// Reader monad instance. Values are functions `env -> a`. The environment
/// is read-only — useful for dependency injection without explicit param
/// threading.
///
/// ```example
/// #let prog = bind(reader.monad, reader.ask, env => pure(reader.monad, env.host))
/// #reader.run(prog, (host: "example.com", port: 80))
/// ```
///
/// -> dictionary
#let monad = (
  pure: x => (env => x),
  bind: (m, k) => (env => k(m(env))(env)),
  fmap: (f, m) => (env => f(m(env))),
)

/// Action that returns the current environment unchanged.
/// -> function
#let ask = env => env

/// Read a projected view of the environment.
/// -> function
#let asks(
  /// `env -> a`. -> function
  f,
) = env => f(env)

/// Run an action under a temporarily-modified environment.
///
/// ```example
/// #reader.run(reader.local(e => e + (port: 443), reader.ask), (host: "x"))
/// ```
///
/// -> function
#let local(
  /// `env -> env`. -> function
  f,
  /// Action to run under the transformed env. -> function
  m,
) = env => m(f(env))

/// Read a single key from a dict-shaped environment.
/// -> function
#let ask-at(
  /// -> any
  key,
  /// -> any
  default: none,
) = env => env.at(key, default: default)

/// Run a Reader action against an environment.
/// -> any
#let run(
  /// -> function
  m,
  /// -> dictionary
  env,
) = m(env)
