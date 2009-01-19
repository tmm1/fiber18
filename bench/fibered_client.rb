# require 'rubygems'
require 'socket'
include Socket::Constants
require 'net/http'
require 'uri'
# require 'fiber'

GC.disable
GC.disable

$count = 5000

def timeout(time, &block)
  yield
end
class Fiber
  def _hash
    @_hash ||= {}
  end  
  def [](key)
    _hash[key]
  end  
  def []=(key,value)
    _hash[key] = value
  end
end

$nonblock = false

$nonblock = true if ARGV[0] and ARGV[0] == 'nb'

$writables = []
$readables = [] 

class Socket
  alias_method :read_blocking, :sysread

  def sysread(*args)
    if Fiber.current[:neverblock]
      begin
        read_nonblock(*args)
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
        @fiber = Fiber.current
        $readables << self
        Fiber.yield
        $readables.delete self
        @fiber = nil
        read_nonblock(*args)
      end
     else
      read_blocking(*args)
     end
  end

  alias_method :connect_blocking, :connect
  def connect(server_sockaddr)
    #Kernel.puts "connecting"
    if Fiber.current[:neverblock]
      begin
        connect_nonblock(server_sockaddr)
      rescue Errno::EINPROGRESS
        @fiber = Fiber.current
        $writables << self
        Fiber.yield
        $writables.delete self
        @fiber = nil
        begin
          connect_nonblock(server_sockaddr)
        rescue Errno::EISCONN
        end
      end
     else
      connect_blocking(server_sockaddr)
     end
  end

  def resume_command
    @fiber.resume if @fiber
  end

end

class BasicSocket
  @@getaddress_method = IPSocket.method(:getaddress)
  def self.getaddress(*args)
    @@getaddress_method.call(*args)
  end
end

Object.send(:remove_const, :TCPSocket)

class TCPSocket < Socket
  def initialize(*args)
    super(AF_INET, SOCK_STREAM, 0)
    self.connect(Socket.sockaddr_in(*(args.reverse)))
  end
end

$url = URI.parse('http://127.0.0.1:3005')
$size = 0

def connect(i)
  begin
    f = Fiber.new do
      res = Net::HTTP.start($url.host, $url.port) { |http| http.get('/images/rails.png') }
      $size = $size + res.body.length
      puts "#{i} finished at #{$time = Time.now - $t} with size = #{$size}  "
    end
    f[:neverblock] = $nonblock
    f.resume
  rescue Exception => e
    puts e
  end
end

$t = Time.now
loop do    
  connect($count = $count - 1) if $count >= 0
  res = select($readables, $writables, nil, 0.00001)
  res.flatten.each{ |io| io.resume_command } if res
end

# blocking: 4.9s
# queue: 15.11s
# priority: 6.29s
# continuations: 7.1s