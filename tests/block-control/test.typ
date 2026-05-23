#import "/tests/template.typ": test-page
#import "/src/lib.typ": free

#show: test-page

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
#let eval = builder.eval

#let with-true = eval({
  Set("x", 0)
  if true { Add("x", 5) }
})
#assert.eq(with-true.value, 5)
#assert.eq(with-true.state.x, 5)

#let with-false = eval({
  Set("x", 7)
  if false { Add("x", 100) }
})
#assert.eq(with-false.state.x, 7)

#let with-else = eval({
  Set("x", 0)
  if false { Add("x", 1) } else { Add("x", 2) }
})
#assert.eq(with-else.state.x, 2)

#let with-for = eval({
  Set("count", 0)
  for n in (1, 2, 3, 4) {
    Add("count", n)
  }
})
#assert.eq(with-for.state.count, 10)

#let nested = eval({
  Set("n", 0)
  for i in range(3) {
    if calc.even(i) {
      Add("n", i * 10)
    } else {
      Add("n", i)
    }
  }
})
#assert.eq(nested.state.n, 0 + 1 + 20)

block-control OK
