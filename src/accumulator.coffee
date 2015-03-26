class Accumulator
  # Accumulate an array of arrays for each label
  # ex:
  #  { pass: [0,0],[5,10],[10,8], fail: [0,0],[5,0],[10,2]}
  constructor: (labels) ->
    console.info "construct Accumulator for: #{labels}"
    @data = {}
    @x0 = {}
    @y0 = {}
    @t0 = {}
    @c0 = {}
    @data[label] = [] for label in labels
    @integers = true

  push_rate: (label, time, value) ->
    x = time
    if @x0?[label]
      y = (value - @y0[label])/(time - @x0[label])
    else
      console.info "First rate: #{label} t:#{time} v:#{value}"
      y = if time > 0.2 then value/time else 0
    @data[label].push([ Math.round(x), Math.round(y)])

    @x0[label] = x
    @y0[label] = value

  push_avg_rate: (label, time, total, count) ->
    console.info "#{label} t:#{total} c:#{count}"
    x = time
    if @x0?[label]
      avg = (total - @t0[label])/(count - @c0[label])
      y = (avg - @y0[label])/(time - @x0[label])
    else
      avg = total/count
      y = avg/time
    @data[label].push([ Math.round(x), Math.round(y)])

    @x0[label] = x
    @y0[label] = avg
    @t0[label] = total
    @c0[label] = count

  push_value: (label, time, value) ->
    @data[label].push([ Math.round(time), Math.round(value)])

  push_avg: (label, time, total, count) ->
    if @t0?[label]
      avg = (total - @t0[label])/(count - @c0[label])
    else
      avg = total/count
    @data[label].push([ Math.round(time), Math.round(avg)])

    @t0[label] = total
    @c0[label] = count

module.exports = Accumulator