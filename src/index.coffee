###

  Turn a stream of objects into an RPC system

###

through = require 'through'
uuid = require 'uuid'

delay = (ms, func) ->
  setTimeout func, ms

module.exports = (options = {}) ->
  waitingFor = {}
  timeout = options.timeout or 2000
  handle = options.handle

  stream = through (message) ->
    {id, err, request, response} = message

    if not id
      console.warn "message with no id"
      return

    if request
      if handle
        handle request, (err, response) =>
          stream.emit 'data', {id, err, response}
      else
        stream.emit 'data', {id, response: request}

    else
      if not waitingFor[id]
        console.warn "orphaned response with id", id
        return

      {timer, cb} = waitingFor[id]
      delete waitingFor[id]
      clearTimeout timer
      cb(err, response)

  stream.call = (request, cb) ->
    id = uuid.v4()
    timer = setTimeout (=>
      {timeout, cb} = waitingFor[id]
      clearTimeout timeout
      cb(new Error('timeout'))
      delete waitingFor[id]), timeout
    waitingFor[id] = {timer, cb}
    stream.emit 'data', {id, request}

  stream
