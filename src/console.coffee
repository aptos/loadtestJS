RunTime = require './run_time'

params = {
  request: {
    uri: "http://localhost",
    method: "GET",
    timeout: 5000
  },
  pattern: {
    start_count: 1,
    end_count: 10000, 
    duration: 60
  },
  chart: {
    interval: 1,
    rates: ['pass', 'timeouts', 'errors'],
    values: ['volume','active_connections','response_time']
  }
}

r = new RunTime()
r.start(params)
    
# Output stats to console
update = () ->
  return () ->
    console.log(r.stats)

# print updates
updatesId = setInterval( update(), params.poll_interval * 1000 )