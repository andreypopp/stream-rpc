Stream-RPC
==========

RPC calls over arbitrary streams in Node and a Browser

This library provides a way to send a request and get a response on it over
an arbitrary stream. It works both in Node and in a browser (via browserify_).

This documentation is organized as follows:

.. contents::
   :local:

Note that this is not a full-blown RPC solution but a just primitive building
block which correlates request with corresponding response over streams.

Getting started
---------------

To get started, install ``stream-rpc`` package via ``npm``::

    % npm install stream-rpc

After that you will be able to use ``stream-rpc`` library in you code.  The
basic usage example is as follows::

    var rpc = require('stream-rpc'),
        client = rpc(),
        server = rpc({
          handle: function(request, done) {
            done(null, 'Hello, ' + request.name + '!');  
          }
        });

    client.pipe(server).pipe(client);

    client.call({name: 'World'}, function(response) {
      console.log(response); // prints 'Hello, World!'
    });

Note that in the example above ``client`` and ``server`` streams are connected
directly, while in a real-world scenario you probably would like them to be
connected over the network.

RPC over WebSockets
-------------------

Now, we will provide an example of an RPC subsystem over WebSockets. For that we
need `websocket-stream`_ library which wraps WebSocket (both client and
server) connection in a stream.

We also need a way to serialize values inside streams, let's do it in a plain
JSON::

    var through = require('through');

    var serialize = function() {
      return through(function(data) {
        this.push(JSON.stringify(data));
      });
    };

    var deserialize = function() {
      return through(function(data) {
        this.push(JSON.parse(data));
      });
    };

Please note through_ library which we use to create ``serialize`` and
``deserialize`` stream transformers.

On a server you need to compose a stream pipeline on each connection::

    var websocket = require('websocket-stream'),
      rpc = require('stream-rpc'),
      ws = require('ws'),
      wss = new ws.Server({port: 3000}),
      handle = function(request, done) {
        // process request
        done(null, {msg: 'hello, ' + request.name + '!'});
      };

    wss.on('connection', function(ws) {
      var sock = websocket(ws),
          server = rpc({handle: handle});
      server
        .pipe(serialize())
        .pipe(sock)
        .pipe(deserialize())
        .pipe(server);
    });

Now on a client you use exactly the same libraries and exactly the same::

    var websocket = require('websocket-stream'),
        rpc = require('stream-rpc'),
        sock = websocket('ws://localhost:3000'),
        client = rpc();

    client
      .pipe(serialize())
      .pipe(sock)
      .pipe(deserialize())
      .pipe(client);

    sock.on('open', function() {
      client.call({name: 'andrey'}, function(err, response) {
        console.log(response.msg); // 'hello, andrey!'
      });
    });

Note that you would need to process client code with ``browserify`` before
serving to a browser.

Handling timeouts
-----------------

Library also provides a way to handle timeouts, just pass a ``timeout`` option
in milliseconds to a client::

    var client = rpc({timeout: 2000});

If ``client`` waits more than 2 seconds then it will receive ``new
Error('timeout')`` error.

Development
-----------

Development of the library takes place in the  GitHub `andreypopp/stream-rpc`_
repository.

Before submitting any pull requests please make sure with ``make test`` that all
tests pass.

.. _browserify: http://browserify.org
.. _`websocket-stream`: https://github.com/maxogden/websocket-stream
.. _through: https://github.com/dominictarr/through
.. _`andreypopp/stream-rpc`: https://github.com/andreypopp/stream-rpc
