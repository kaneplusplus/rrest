library(attributes)

if (!exists("params_updated")) {
  Sys.setenv("PKG_LIBS"=paste("-lboost_system-mt", Sys.getenv("PKG_LIBS")))
  Sys.setenv("PKG_LIBS"=paste("-L/usr/local/lib/",Sys.getenv("PKG_LIBS")))
  params_updated=TRUE
}
attributes::sourceCpp("socket_server.cpp", verbose=TRUE)

tcp_server = create_tcp_server(9090)
r = get_next_request(tcp_server)
print(get_message(r))
send_message(r, "ACK")
