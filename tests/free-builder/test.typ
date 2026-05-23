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
#let eval-with = builder.eval-with

#let env = eval({
  Set("x", 2)
  Add("x", 3)
})

#assert.eq(env.value, 5)
#assert.eq(env.state, (x: 5))

#let chained = eval({
  Set("count", 0)
  Add("count", 10)
  Add("count", 5)
})

#assert.eq(chained.value, 15)
#assert.eq(chained.state.count, 15)

#let with-init = eval-with({ Add("n", 1) }, start: (n: 99))
#assert.eq(with-init.value, 100)

free-builder OK
