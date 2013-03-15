# **Noeq** generates GUIDs using [noeqd](https://github.com/bmizerany/noeqd).

# `noeqd` uses a simple TCP wire protocol, so let's require our only dependency,
# `socket`.
require 'socket'

class Noeq
  class ReadTimeoutError < StandardError; end
  SECS_READ_TIMEOUT_FOR_SYCN = 0.1

  # If you just want to test out `noeq` or need to use it in a one-off script,
  # this method allows for very simple usage.
  def self.generate(n=1)
    noeq = new
    ids = noeq.generate(n)
    noeq.disconnect
    ids
  end

  # `Noeq.new` defaults to connecting to `localhost:4444` with async off.
  # The `options` hash is used so that we are verbose when turning async on.
  def initialize(host = 'localhost', port = 4444, options = {})
    @host, @port, @async = host, port, options[:async]
    connect
  end

  # The first thing that we need to do is connect to the `noeqd` server.
  def connect(failures=0)
    # We create a new TCP `STREAM` socket. There are a few other types of
    # sockets, but this is the most common.
    @socket = Socket.new(:INET, :STREAM)

    # If the connection fails after 0.5 seconds, immediately retry.
    set_socket_timeouts 0.5

    # In order to create a socket connection we need an address object.
    address = Socket.sockaddr_in(@port, @host)

    # If async is enabled, we establish the connection in nonblocking mode,
    # otherwise we connect normally, which will wait until the connection is
    # established.
    @async ? @socket.connect_nonblock(address) : @socket.connect(address)

  rescue Errno::EINPROGRESS
    # `Socket.connect_nonblock` raises `Errno::EINPROGRESS` if the socket isn't
    # connected instantly. It will be connected in the background, so we ignore
    # the exception
  rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
    raise if failures == 3
    connect(failures + 1)
  end

  def disconnect
    # If the socket has already been closed by the other side, `close` will
    # raise, so we rescue it.
    @socket.close rescue false
  end

  # The workhorse generate method. Defaults to one id, but up to 255 can be
  # requested.
  def generate(n=1)
    request_id(n)
    fetch_id(n)

    # If something goes wrong, we reconnect and retry. There is a slim chance
    # that this will result in an infinite loop, but most errors are raised in
    # the reconnect step and won't get re-rescued here.
  rescue ReadTimeoutError
    raise
  rescue => exception
    disconnect
    connect
    retry
  end

  def request_id(n=1)
    # The integer is packed into a binary byte and sent to the `noeqd` server.
    # The second argument to `BasicSocket#send` is a bitmask of flags, we don't
    # need anything special, so it is set to zero.
    @socket.send [n].pack('c'), 0
  end
  alias :request_ids :request_id

  def fetch_id(n=1)
    # We collect the ids from the `noeqd` server.
    ids = (1..n).map { get_id }.compact

    # If we have more than one id, we return the array, otherwise we return the
    # single id.
    ids.length > 1 ? ids : ids.first
  end
  alias :fetch_ids :fetch_id

  private

  def set_socket_timeouts(timeout)
    secs = Integer(timeout)
    usecs = Integer((timeout - secs) * 1_000_000)
    optval = [secs, usecs].pack("l_2")
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
    @socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
  end

  def get_id
    # `noeqd` sends us a 64-bit unsigned integer in network (big-endian) byte
    # order, but Ruby 1.8 doesn't have a native unpack directive for this, so we
    # do it manually by shifting the high bits and adding the low bits.
    high, low = read_long, read_long
    return unless high && low
    (high << 32) + low
  end

  def read_long
    # `IO.select` blocks until one of the sockets passed in has an event
    # or a timeout is reached (the fourth argument). We don't do the `select`
    # if we are in async mode.
    unless @async
      ready = IO.select([@socket], nil, nil, SECS_READ_TIMEOUT_FOR_SYCN) 
      raise ReadTimeoutError unless ready
    end

    # Since `select` has already blocked for us, we are pretty sure that
    # there is data available on the socket, so we try to fetch 4 bytes and
    # unpack them as a 32-bit big-endian unsigned integer. If there is no data
    # available this will raise `Errno::EAGAIN` which will propagate up and
    # could cause a retry.
    @socket.recv_nonblock(4).unpack("N").first
  end
end
