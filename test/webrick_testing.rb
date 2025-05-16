# frozen_string_literal: false
require 'timeout'

module WEBrick_Testing
  def teardown
    WEBrick::Utils::TimeoutHandler.terminate
    super
  end

  def start_server(logger, config={})
    raise "already started" if defined?(@__server) && @__server
    @__started = false

    @__server = WEBrick::HTTPServer.new(
      {
        :BindAddress => "localhost",
        :Logger => logger,
        :AccessLog => [],
      }.update(config))
    yield @__server
    @__started = true

    addr = @__server.listeners.first.connect_address

    @__server_thread = Thread.new {
      begin
        @__server.start
      rescue IOError => e
        assert_match(/closed/, e.message)
      ensure
        @__started = false
      end
    }

    addr
  end

  def with_server(config, servlet, *args)
    log = []
    logger = WEBrick::Log.new(log, WEBrick::BasicLog::WARN)
    addr = start_server(logger, config) {|w|
      servlet = servlet.call(w) if servlet.respond_to? :call
      w.mount('/RPC2', servlet, *args)
    }

    begin
      yield addr
    ensure
      @__server.shutdown
    end

    @__server_thread.join
    @__server = nil
    assert_equal([], log)
  end
end
