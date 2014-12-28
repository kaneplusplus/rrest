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
    acceptor(io_service, tcp::endpoint(tcp::v4(), port)) {}
};

// [[Rcpp::export]]
Rcpp::XPtr<tcp_server> create_tcp_server(int port=9090)
{
  return XPtr<tcp_server>(new tcp_server(port));
}

// [[Rcpp::export]]
Rcpp::XPtr<tcp::socket> asio_service_next_request(SEXP p_server)
{
  Rcpp::XPtr<tcp_server> server(p_server);
  tcp::socket *socket = new tcp::socket(server->io_service);
  server->acceptor.accept(*socket);
  return XPtr<tcp::socket>(socket);
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
