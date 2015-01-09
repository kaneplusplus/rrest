library(parallel)
library(RJSONIO)

source('responses.R')

parse_html_request = function(str) {  
  print(str)
  meth     = unlist(strsplit(str, ' /'))[[1]]
  print(meth)
  endpoint = unlist(regmatches(str, gregexpr('/[^ ]*', str)))[1]
  endpoint = gsub('^/', '', endpoint)
  body     = unlist(strsplit(str, "\r\n"))
  body     = body[length(body)]
  if(jsonlite::validate(body)) {
	  body = fromJSON(body)
  } else {
	  body = NULL
  }

  req = list(fun = endpoint, body = body)
  class(req) = c(meth, 'character')
  print(req)
  req
}

call_gen = function(fun_env) {
  function(req) {
#    ret = toJSON({
      tryCatch({
        fun = fun_env[[req[['fun']]]]
        if(!is.null(fun)){
          body = req[['body']]
          if(!is.null(body)) {
            class(body) <- c(class(body), class(req))
          }
          ret = success(toJSON(fun(body)))
		  print(ret)
        } else { 
          ret= method_not_found()
        }
        ret
      }, error = function(e) {
        throw_error()
      })
#    })
#    ret = sub("\n", "", ret)
    # print(ret)
    # ret
  }
}

start_service = function(conn, call, parse_input=function(x) x,
                         format_output=function(x) x, callback=NULL, 
                         parallel=1, max_num_requests=Inf) {
  i=1
  if (parallel == 1) {
    while(i <= max_num_requests) {
      req = next_request(conn)
      print(req)
      i = i+1
      call_input = parse_input(req$str)
      call_ret = call(call_input)
      formatted_call_return = format_output(call_ret)
      if (!is.null(formatted_call_return))
        send_message(req$client_conn, call_ret)
      if (!is.null(callback))
        callback(call_ret)
      close(req$client_conn)
    }
  } else {
    # For now, parallel > 1 means we fork for each request and assume
    # that the request is stateless.
    while(i <= max_num_requests) {
      req = next_request(conn)
      i = i+1
      p = parallel:::mcfork(estranged=TRUE)
      if (inherits(p, "masterProcess")) {
        # This line need to change to a real rng
        set.seed(as.integer(microbenchmark::get_nanotime()/1e7))
        # child process code
        call_input = parse_input(req$str)
        call_ret = call(call_input)
        formatted_call_return = format_output(call_ret)
        if (!is.null(formatted_call_return))
          send_message(req$client_conn, call_ret)
        if (!is.null(callback))
          callback(call_ret)
        close(req$client_conn)
        parallel:::mcexit()
      } else {
        # parent process code
        close(req$client_conn)
      }
    }
  }
}
