library(parallel)
library(RJSONIO)

source('responses.R')
rrest_socket_connection = function(host="localhost", port=9090, fail=TRUE) {
  conn = new.env()
  assign("host", host, conn)
  assign("port", port, conn)
  assign("fail", fail, conn)
  class(conn) = c("service_connection", "rrest_socket_connection")
  conn
}

close.rrest_socket_connection = function(con, ...) {
}

next_request = function(conn) {
  UseMethod("next_request", conn)
}

send_response = function(conn, x) {
  UseMethod("send_response", conn)
}

# Request parsing should be done here.
next_request.rrest_socket_connection = function(conn) {
  client_conn = make.socket(host=conn$host, port=conn$port, fail=conn$fail,
                          server=TRUE)
  str = read.socket(client_conn, maxlen=10000L)
  list(str=str, client_conn=client_conn)
}

parse_html_request = function(str) {  
  # I wonder if we should separate parsing from reading
  # because I'm guessing HTTP requests are going to look
  # the same no matter how we actuall receive them (sockets, 
  # httpuv, whatever)
  meth     = unlist(strsplit(str, ' /'))[[1]]
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
  class(req) = c('character', meth)
  req
}

send_response.socket = function(conn, x) {
  print("message being sent to socket")
  print(x)
  write.socket(conn, x)
}

call_gen = function(fun_env) {
  function(req) {
    ret = toJSON(
      tryCatch({
        fun <- fun_env[[req[['fun']]]]
        print(fun)
        if(!is.null(fun)){
          body <- req[['body']]
          if(!is.null(body)) {
            class(body) <- c(class(body), class(req))
          }
          success(toJSON(fun(body)))
        } else { 
          method_not_found()
        }
      }, error = function(e) {
        throw_error()
      })
    )
    sub("\n", "", ret)
  }
}

start_service = function(conn, call, parse_input=function(x) x,
                         format_output=function(x) x, callback=NULL, 
                         parallel=1, max_num_requests=Inf) {
  i=1
  if (parallel == 1) {
    while(i <= max_num_requests) {
      req = next_request(conn)
      i = i+1
      call_input = parse_input(req$str)
      call_ret = call(call_input)
      formatted_call_return = format_output(call_ret)
      if (!is.null(formatted_call_return))
        send_response(req$client_conn, call_ret)
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
          send_response(req$client_conn, call_ret)
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
