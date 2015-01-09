#include <iostream>
#include <string>
#include <boost/asio.hpp>

#include <Rcpp11>

using boost::asio::ip::tcp;

#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
 
template <typename T>
class Queue
{
 public:
 
  T pop()
  {
    std::unique_lock<std::mutex> mlock(mutex_);
    while (queue_.empty())
    {
      cond_.wait(mlock);
    }
    auto item = queue_.front();
    queue_.pop();
    return item;
  }
 
  void pop(T& item)
  {
    std::unique_lock<std::mutex> mlock(mutex_);
    while (queue_.empty())
    {
      cond_.wait(mlock);
    }
    item = queue_.front();
    queue_.pop();
  }
 
  void push(const T& item)
  {
    std::unique_lock<std::mutex> mlock(mutex_);
    queue_.push(item);
    mlock.unlock();
    cond_.notify_one();
  }
 
  void push(T&& item)
  {
    std::unique_lock<std::mutex> mlock(mutex_);
    queue_.push(std::move(item));
    mlock.unlock();
    cond_.notify_one();
  }

  bool empty()
  {
    return queue_.empty();
  }
 
 private:
  std::queue<T> queue_;
  std::mutex mutex_;
  std::condition_variable cond_;
};

void worker_thread(boost::asio::io_service &io_service, 
                   tcp::acceptor &acceptor, 
                   Queue<std::string> &input_queue, 
                   Queue<tcp::socket*> &output_queue)
{
  bool done = false;
  std::string input;
  while (!done)
  {
    input = input_queue.pop();
    if (input == "next")
    {
      tcp::socket *socket = new tcp::socket(io_service);
      acceptor.accept(*socket);
      output_queue.push(socket);
    }
    else if (input == "stop")
    {
      std::cout << "Tcp server thread is stopping\n";
      done = false;
    }
  }
}

struct tcp_server
{
  boost::asio::io_service io_service;
  tcp::acceptor acceptor;
  Queue<std::string> input_queue;
  Queue<tcp::socket*> output_queue;
  std::thread thread;
  tcp_server(int port=9090) : 
    io_service(), 
    acceptor(io_service, tcp::endpoint(tcp::v4(), port)) {}
};

// [[Rcpp::export]]
Rcpp::XPtr<tcp_server> create_tcp_server(int port=9090)
{
  tcp_server *server = new tcp_server(port);
  server->thread = std::thread(worker_thread, std::ref(server->io_service),
           std::ref(server->acceptor), std::ref(server->input_queue),
           std::ref(server->output_queue));
  return XPtr<tcp_server>(server); 
//  return XPtr<tcp_server>(new tcp_server(port));
}

// [[Rcpp::export]]
Rcpp::XPtr<tcp::socket> asio_service_next_request(SEXP p_server)
{
  Rcpp::XPtr<tcp_server> server(p_server);
  server->input_queue.push(std::string("next"));
  tcp::socket *socket = server->output_queue.pop();
//  tcp::socket *socket = new tcp::socket(server->io_service);
//  server->acceptor.accept(*socket);
  return XPtr<tcp::socket>(socket);
}

// [[Rcpp::export]]
void asio_service_shutdown(SEXP p_server)
{
  Rcpp::XPtr<tcp_server> server(p_server);
  server->input_queue.push(std::string("stop"));
  server->thread.join();
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
