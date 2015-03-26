express = require 'express'
os      = require 'os'
RunTime = require './run_time'

class Server
  port = 8000
  constructor: () ->
    console.log("Server listening on port #{port}")
    @runner = new RunTime()
   
  start: () ->
    app = express()
    
    app.configure () ->
      app.use(express.methodOverride())
      app.use(express.bodyParser())
      app.use(app.router)
      return
    
    app.post '/rush', (req, res) =>
      console.log req
      @runner or @runner = new RunTime()
      response = @runner.rush(req.body)
      res.json(response)
    
    app.post '/sprint', (req, res) =>
      console.log req
      @runner or @runner = new RunTime()
      my_callback = (e, r) -> 
        res.json(r)
      @runner.sprint(req.body, my_callback)
      

    app.get '/stats', (req, res) =>
      if @runner?.stats
        response = {ok: true, data: @runner.stats}
      else
        response = {ok: false, message: "test is not running"}
      res.json(response)

    app.get '/chart_data', (req, res) =>
      if @runner?.chart_data
        response = {ok: true, finished: @runner.stats.finished, data: @runner.chart_data}
      else
        response = {ok: false, message: "test is not running"}
      res.json(response)

    app.get '/stop', (req, res) =>
      if @runner
        response = @runner.stop()
      else
        response = {ok: false, message: "test is not running"}
      res.json(response)

    app.get '/', (req, res) =>
      res.sendfile('index.html')
      
    app.get '/system', (req, res) =>
      mem = process.memoryUsage()
      res.json({
        totalmem: os.totalmem(),
        freemem: os.freemem(),
        uptime: os.uptime(),
        version: process.version,
        platform: process.platform,
        # vsize: Math.round(mem.vsize / 1024),
        rss: Math.round(mem.rss / 1024),
        heapTotal: Math.round(mem.heapTotal / 1024),
        heapUsed: Math.round(mem.heapUsed / 1024)
      })

    app.listen port
    console.log "Server started on port #{port}"
    return
    
    
  shutdown: () -> process.exit(0)

module.exports = Server
