#import "../src/lib.typ": bind, pure, do, check-laws

#let counter-monad = (
  pure: x => (count: 0, value: x),
  bind: (m, k) => {
    let m2 = k(m.value)
    (count: m.count + m2.count + 1, value: m2.value)
  },
)

#let leaf(x) = (count: 0, value: x)

#let chained = bind(counter-monad, leaf(1), a =>
  bind(counter-monad, leaf(2), b =>
    bind(counter-monad, leaf(3), c =>
      pure(counter-monad, a + b + c))))

After three binds: #chained.

#let eq = (m1, m2) => m1 == m2
#let report = check-laws(
  counter-monad,
  eq,
  (
    values: (1, 2, 3),
    actions: (leaf(0), leaf(5), leaf(10)),
    "arrows-f": (x => leaf(x + 1), x => leaf(x * 2)),
    "arrows-g": (x => leaf(x - 1), x => leaf(x * 3)),
    "plain-fs": (x => x + 1,),
    "plain-gs": (x => x * 2,),
  ),
)

This "monad" violates the laws: #report.failures.len() failures detected. 
(Counting binds breaks associativity -- the left-leaning tree counts differently from the right-leaning
one.)
