# Poor Man's Fiber (API compatible Thread based Fiber implementation for Ruby 1.8)
# (c) 2008 Aman Gupta (tmm1)

unless defined? Fiber
  $:.unshift File.expand_path(File.dirname(__FILE__)) + '/compat'

  class FiberError < StandardError; end

  class Fiber
    def initialize
      raise ArgumentError, 'new Fiber requires a block' unless block_given?

      @alive = true

      unless @yield = callcc{|c| c }
        @ret = yield @ret
        @alive = false
        @resume.call
      end
    end
    attr_reader :thread

    def resume *args
      raise FiberError, 'dead fiber called' unless @alive

      if @resume = callcc{|c| c }
        prev_fiber, Thread.current[:fiber] = Thread.current[:fiber], self
        @ret = args.size > 1 ? args : args.first
        @yield.call
      end

      Thread.current[:fiber] = prev_fiber
      @ret
    end

    def yield *args
      if @yield = callcc{|c| c }
        @ret = args.size > 1 ? args : args.first
        @resume.call
      end

      @ret
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
