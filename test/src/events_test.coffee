describe 'XMLHttpRequest', ->
  beforeEach ->
    @xhr = new XMLHttpRequest
    @dripUrl = 'https://localhost:8911/_/drip'
    @dripJson = drips: 3, size: 1000, ms: 50, length: true

  describe 'new-school events', ->
    beforeEach ->
      @events = []
      @endFired = false
      @eventCheck = -> null  # replaced by tests
      @xhr.addEventListener 'loadstart', (event) =>
        expect(event.type).to.equal 'loadstart'
        expect(@endFired).to.equal false
        @events.push event
      @xhr.addEventListener 'progress', (event) =>
        expect(event.type).to.equal 'progress'
        expect(@endFired).to.equal false
        @events.push event
      @xhr.addEventListener 'load', (event) =>
        expect(event.type).to.equal 'load'
        expect(@endFired).to.equal false
        @events.push event
      @xhr.addEventListener 'loadend', (event) =>
        expect(event.type).to.equal 'loadend'
        expect(@endFired).to.equal false
        @endFired = 'loadend already fired'
        @events.push event
        @eventCheck()
      @xhr.addEventListener 'error', (event) =>
        expect(event.type).to.equal 'error'
        expect(@endFired).to.equal false
        @events.push event
      @xhr.addEventListener 'abort', (event) =>
        expect(event.type).to.equal 'abort'
        expect(@endFired).to.equal false
        @events.push event

    describe 'for a successful fetch with Content-Length set', ->
      beforeEach ->
        @xhr.open 'POST', @dripUrl
        @xhr.send JSON.stringify(@dripJson)

      it 'events have the correct target', (done) ->
        @eventCheck = =>
          for event in @events
            expect(event.target).to.equal @xhr
          done()

      it 'events have the correct bubbling setup', (done) ->
        @eventCheck = =>
          for event in @events
            expect(event.bubbles).to.equal false
            expect(event.cancelable).to.equal false
          done()

      it 'events have the correct progress info', (done) ->
        @eventCheck = =>
          for event in @events
            switch event.type
              when 'loadstart'
                expect(event.loaded).to.equal 0
                expect(event.lengthComputable).to.equal false
                expect(event.total).to.equal 0
              when 'load', 'loadend'
                expect(event.loaded).to.equal 3000
                expect(event.lengthComputable).to.equal true
                expect(event.total).to.equal 3000
              when 'progress'
                if event.lengthComputable
                  expect(event.loaded).to.be.gte 0
                  expect(event.loaded).to.be.lte 3000
                  expect(event.total).to.equal 3000
                else
                  expect(event.loaded).to.be.gte 0
                  expect(event.total).to.equal 0
          done()

      it 'events include at least one intermediate progress event', (done) ->
        @eventCheck = =>
          found = 'no suitable progress event emitted'
          for event in @events
            continue unless event.type is 'progress'
            continue unless event.loaded > 0
            continue unless event.loaded < event.total
            found = true
          expect(found).to.equal true
          done()

    describe 'for a successful fetch without Content-Length set', ->
      beforeEach ->
        @xhr.open 'POST', @dripUrl
        @dripJson.length = false
        @xhr.send JSON.stringify(@dripJson)

      it 'events have the correct progress info', (done) ->
        @eventCheck = =>
          for event in @events
            expect(event.lengthComputable).to.equal false
            expect(event.total).to.equal 0
            switch event.type
              when 'loadstart'
                expect(event.loaded).to.equal 0
              when 'load', 'loadend'
                expect(event.loaded).to.equal 3000
              when 'progress'
                expect(event.loaded).to.be.gte 0
          done()

      it 'events include at least one intermediate progress event', (done) ->
        @eventCheck = =>
          found = 'no suitable progress event emitted'
          for event in @events
            continue unless event.type is 'progress'
            continue if event.loaded is 0
            continue if event.loaded is 3000
            found = true
          expect(found).to.equal true
          done()
