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

next_request = function(conn) {
  UseMethod("next_request", conn)
}

send_response = function(conn, x) {
  UseMethod("send_response", conn)
}

# Request parsing should be done here.
next_request.rrest_socket_connection = function(conn) {
  if (!is.null(conn$sock))
    close(conn$sock)
  conn$sock = make.socket(host=conn$host, port=conn$port, fail=conn$fail,
                          server=TRUE)
  str = read.socket(conn$sock, maxlen=10000L)
  
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

send_response.rrest_socket_connection = function(conn, x) {
  write.socket(conn$sock, x)
}

close.rrest_socket_connection = function(conn) {
  close(conn$sock)
  conn$sock = NULL
}

call = function(req, fun_env) {
	toJSON(
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
}

start_service = function(conn, fun_env, callback=NULL, parallel=1, 
                         max_num_requests=Inf) {
  if (parallel == 1) {
    i=1
    while(i <= max_num_requests) {
      call_ret = call(next_request(conn), fun_env)
      if (!is.null(call_ret))
        send_response(conn, call_ret)
      if (!is.null(callback))
        callback(call_ret)
      close(conn)
    }
  }
}
