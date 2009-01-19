require 'rubygems'
require 'socket'
include Socket::Constants
require 'net/http'
require 'uri'
require 'thread'
GC.disable
GC.disable
$count = 5000
$url = URI.parse('http://localhost:3005')
$size = 0
$t = Time.now
$count.times do |i|   
  t = Thread.new do
  begin
      res = Net::HTTP.start($url.host, $url.port) { |http| http.get('/images/rails.png') }
      $size = $size + res.body.length
    puts " finished #{i+1} at #{$time = Time.now - $t} with size = #{$size}"
  rescue Exception => e
    puts e
  end
  end
end

sleep 100