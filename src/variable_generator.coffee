class VariableGenerator

  # create an array of paths (urls) by replacing each variable with list/alpha/number
  # the size of the array will depend on the variable types:
  #    when a list is used, the array size will match the list size
  #    when an alpha, number or uuid is used, the array size will match the max Volume of the test
  #    the max list size is 1000
  #
  # ex: -p 1-10:10 -v:word list[a,b,c,d,e,f,g] -v:num number[100,5000] -v:ralpha alpha[3,10] http://localhost/?#{word}_#{num}_#{ralpha}
  #     path_list = /?a_768_Yp,/?b_174_irZbm,/?c_4677_J,/?d_1981_sPci,/?e_2419_VcMIDd,/?f_3843_xxP,/?g_906_n
  # 
  @generate: (params)->
    path_list = []
    header_list = []
    path = params.request.path
    headers = params.request.headers
    count = Math.min(params.pattern.end, 1000) # support 1000 paths max
    expanded = {}
    expanded_length = 0

    # populate 'expanded' hash with an array of values for each variable, variable name as the key
    for key, value of params.variables
      switch value.type
        when 'list'
          expanded[key] = value.entries
          expanded_length = value.entries.length
        when 'alpha'
          expanded[key] = (@random_alpha(value.min,value.max) for n in [1..count])
        when 'number'
          expanded[key] = (@random_integer(value.min,value.max) for n in [1..count])        
        when 'uuid'
          console.log "NOT IMPLEMENTED: uuid"

    # if no list variable was encountered, the path array length with be 'count'
    expanded_length = count if expanded_length == 0
    
    # populate the path array by replacing all variables at each index of the expanded_length
    for i in [0..expanded_length-1]
      path_n = path
      headers_n = {}
      for var_name, value of params.variables
        path_n = path_n.replace ///\#\{#{var_name}\}///g, expanded[var_name][i]
        for header, value of headers
          headers_n[header] = value.replace ///\#\{#{var_name}\}///g, expanded[var_name][i]
      path_list.push path_n
      header_list.push headers_n

    return [path_list, header_list]

  @random_alpha: (min,max)->
    charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    word = ""
    word += charSet[Math.floor(Math.random() * charSet.length)] for n in [1..(Math.random() * (max - min)) + min]
    return word

  @random_integer: (min,max)->
    max = parseInt(max,10)
    min = parseInt(min,10)
    Math.floor(Math.random()*(max-min)) + min

module.exports = VariableGenerator
