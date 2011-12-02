require 'socket'

class Noeq
  def self.generate(n=1)
    noeq = new
    ids = noeq.generate(n)
    noeq.disconnect
    ids
  end

  def initialize(server = 'localhost', port = 4444)
    @server, @port, = server, port
    connect
  end

  def connect
    @socket = TCPSocket.new @server, @port
  end

  def disconnect
    @socket.close rescue false
  end

  def generate(n=1)
    @socket.send [n].pack('c'), 0
    ids = (1..n).map { get_id }.compact
    ids.length > 1 ? ids : ids.first
  rescue
    disconnect
    connect
    retry
  end

  private

  def get_id
    (read_long << 32) + read_long
  end

  def read_long
    @socket.read(4).unpack("N").first
  end
end
