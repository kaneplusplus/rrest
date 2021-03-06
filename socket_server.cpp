#include <iostream>
#include <string>
#include <boost/asio.hpp>

#include <Rcpp11>

using boost::asio::ip::tcp;

struct tcp_server
{
  boost::asio::io_service io_service;
  tcp::acceptor acceptor;
  tcp_server(int port=9090) : 
    io_service(), 
    acceptor(io_service, tcp::endpoint(tcp::v4(), port)), interrupted(false) {}
};

// [[Rcpp::export]]
Rcpp::XPtr<tcp_server> create_tcp_server(int port=9090)
{
  return XPtr<tcp_server>(new tcp_server(port));
}

// [[Rcpp::export]]
void shutdown_tcp_server(SEXP p_server)
{
  // TODO: Finish this.
  Rcpp::XPtr<tcp_server> server(p_server);
}

// [[Rcpp::export]]
Rcpp::XPtr<tcp::socket> asio_service_next_request(SEXP p_server)
{
  Rcpp::XPtr<tcp_server> server(p_server);
  tcp::socket *socket = new tcp::socket(server->io_service);
 
  fd_set file_descriptor_set; 
  FD_ZERO(&file_descriptor_set);

  int native_socket_server = server->acceptor.native();
  FD_SET(native_socket_server, &(server->file_descriptor_set));
  select(native_socket_server+1, &(server->file_descriptor_set), NULL, 
         NULL, NULL); 

  if(errno == EINTR)
  { 
    // reset the error.
    errno = 0;
    std::cout << "\nInterrupting call for next request";
    delete socket;
    //socket->close();
    return R_NilValue; //Rcpp::XPtr<tcp::socket>(R_NilValue);
  } 
  else 
  {
    server->acceptor.accept(*socket);
    return Rcpp::XPtr<tcp::socket>(socket);
  }
}

// [[Rcpp::export]]
std::string asio_socket_read_message(SEXP p_socket)
{
  Rcpp::XPtr<tcp::socket> sock(p_socket);
  std::string message;
  message.resize(10000);
  sock->receive(boost::asio::buffer(&message[0], message.size()));
  return message;
}

// [[Rcpp::export]]
void asio_socket_write_message(SEXP p_socket, std::string message)
{
  Rcpp::XPtr<tcp::socket> sock(p_socket);
  sock->send(boost::asio::buffer(&message[0], message.size()));
}

// [[Rcpp::export]]
void asio_socket_close(SEXP p_socket)
{
  Rcpp::XPtr<tcp::socket> sock(p_socket);
  sock->close();
}
