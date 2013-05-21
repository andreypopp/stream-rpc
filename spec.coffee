{ok, equal} = require 'assert'
through = require 'through'
rpc = require './src'

describe 'stream-rpc', ->

  describe 'echo server', ->


    it 'works', (done) ->

      client = rpc()
      server = rpc()
      client.pipe(server).pipe(client)

      client.call 'hello', (err, response) ->
        equal response, 'hello'
        done()

    it 'works through some stream', (done) ->

      client = rpc()
      server = rpc()
      client.pipe(through()).pipe(server).pipe(through()).pipe(client)

      client.call 'hello', (err, response) ->
        equal response, 'hello'
        done()

    it 'times out', (done) ->

      client = rpc(name: 'client', timeout: 30)
      server = rpc name: 'server', handle: (request, done) ->
        setTimeout (-> 
          done(null, request)
        ), 50
      client.pipe(server).pipe(client)

      client.call 'hello', (err, response) ->
        ok err instanceof Error
        equal response, undefined
        done()
