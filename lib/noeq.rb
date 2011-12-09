require 'socket'

class Noeq
  def self.generate(n=1)
    noeq = new
    ids = noeq.generate(n)
    noeq.disconnect
    ids
  end

  def initialize(server = 'localhost', port = 4444, options = {})
    @server, @port, @async = server, port, options[:async]
    connect
  end

  def connect
    @socket = Socket.new(:INET, :STREAM, 0)
    address = Socket.sockaddr_in(@port, @server)
    if @async
      @socket.connect_nonblock(address)
    else
      @socket.connect(address)
    end
  rescue Errno::EINPROGRESS
  end

  def disconnect
    @socket.close rescue false
  end

  def generate(n=1)
    request_id(n)
    fetch_id(n)
  rescue
    disconnect
    connect
    retry
  end

  def request_id(n=1)
    @socket.send [n].pack('c'), 0
  end

  def fetch_id(n=1)
    ids = (1..n).map { get_id }.compact
    ids.length > 1 ? ids : ids.first
  end

  alias

  private

  def get_id
    high, low = read_long, read_long
    return unless high && low
    (high << 32) + low
  end

  def read_long
    IO.select([@socket], nil, nil, 0.1) unless @async
    @socket.recv_nonblock(4).unpack("N").first
  end
end
