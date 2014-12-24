//#include <Rcpp11>

#include <iostream>
#include <string>
#include <boost/asio.hpp>

using boost::asio::ip::tcp;

// compile with g++ -std=gnu++11 socket_server.cpp -L/usr/local/lib/ -lboost_system-mt

// TODO: add options to better specify the endpoint.
tcp::acceptor* create_tcp_server(int port=9090) 
{
  boost::asio::io_service io_service;
  return new tcp::acceptor(io_service, tcp::endpoint(tcp::v4(), port));
}

tcp::socket* get_next_request(tcp::acceptor* server)
{
  tcp::socket *socket = new tcp::socket(server->get_io_service());
  server->accept(*socket);
  return socket;
}

int main()
{
  try
  {
    std::string message;
    tcp::acceptor *a = create_tcp_server();
    tcp::socket *s = get_next_request(a);
    message.resize(10000);
    s->receive(boost::asio::buffer(&message[0], message.size()));
    std::cout << "message is: " << message << std::endl;
    message = "ACK";
    s->send(boost::asio::buffer(&message[0], message.size()));
  }
  catch (std::exception& e)
  {
    std::cerr << e.what() << std::endl;
  }
  return 0;
}
