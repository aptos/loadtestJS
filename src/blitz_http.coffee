net = require 'net'

class BlitzHttp

  @now: () =>
    return new Date().getTime()

  @request: (params, @callback) =>
    method = "GET"
    path = "/"
    host = "localhost"
    port = 80

    headers = { 
      'User-Agent': "curl/7.19.7 (universal-apple-darwin10.0) libcurl/7.19.7 OpenSSL/0.9.8r zlib/1.2.3"
      'Host': "localhost"
      'Accept': "*/*"
      'Connection': "close"
    }
    hdr_string = ""
    for name, value of headers
      hdr_string += "#{name}: #{value}\r\n"
      
    req = [ method, path, "HTTP/1.1" ].join(" ") + "\r\n"
    req += hdr_string + "\r\n"

    client = new net.Socket()
    client.connect(port, host, () =>
      @request_time = @now()
      client.write(req)
    )

    client.on('data', (data) =>
      response_time = @now() - @request_time
      @response = @parse(data)
      client.end()
      client.destroy()
      @response.responseTime = response_time
      @callback(@response)
    )

    client.on('error', (e) => 
        console.log "error: #{e.code}"
    )

    return

  @parse: (buf) ->
    response = {}
    [header, response.body] = buf.toString().split("\r\n\r\n",2)
    response.headers = header.split("\r\n")
    [response.proto, response.statusCode, response.message] = response.headers.shift().split(" ")
    return response

module.exports = BlitzHttp