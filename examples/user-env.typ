#import "../src/lib.typ": free

#let builder = free.make(
  handlers: (
    Set: (key, val) => state => {
      let s = state
      s.insert(key, val)
      (s, val)
    },
    Add: (key, n) => state => {
      let cur = state.at(key, default: 0)
      let next = cur + n
      let s = state
      s.insert(key, next)
      (s, next)
    },
    Get: key => state => (state, state.at(key, default: none)),
  ),
)

#let Set = builder.ops.Set
#let Add = builder.ops.Add
#let Get = builder.ops.Get
#let SomeEnv = builder.eval

#let env = SomeEnv({
  Set("x", 2)
  Add("x", 3)
})

The final value is #env.value.

The full state dict is #env.state.

#let program = SomeEnv({
  Set("count", 0)
  Add("count", 10)
  Add("count", 5)
  Set("name", "world")
})

After the program: state = #program.state, last value = #program.value.
