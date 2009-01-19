require 'rubygems'
require 'eventmachine'

$response = "HTTP/1.1 200 OK\n\r\n\rdone".freeze

module Server
  def receive_data data
    send_data $response
    close_connection_after_writing
  end
end

EM.run do
  EM.start_server('localhost', 3005, Server)
end