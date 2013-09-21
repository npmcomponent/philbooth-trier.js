'use strict'

{ assert } = require 'chai'
spooks = require 'spooks'

modulePath = '../src/trier'

suite 'trier:', ->
  test 'require does not throw', ->
    assert.doesNotThrow ->
      require modulePath

  test 'require returns object', ->
    assert.isObject require modulePath

  suite 'require:', ->
    trier = undefined

    setup ->
      trier = require modulePath

    teardown ->
      trier = undefined

    test 'exec function is exported', ->
      assert.isFunction trier.exec

    test 'exec throws when options is null', ->
      assert.throws ->
        trier.exec null

    test 'exec does not throw when options is object', ->
      assert.doesNotThrow ->
        trier.exec {}

    suite 'when immediately:', ->
      log = predicate = action = fail = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: true }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        context = {}
        args = [ 'foo', 'bar' ]
        trier.exec { when: predicate, action, fail, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = context = args = undefined

      test 'predicate was called once', ->
        assert.strictEqual log.counts.predicate, 1

      test 'predicate was passed correct arguments', ->
        assert.lengthOf log.args.predicate[0], 2
        assert.strictEqual log.args.predicate[0][0], 'foo'
        assert.strictEqual log.args.predicate[0][1], 'bar'

      test 'predicate was applied to correct context', ->
        assert.strictEqual log.these.predicate[0], context

      test 'action was called once', ->
        assert.strictEqual log.counts.action, 1

      test 'action was passed correct arguments', ->
        assert.lengthOf log.args.action[0], 2
        assert.strictEqual log.args.action[0][0], 'foo'
        assert.strictEqual log.args.action[0][1], 'bar'

      test 'action was applied to correct context', ->
        assert.strictEqual log.these.action[0], context

      test 'fail was not called', ->
        assert.strictEqual log.counts.fail, 0

    suite 'when fail 3:', ->
      log = predicate = action = fail = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        context = {}
        args = [ 'baz' ]
        trier.exec { when: predicate, action, fail, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = context = args = undefined

      test 'predicate was called three times', ->
        assert.strictEqual log.counts.predicate, 3

      test 'predicate was passed correct arguments first time', ->
        assert.lengthOf log.args.predicate[0], 1
        assert.strictEqual log.args.predicate[0][0], 'baz'

      test 'predicate was applied to correct context first time', ->
        assert.strictEqual log.these.predicate[0], context

      test 'predicate was passed correct arguments second time', ->
        assert.lengthOf log.args.predicate[1], 1
        assert.strictEqual log.args.predicate[1][0], 'baz'

      test 'predicate was applied to correct context second time', ->
        assert.strictEqual log.these.predicate[1], context

      test 'predicate was passed correct arguments third time', ->
        assert.lengthOf log.args.predicate[2], 1
        assert.strictEqual log.args.predicate[2][0], 'baz'

      test 'predicate was applied to correct context third time', ->
        assert.strictEqual log.these.predicate[2], context

      test 'action was not called', ->
        assert.strictEqual log.counts.action, 0

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

      test 'fail was passed correct arguments', ->
        assert.lengthOf log.args.fail[0], 1
        assert.strictEqual log.args.fail[0][0], 'baz'

      test 'fail was applied to correct context', ->
        assert.strictEqual log.these.fail[0], context

    suite 'when fail 5:', ->
      log = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.exec { when: predicate, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicate = action = fail = undefined

      test 'predicate was called five times', ->
        assert.strictEqual log.counts.predicate, 5

      test 'action was not called', ->
        assert.strictEqual log.counts.action, 0

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'when fail exponential:', ->
      log = timestamps = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = []
        predicate = spooks.fn {
          name: 'predicate',
          log,
          result: false,
          callback: ->
            timestamps.push Date.now()
        }
        action = spooks.fn { name: 'action', log, callback: done }
        fail = spooks.fn { name: 'fail', log, callback: done }
        timestamps.push Date.now()
        trier.exec { when: predicate, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = timestamps = predicate = action = fail = undefined

      test 'five timestamps were recorded', ->
        assert.lengthOf timestamps, 5

      test 'first interval is immediate', ->
        assert.isTrue timestamps[1] < timestamps[0] + 16

      test 'second interval is about 32 ms', ->
        assert.isTrue timestamps[2] > timestamps[1] + 16
        assert.isTrue timestamps[2] < timestamps[1] + 48

      test 'third interval is about 64 ms', ->
        assert.isTrue timestamps[3] > timestamps[2] + 48
        assert.isTrue timestamps[3] < timestamps[2] + 80

      test 'fourth interval is about 128 ms', ->
        assert.isTrue timestamps[4] > timestamps[3] + 112
        assert.isTrue timestamps[4] < timestamps[3] + 144

    suite 'until immediately:', ->
      log = predicate = action = fail = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: true, callback: done }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        context = {}
        args = [ 'foo', 'bar' ]
        trier.exec { until: predicate, action, fail, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = context = args = undefined

      test 'predicate was called once', ->
        assert.strictEqual log.counts.predicate, 1

      test 'predicate was passed correct arguments', ->
        assert.lengthOf log.args.predicate[0], 2
        assert.strictEqual log.args.predicate[0][0], 'foo'
        assert.strictEqual log.args.predicate[0][1], 'bar'

      test 'predicate was applied to correct context', ->
        assert.strictEqual log.these.predicate[0], context

      test 'action was called once', ->
        assert.strictEqual log.counts.action, 1

      test 'action was passed correct arguments', ->
        assert.lengthOf log.args.action[0], 2
        assert.strictEqual log.args.action[0][0], 'foo'
        assert.strictEqual log.args.action[0][1], 'bar'

      test 'action was applied to correct context', ->
        assert.strictEqual log.these.action[0], context

      test 'fail was not called', ->
        assert.strictEqual log.counts.fail, 0

    suite 'until fail 3:', ->
      log = predicate = action = fail = context = args = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        context = {}
        args = [ 'baz' ]
        trier.exec { until: predicate, action, fail, context, args, interval: 0, limit: 3 }

      teardown ->
        log = predicate = action = fail = context = args = undefined

      test 'predicate was called three times', ->
        assert.strictEqual log.counts.predicate, 3

      test 'predicate was passed correct arguments first time', ->
        assert.lengthOf log.args.predicate[0], 1
        assert.strictEqual log.args.predicate[0][0], 'baz'

      test 'predicate was applied to correct context first time', ->
        assert.strictEqual log.these.predicate[0], context

      test 'predicate was passed correct arguments second time', ->
        assert.lengthOf log.args.predicate[1], 1
        assert.strictEqual log.args.predicate[1][0], 'baz'

      test 'predicate was applied to correct context second time', ->
        assert.strictEqual log.these.predicate[1], context

      test 'predicate was passed correct arguments third time', ->
        assert.lengthOf log.args.predicate[2], 1
        assert.strictEqual log.args.predicate[2][0], 'baz'

      test 'predicate was applied to correct context third time', ->
        assert.strictEqual log.these.predicate[2], context

      test 'action was called three times', ->
        assert.strictEqual log.counts.action, 3

      test 'action was passed correct arguments first time', ->
        assert.lengthOf log.args.action[0], 1
        assert.strictEqual log.args.action[0][0], 'baz'

      test 'action was applied to correct context first time', ->
        assert.strictEqual log.these.action[0], context

      test 'action was passed correct arguments second time', ->
        assert.lengthOf log.args.action[1], 1
        assert.strictEqual log.args.action[1][0], 'baz'

      test 'action was applied to correct context second time', ->
        assert.strictEqual log.these.action[1], context

      test 'action was passed correct arguments third time', ->
        assert.lengthOf log.args.action[2], 1
        assert.strictEqual log.args.action[2][0], 'baz'

      test 'action was applied to correct context third time', ->
        assert.strictEqual log.these.action[2], context

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

      test 'fail was passed correct arguments', ->
        assert.lengthOf log.args.fail[0], 1
        assert.strictEqual log.args.fail[0][0], 'baz'

      test 'fail was applied to correct context', ->
        assert.strictEqual log.these.fail[0], context

    suite 'until fail 5:', ->
      log = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        predicate = spooks.fn { name: 'predicate', log, result: false }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        trier.exec { until: predicate, action, fail, interval: 0, limit: 5 }

      teardown ->
        log = predicate = action = fail = undefined

      test 'predicate was called five times', ->
        assert.strictEqual log.counts.predicate, 5

      test 'action was called five times', ->
        assert.strictEqual log.counts.action, 5

      test 'fail was called once', ->
        assert.strictEqual log.counts.fail, 1

    suite 'until fail exponential:', ->
      log = timestamps = predicate = action = fail = undefined

      setup (done) ->
        log = {}
        timestamps = []
        predicate = spooks.fn {
          name: 'predicate',
          log,
          result: false,
          callback: ->
            timestamps.push Date.now()
        }
        action = spooks.fn { name: 'action', log }
        fail = spooks.fn { name: 'fail', log, callback: done }
        timestamps.push Date.now()
        trier.exec { until: predicate, action, fail, interval: -32, limit: 4 }

      teardown ->
        log = timestamps = predicate = action = fail = undefined

      test 'five timestamps were recorded', ->
        assert.lengthOf timestamps, 5

      test 'first interval is immediate', ->
        assert.isTrue timestamps[1] < timestamps[0] + 16

      test 'second interval is about 32 ms', ->
        assert.isTrue timestamps[2] > timestamps[1] + 16
        assert.isTrue timestamps[2] < timestamps[1] + 48

      test 'third interval is about 64 ms', ->
        assert.isTrue timestamps[3] > timestamps[2] + 48
        assert.isTrue timestamps[3] < timestamps[2] + 80

      test 'fourth interval is about 128 ms', ->
        assert.isTrue timestamps[4] > timestamps[3] + 112
        assert.isTrue timestamps[4] < timestamps[3] + 144

