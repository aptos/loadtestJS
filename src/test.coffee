http = require './blitz_http'

params = {}
res = http.request(params, (res)->
	console.log "Response: #{JSON.stringify(res)}"
	console.log "done!"
)