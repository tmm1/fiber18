# Poor Man's Fiber (API compatible Thread based Fiber implementation for Ruby 1.8)
# (c) 2008 Aman Gupta (tmm1)

unless defined? Fiber
  $:.unshift File.expand_path(File.dirname(__FILE__)) + '/compat'
  require 'thread'

  class FiberError < StandardError; end

  class Fiber
    def initialize
      raise ArgumentError, 'new Fiber requires a block' unless block_given?

      @priority = (Thread.current[:fiber] and Thread.current[:fiber].priority + 1) || 1
      @value = nil

      @thread = Thread.new(@priority){ |priority|
        Thread.current.priority = priority
        Thread.critical = false
        Thread.stop
        Thread.critical = true
        Thread.current[:fiber].value = [ yield *Thread.current[:fiber].value ]
      }
      @thread.abort_on_exception = true
      @thread[:fiber] = self
    end
    attr_reader :thread, :priority
    attr_accessor :value

    def resume *args
      raise FiberError, 'dead fiber called' unless @thread.alive?
      @value = args
      @thread.wakeup
      Thread.pass
      @value.size > 1 ? @value : @value.first
    end

    def yield *args
      @value = args
      Thread.critical = false
      Thread.stop
      Thread.critical = true
      @value.size > 1 ? @value : @value.first
    end

    def self.yield *args
      if fiber = Thread.current[:fiber]
        fiber.yield(*args)
      else
        raise FiberError, 'not inside a fiber'
      end
    end

    def self.current
      if Thread.current == Thread.main
        return Thread.main[:fiber] ||= RootFiber.new
      end

      Thread.current[:fiber] or raise FiberError, 'not inside a fiber'
    end

    def inspect
      "#<#{self.class}:0x#{self.object_id.to_s(16)}>"
    end
  end

  class RootFiber < Fiber
    def initialize
      # XXX: what is a root fiber anyway?
      @priority = 1
    end

    def self.yield *args
      raise FiberError, "can't yield from root fiber"
    end
  end
end

if __FILE__ == $0
  f = Fiber.new{ |sym|
    p(sym)
    puts 'hi'
    p(Fiber.yield 1)
    puts 'bye'
    :end
  }
  p(f.resume :begin)
  p(f.resume 2)
end

__END__

$ ruby fbr.rb
:begin
hi
1
2
bye
:end

$ ruby1.9 fbr.rb
:begin
hi
1
2
bye
:end
