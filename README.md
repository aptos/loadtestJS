blitz-engineJS
===========

blitz-engine written in coffeescript for nodejs.

To run the server on the default port 8000:

	npm install
	coffee blitz-engine.coffee

The server supports the following commands:
  * POST /sprint
  * POST /rush
  * GET /stats
  * GET /chart_data
  * GET /stop
  * GET /system

The POST params for sprint and rush are:

	params = {
	  request: {
	    uri: "http://localhost",
	    method: "GET",
	    timeout: 5000
	  },
	  pattern: {
	    start_count: 1,
	    end_count: 10000, 
		duration: 60,
	    hold: 50
	  },
	  chart: {
	    interval: 1,
	    rates: ['pass', 'timeouts', 'errors'],
	    values: ['volume','active_connections','response_time']
	  }
	}

The pattern does not currently support an array of ramps, however it does implement a hold timer, which will hold volume at end_count for a configured number of seconds.

HTTP Client
-----------
The initial implementation used the node 'request' module. At high concurrencies (5K+) response times of 6 seconds were measured on an Ec2 running against an nginx running on localhost. The implementation has since been changed to node's internal http.client. This implementation measures 3 second response times for the 5K concurrencies to localhost test.

Chart Data
----------
The chart_data is organized as an array of [time, value] for use by flot. Values can be specified as rates or simple values based on the chart params. Polling interval is in seconds. Values are all rounded to nearest integer. response_time is in ms. The response includes a "finished" boolean, so that a polling process can stop onces the test completes. Note that a cool-down time of 5 seconds is included after each pattern so that in-flight requests can be completed and added to the chart.

The response to /chartdata looks something like:

	{
	  "ok": true,
	  "finished": false,
	  "data": {
	    "pass": [0,0],[5,10],[10,8], 
	    "timeouts": [0,0],[5,0],[10,2]
	  }
	}

Testing
-------
For testing purposes, the server also provides a simple UI at /index.html. Supported parameters:
  * -p 1-250:60  (only a single pattern is supported at this time)
  * -T 5000 (timeout in milliseconds)
  * -X (method)

Node.js
-------
When running blitz-engine.js with standard node, you will see spikes on response times appearing every minute. These spikes are caused by the garbage collection process in node. To build node without GC, follow the instructions here:

http://blog.caustik.com/2012/04/11/escape-the-1-4gb-v8-heap-limit-in-node-js/

Begin by cloning the latest node repository:

    git clone https://github.com/joyent/node.git

Main points of that blog: 
Add a single line addition to “SConstruct” inside the v8 directory.

    node/deps/v8/SConstruct:

    'CPPPATH': [src_dir],
    'CPPDEFINES': ['V8_MAX_SEMISPACE_SIZE=536870912'],

 Comment out the call to “CollectAllGarbage” in “heap-inl.h”:

    node/deps/v8/src/heap-inl.h:

    if (amount_since_last_global_gc > external_allocation_limit_) {
      //CollectAllGarbage(kNoGCFlags, "external memory allocation limit reached");
    }

Next, work around the 'bug' listed below - events is worried about memory leaks after we open the 11th active connection. Edit node/lib/events.js as follows:

    node/lib/events.js:

	// Obviously not all Emitters should be limited to 10. This function allows
	// that to be increased. Set to zero for unlimited.
	var defaultMaxListeners = 0;
	EventEmitter.prototype.setMaxListeners = function(n) {

Build node for your arch. Note that the blog recommends updating v8 code within the node/deps. I DO NOT recommend this as when I attempted this my build did not complete without errors.

    ./configure
    make
    sudo make install


The following params should also be used to start node:

    ulimit -n 999999
    –nouse-idle-notification
    –max-old-space-size=8192

EC2
---
To build on EC2 64-bit - following the notes from http://skipperkongen.dk/2012/01/10/installing-node-js-on-ec2-64-bit-microinstance-running-amazon-linux/

    sudo yum install git
    sudo yum install gcc-c++.x86_64
    sudo yum install openssl-devel.x86_64
    sudo yum install -y make.x86_64

Then follow instructions above on building node with the proper hacks for our usage.

Rakefile
--------
In order to keep usage consistent, I've added a Rakefile that can be used to install, compile and run:

	$ rake help
	rake init                : npm install: download all dependencies.
	rake compile             : compile coffee-script codes to javascript.
	rake compile_run         : compile and run the node app
	rake run                 : run the node app
	rake dev                 : run the coffee-script app with source

Reliable Response Time Measurement
----------------------------------
Using the callback from http client to measure response time of the server will result in descrepancies between the response time on the wire, and the value measured. This is due to adding in time spent dequeuing and processing of responses. As load increases, this factor makes the response time measurement invalid. A blitz_http module has been added which uses sockets directly and implements a very simple http client with header parsing. This remedies the problem but does not support body parsing, limiting future features such as CSRF authentication token processing.

TCP Socket Recycling for Large Concurrencies
--------------------------------------------
When using node http module, the Agent provides resuable TCP connections for multiple transactions. With the default agent settings, 6000 requests per second were achieved with 10,000 connections to an nginx server on localhost. Disabling the agent caused crashes as soon as the system sockets were exhausted, about 10 seconds into a test. When using the blitz_http module ENOTFOUND errors began logging shortly into the test. Adjusting the following parameters reduced but did not fix the problem:

	echo 10 > /proc/sys/net/ipv4/tcp_fin_timeout
	echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
	echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse