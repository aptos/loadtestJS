http = require 'http'
variable_generator = require './variable_generator'

class ClientRequest
  constructor: (@params, @stats, @totals) ->
    console.log("ClientRequest Created")
    @request = @params.request
    @path_list = [@request.path]
    @header_list = [@request.headers]
    @list_length = 1
    if @params.variables
      [@path_list, @header_list] = variable_generator.generate(@params)
      @list_length = @path_list.length
      console.info("path_list: #{@path_list} header_list: #{JSON.stringify(@header_list)}")

  now: () ->
    return new Date().getTime()

  send: (callback) ->
    @request.path = @path_list[@stats.requests%@list_length]
    @request.headers = @header_list[@stats.requests%@list_length]
    @stats.requests += 1
    t1 = @now()
    req = http.request(@request, (r) =>
      if r?.statusCode
        @stats.responses += 1
        @stats.response_time = @now() - t1
        @totals.response_count += 1
        @totals.response_time += @stats.response_time

        @stats.codes[r.statusCode] = if @stats.codes[r.statusCode] then @stats.codes[r.statusCode] + 1 else 1
        @stats.rx_bytes = r.socket.bytesRead
      if r?.statusCode < 400
        @stats.pass += 1
      callback(true)
    )
    req.on('error', (e) =>
      # console.log "error: #{e.code} #{e.message}"
      if e?.code == "ECONNRESET"
        @stats.timeouts += 1
      else
        @stats.errors += 1
        @stats.last_error = e.code
      callback(false)
      return
    )

    if @params.data
      req.write(@params.data.join("&"))

    req.on('socket', (socket) =>
      socket.setTimeout(@params.timeout)
      socket.on('timeout', () =>
        req.abort();
      )
    )
    req.end()
    return

module.exports = ClientRequest
