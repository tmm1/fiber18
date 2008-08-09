unless defined? Fiber
  require 'thread'

  class FiberError < StandardError; end

  class Fiber
    def initialize
      raise ArgumentError, 'new Fiber requires a block' unless block_given?

      @yield = Queue.new
      @sleeper = Queue.new

      @thread = Thread.new{ sleep; @yield.push(yield) }
      @thread.abort_on_exception = true
      @thread[:fiber] = self
    end
    attr_reader :yield, :thread

    def resume
      wake
      @yield.pop
    end

    def wake
      @sleeper.push(nil)
    end

    def sleep
      @sleeper.pop
    end
    
    def self.yield arg = nil
      raise FiberError, "can't yield from root fiber" unless fiber = Thread.current[:fiber]
      fiber.yield.push(arg)
      fiber.sleep
    end
  end
end

if __FILE__ == $0
  f = Fiber.new{ puts 'hi'; Fiber.yield(1); puts 'bye'; :done }
  p f.resume
  p f.resume
end

__END__

$ ruby fbr.rb 
hi
1
bye
:done

$ ruby1.9 fbr.rb 
hi
1
bye
:done
