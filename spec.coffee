{ok, equal, deepEqual} = require 'assert'
through = require 'through'
rpc = require './src'
serialize = require('stream-serializer')()
net = require 'net'

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


  describe 'network case', ->

    it 'works', ->
      clientO = rpc()
      client = serialize clientO
      server = serialize rpc()
      sockServer = net.createServer (sock) ->
        server.pipe(sock).pipe(server)
      sockServer.listen 12345, ->
        client.pipe(net.connect(12345)).pipe(client)
        clientO.call {hello: 'world'}, (err, response) ->
          deepEqual response, {hello: 'world'}
          sockServer.close()

    it 'allows to serialize an error', ->
      clientO = rpc()
      client = serialize clientO
      server = serialize rpc
        handle: (request, done) ->
          done(new Error('x'))
      sockServer = net.createServer (sock) ->
        server.pipe(sock).pipe(server)
      sockServer.listen 12345, ->
        client.pipe(net.connect(12345)).pipe(client)
        clientO.call {hello: 'world'}, (err, response) ->
          deepEqual err, new Error('x')
          deepEqual response, undefined
          sockServer.close()
