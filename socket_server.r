while (1) {
  sock = make.socket(host = "localhost", port="9090", fail = TRUE, 
                     server = TRUE)
  str = read.socket(sock)
  print(str)
  close.socket(sock)
}
