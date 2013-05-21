# stream-rpc

RPC over arbitrary streams

    rpc = require 'stream-rpc'

    client = rpc(timeout: 1000)
    server = rpc
      handle: (request, done) ->
        done(null, request)

    client.pipe(server).pipe(client)

or

    {json} = require 'stream-serializer'

    client
      .pipe(json)
      .pipe(serverConnectedSocket)
      .pipe(json)
      .pipe(client)

    server
      .pipe(json)
      .pipe(clientConnectedSocket)
      .pipe(json)
