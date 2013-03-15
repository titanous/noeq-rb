require 'test/unit'
require './lib/noeq'

class NoeqTest < Test::Unit::TestCase

  def setup
    FakeNoeqd.start
  end

  def teardown
    FakeNoeqd.stop
  end

  def test_simple_generate
    assert_equal expected_id, Noeq.generate
  end

  def test_multiple_generate
    noeq = Noeq.new
    assert_equal [expected_id]*3, noeq.generate(3)
  end

  def test_different_port
    FakeNoeqd.stop
    FakeNoeqd.start(4545)

    noeq = Noeq.new('localhost', 4545)
    assert_equal expected_id, noeq.generate
  end

  def test_reconnect
    noeq = Noeq.new
    assert noeq.generate

    FakeNoeqd.stop
    FakeNoeqd.start

    assert_equal expected_id, noeq.generate
  end

  def test_async_generate
    noeq = Noeq.new('localhost', 4444, :async => true)
    noeq.request_id
    sleep 0.0001
    assert_equal expected_id, noeq.fetch_id
  end

  def test_async_request_with_disconnected_server_raises
    noeq = Noeq.new('localhost', 4444, :async => true)
    FakeNoeqd.stop
    assert_raises(Errno::EPIPE) { noeq.request_id }
  end

  def test_sync_request_with_unresponsive_server_after_connect_raises
    FakeNoeqd.stop
    FakeNoeqd.start(4444, :block_on_read => true)
    noeq = Noeq.new(Noeq::DEFAULT_HOST, 4444)
    assert_raises(Noeq::ReadTimeoutError){  noeq.generate }
  end

  private

  def expected_id
    144897448664367104
  end

end

class FakeNoeqd

  def self.start(port = 4444, options = {})
    @server = new(port, options)
    Thread.new { @server.accept_connections }
  end

  def self.stop
    @server.stop
  end

  def initialize(port, options)
    @options = options
    @socket = TCPServer.new(port)
  end

  def stop
    @socket.close rescue true
  end

  def accept_connections
    while conn = @socket.accept
      while n = conn.read(1)
        if @options[:block_on_read]
          sleep(1)
        end
        conn.send "\x02\x02\xC7v<\x80\x00\x00" * n.unpack('c')[0], 0
      end
    end
  end

end
