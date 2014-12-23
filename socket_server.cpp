//#include <Rcpp11>

#include <mutex>
#include <chrono>
#include <utility>
#include <queue>

#include <ctime>
#include <iostream>
#include <string>
#include <boost/bind.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/asio.hpp>

#undef THREAD_SAFE

template<typename Data>
class concurrent_queue
{
  protected:
    std::queue<Data> queue_;
#ifdef THREAD_SAFE
    mutable std::mutex mutex_;
    std::condition_variable cv_;
#endif 
  public:
    void push(Data const& data)
    {
#ifdef THREAD_SAFE
      std::lock_guard<std::mutex> lock(mutex_);
#endif
      queue_.push(data);
#ifdef THREAD_SAFE
      cv_.notify_one();
#endif
    }

    bool empty() const
    {
#ifdef THREAD_SAFE
      std::lock_guard<std::mutex> lock(mutex_);
#endif
      return queue_.empty();
    }

    bool try_pop(Data& popped_value)
    {
#ifdef THREAD_SAFE
      std::lock_guard<std::mutex> lock(mutex_);
#endif
      bool ret = false;
      if(!queue_.empty()) 
      {
        popped_value=queue_.front();
        queue_.pop();
        ret = true;
      }
      return true;
    }

    bool wait_and_pop(Data& popped_value, unsigned int timeout=10)
    {
#ifdef THREAD_SAFE
      std::lock_guard<std::mutex> lock(mutex_);
      auto now = std::chrono::system_clock::now();
      if(queue_.empty())
        cv_.wait_until(lock, now + std::chrono::seconds(timeout));
#endif
      bool ret = false;
      if (!queue_.empty())  
      {
        popped_value=queue_.front();
        queue_.pop();
        ret = true;
      }
      return ret;
    }
};

using boost::asio::ip::tcp;

typedef std::pair<std::string, tcp::socket> string_socket_pair;
class tcp_connection;
typedef concurrent_queue<tcp_connection*> response_queue;

class tcp_connection
{
  public:

    static tcp_connection* create(boost::asio::io_service& io_service, 
                                  response_queue &rq)
    {
      return new tcp_connection(io_service, rq);
    }

    tcp::socket& socket() { return socket_; }

    void start()
    {
      std::cout << "in tcp_connection::start\n\n";
      message_.resize(10000);
      socket_.receive(boost::asio::buffer(&message_[0], message_.size()));
      std::cout << "message is: " << message_ << std::endl;
      std::cout << "This connection is putting itself on the queue\n";
      response_queue_.push(this);
    }
    
    std::string get_message() {return message_;}

    void write(std::string message) 
    {
      boost::asio::write(socket_, boost::asio::buffer(message));
    }  

  protected:
    tcp_connection(boost::asio::io_service& io_service, response_queue &rq)
      : socket_(io_service), response_queue_(rq) {}

    tcp::socket socket_;
    std::string message_;
    response_queue &response_queue_;
    boost::asio::streambuf buffer_;
};

class tcp_server
{
  public:
    tcp_server(boost::asio::io_service& io_service)
      : acceptor_(io_service, tcp::endpoint(tcp::v4(), 9090))
    {
      start_accept();
    }

  private:
    void start_accept()
    {
      tcp_connection* new_connection =
        tcp_connection::create(acceptor_.get_io_service(), response_queue_);

      acceptor_.async_accept(new_connection->socket(),
          boost::bind(&tcp_server::handle_accept, this, new_connection,
            boost::asio::placeholders::error));
    }

    void handle_accept(tcp_connection* new_connection,
        const boost::system::error_code& error)
    {
      if (!error) new_connection->start();
      start_accept();
    }
    
    tcp::acceptor acceptor_;
    response_queue response_queue_;
};
// compile with g++ -std=gnu++11 socket_server.cpp -L/usr/local/lib/ -lboost_system-mt
int main()
{
  try
  {
    boost::asio::io_service io_service;
    tcp_server server(io_service);
    io_service.run_one();
    io_service.run_one();
  }
  catch (std::exception& e)
  {
    std::cerr << e.what() << std::endl;
  }
  return 0;
}
