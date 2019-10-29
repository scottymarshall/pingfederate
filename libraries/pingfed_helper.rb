

module PingfedHelper
  class << self
    def load_dependencies
      require 'socket'
      require 'timeout'
    end

    def port_open?(ip, port, seconds=5, retries=10)
      # => checks if a port is open or not on a remote host
      for i in 1..retries
        Chef::Log.warn("Port Open Check ##{i}")
        Timeout::timeout(seconds) do
          begin
            TCPSocket.new(ip, port).close
            puts "[OPEN]: Port #{port} is open on host #{ip}"
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, SocketError
            next
          rescue => error
            puts "Caught a new one #{error.inspect}"
            next
          end
        end
        sleep seconds
      end
      return false
    end


  end
end
