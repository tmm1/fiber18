unless defined? Fiber
  require 'thread'

  class FiberError < StandardError; end

  class Fiber
    def initialize
      @yield_q = Queue.new
      @sleep_q = Queue.new

      @thread = Thread.new{ @sleep_q.pop; yield; @yield_q.push(nil) }
      @thread.abort_on_exception = true
      @thread[:fiber] = self
    end
    attr_reader :yield_q, :sleep_q, :thread

    def resume
      @sleep_q.push(nil)
      @yield_q.pop
    end
    
    def self.yield arg = nil
      raise FiberError, "can't yield from root fiber" unless fiber = Thread.current[:fiber]
      fiber.yield_q.push(arg)
      fiber.sleep_q.pop
    end
  end
end

f = Fiber.new{ puts 'hi'; Fiber.yield(1); puts 'bye' }
p f.resume
p f.resume

__END__

$ ruby fbr.rb 
hi
1
bye
nil

$ ruby1.9 fbr.rb 
hi
1
bye
nil
