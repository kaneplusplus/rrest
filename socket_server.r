library(attributes)

if (!exists("params_updated")) {
  Sys.setenv("PKG_LIBS"=paste("-lboost_system-mt", Sys.getenv("PKG_LIBS")))
  Sys.setenv("PKG_LIBS"=paste("-L/usr/local/lib/",Sys.getenv("PKG_LIBS")))
  params_updated=TRUE
}
attributes::sourceCpp("boost_socket.cpp", verbose=TRUE)


