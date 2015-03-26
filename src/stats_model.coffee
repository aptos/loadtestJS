class Stats

  constructor: () ->    
    @stats = {
      volume: 0, 
      requests: 0, 
      responses: 0,
      active_connections: 0,
      pass: 0, 
      errors: 0, 
      timeouts : 0,
      response_time: 0, 
      rx_bytes: 0,
      codes:{},
      start_time: 0,
      duration: 0,
      last_error: "",
      finished: false
    }

    @totals = {
      response_count: 0,
      response_time: 0,
      connections_count: 0,
      connections: 0
    }
        
module.exports = Stats