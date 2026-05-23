#import "/tests/template.typ": test-page
#import "/src/lib.typ": check-laws, identity, option, result

#show: test-page

#let eq = (a, b) => a == b

#let id-report = check-laws(identity.monad, eq, (
  values: (1, 2, 3),
  actions: (10, 20),
  "arrows-f": (x => x + 1, x => x * 2),
  "arrows-g": (x => x - 1, x => x * 3),
  "plain-fs": (x => x + 1,),
  "plain-gs": (x => x * 2,),
))
#assert(id-report.passed, message: repr(id-report.failures))

#let option-report = check-laws(option.monad, eq, (
  values: (1, 2),
  actions: (option.some(5), option.nothing),
  "arrows-f": (x => option.some(x + 1), x => if x > 0 { option.some(x) } else { option.nothing }),
  "arrows-g": (x => option.some(x * 2), x => option.nothing),
  "plain-fs": (x => x + 1,),
  "plain-gs": (x => x * 2,),
))
#assert(option-report.passed, message: repr(option-report.failures))

#let result-report = check-laws(result.monad, eq, (
  values: (1, 2),
  actions: (result.ok(5), result.err("boom")),
  "arrows-f": (x => result.ok(x + 1), x => result.err("fail")),
  "arrows-g": (x => result.ok(x * 2), x => result.ok(x - 1)),
  "plain-fs": (x => x + 1,),
  "plain-gs": (x => x * 2,),
))
#assert(result-report.passed, message: repr(result-report.failures))

pure-monad laws OK
