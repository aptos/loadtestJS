http = require 'http'
Stats = require './stats_model'
Accumulator = require './accumulator'
ClientRequest = require './client_request'

# https://github.com/mikeal/request/

class RunTime
    
  constructor: () ->
    console.log("RunTime Created")

  now: () ->
    return new Date().getTime()

  ramp: (pattern) -> 
    return () =>
      @stats.duration = (@now() - @stats.start_time)/1000 # in seconds
      @stats.active_connections = @stats.requests - @stats.responses - @stats.timeouts

      @totals.connections_count += 1
      @totals.connections += @stats.active_connections

      if @stats.duration <= pattern.duration + pattern.hold
        if @stats.volume < pattern.end
          @stats.volume = pattern.start + Math.round(@ramp_rate * @stats.duration)
        else
          @stats.volume = pattern.end
        # Add runtimes based on volume minus current open requests
        add_requests = @stats.volume - @stats.active_connections
        if add_requests > 0
          for i in [1..add_requests]
            @client.send(()->)      
      else
        @stats.volume = 0
        # Stop after 5 second cool down
        if @stats.duration > pattern.duration + 5 + pattern.hold
          @stats.finished = true
          @stop()

  rush: (@params) ->
    console.log "finished? #{@stats?.finished}"
    @s = new Stats()
    @stats = @s.stats
    @totals = @s.totals
    pattern = {
      start: parseInt(@params.pattern.start || 1),
      end:   parseInt(@params.pattern.end || 250),
      duration: parseInt(@params.pattern.duration || 60),
      hold: parseInt(@params.pattern.hold || 0)
    }
    console.log(pattern)
    if @runId
      console.log "already running!"
      return {ok: false, message: "already running!"}
    @ramp_rate = (pattern.end - pattern.start)/pattern.duration
    console.info("rushing... #{JSON.stringify(@params.request)}")
    @stats.start_time = @now()
    @client = new ClientRequest(@params, @stats, @totals)

    @runId = setInterval( @ramp(pattern), 50 )
    
    if @params.chart
      @create_chart()
    return {ok: true}

  sprint: (@params, callback) ->
    console.log("sprinting... #{JSON.stringify(@params.request)}")
    s = new Stats()
    @stats = s.stats
    @totals = s.totals # not used, but keeps client_request simple
    client = new ClientRequest(@params, @stats, @totals)
    client.send((ok) =>
      @stats.finished = true
      console.log "Response: #{ok} Stats: #{JSON.stringify(@stats)}"
      response = {ok: ok, data: @stats}
      callback(undefined, response)
    )
    return

  stop: () -> 
    console.log("stop...")
    unless @runId
      return {ok: true}
    clearInterval(@runId)
    delete @runId
    
    @stats.finished = true
    @stats.volume = 0

    if @chartId
      clearInterval(@chartId)
      delete @chartId
    return {ok: true}

  create_chart: () ->
    labels = @params.chart.rates.concat @params.chart.values.concat @params.chart.avg
    @accumulator = new Accumulator(labels)
    @chart_data = @accumulator.data
    @chartId = setInterval( @chart(@params), @params.chart.interval * 1000)

  chart: () ->
    return () =>
      @accumulator.push_rate(label, @stats.duration, @stats[label]) for label in @params.chart.rates
      @accumulator.push_value(label, @stats.duration, @stats[label]) for label in @params.chart.values
      @accumulator.push_avg('response_time', @stats.duration, @totals.response_time, @totals.response_count)
      @accumulator.push_avg('active_connections', @stats.duration, @totals.connections, @totals.connections_count)

module.exports = RunTime

