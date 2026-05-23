#import "/tests/template.typ": test-page
#import "/src/lib.typ": bind, fmap, identity, option, pure, seq

#show: test-page

#assert.eq(pure(identity.monad, 7), 7)
#assert.eq(bind(identity.monad, 3, x => x + 1), 4)
#assert.eq(fmap(identity.monad, x => x * 2, 5), 10)
#assert.eq(seq(identity.monad, (1, 2, 3)), 3)

#assert.eq(pure(option.monad, 1), option.some(1))
#assert.eq(
  bind(option.monad, option.some(2), x => option.some(x + 1)),
  option.some(3),
)
#assert.eq(
  bind(option.monad, option.nothing, x => option.some(x + 1)),
  option.nothing,
)

core sanity OK
