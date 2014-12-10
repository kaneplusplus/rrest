library(parallel)
library(RJSONIO)

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
  req = unlist(strsplit(str, "\r\n"))
  req = req[length(req)]
}

send_response.rrest_socket_connection = function(conn, x) {
  write.socket(conn$sock, x)
}

close.rrest_socket_connection = function(conn) {
  close(conn$sock)
  conn$sock = NULL
}

start_service = function(conn, call, callback=NULL, parallel=1, 
                         max_num_requests=Inf) {
  if (parallel == 1) {
    i=1
    while(i <= max_num_requests) {
      call_ret = call(next_request(conn))
      if (!is.null(call_ret))
        send_response(conn, call_ret)
      if (!is.null(callback))
        callback(call_ret)
      close(conn)
    }
  }
}
