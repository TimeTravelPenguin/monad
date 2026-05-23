#import "/tests/template.typ": test-page
#import "/src/lib.typ": pure, bind, fmap, seq, identity, maybe

#show: test-page

#assert.eq(pure(identity.monad, 7), 7)
#assert.eq(bind(identity.monad, 3, x => x + 1), 4)
#assert.eq(fmap(identity.monad, x => x * 2, 5), 10)
#assert.eq(seq(identity.monad, (1, 2, 3)), 3)

#assert.eq(pure(maybe.monad, 1), maybe.just(1))
#assert.eq(bind(maybe.monad, maybe.just(2), x => maybe.just(x + 1)), maybe.just(3))
#assert.eq(bind(maybe.monad, maybe.nothing, x => maybe.just(x + 1)), maybe.nothing)

core sanity OK
