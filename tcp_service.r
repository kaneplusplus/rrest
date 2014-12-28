library(attributes)

# Build the boost asio tcp_server. 
if (!exists("params_updated")) {
  Sys.setenv("PKG_LIBS"=paste("-lboost_system-mt", Sys.getenv("PKG_LIBS")))
  Sys.setenv("PKG_LIBS"=paste("-L/usr/local/lib/",Sys.getenv("PKG_LIBS")))
  params_updated=TRUE
}
attributes::sourceCpp("socket_server.cpp", verbose=TRUE)

tcp_service = function(port=9090) {
  service = new.env()
  assign("service", create_tcp_server(port), service)
  class(service) = c("asio_service", "service")
  service
}

close.asio_service = function(service) {
  rm(service)
}

receive_message = function(service_socket) {
  UseMethod("receive_message", service_socket)
}

receive_message.asio_service_socket = function(service_socket) {
  asio_socket_read_message(service_socket)
}

next_request = function(service) {
  UseMethod("next_request", service)
}

next_request.asio_service = function(service) {
  sock = asio_service_next_request(service$service)
  class(sock) = c(class(sock), "service_socket", "asio_service_socket")
  str = receive_message(sock)
  list(str=str, client_conn=sock)
}

send_message = function(service_socket, message) {
  UseMethod("send_message", service_socket)
}

close.asio_service_socket = function(service_socket) {
  asio_socket_close(service_socket)
}

send_message.asio_service_socket = function(service_socket, message) {
  asio_socket_write_message(service_socket, message)
}

