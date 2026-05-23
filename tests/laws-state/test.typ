#import "/tests/template.typ": test-page
#import "/src/lib.typ": check-laws, state-eq, state

#show: test-page

#let sample-states = ((:), (x: 1), (x: 5, y: 10))
#let eq = state-eq(state.run, sample-states)

#let report = check-laws(state.monad, eq, (
  values: (1, 2),
  actions: (
    state.get-at("x", default: 0),
    state.put-at("x", 99),
    state.modify-at("x", v => v + 1, default: 0),
  ),
  "arrows-f": (
    x => state.put-at("x", x),
    x => state.modify-at("x", v => v + x, default: 0),
  ),
  "arrows-g": (
    x => state.put-at("y", x),
    x => state.get-at("x", default: x),
  ),
  "plain-fs": (x => x + 1,),
  "plain-gs": (x => x * 2,),
))
#assert(report.passed, message: repr(report.failures))

state-monad laws OK
