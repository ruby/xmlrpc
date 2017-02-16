# frozen_string_literal: false
require 'timeout'

# Backport of WEBrick::Utils::TimeoutHandler.terminate from Ruby 2.4.
unless WEBrick::Utils::TimeoutHandler.respond_to? :terminate
  class WEBrick::Utils::TimeoutHandler
    def self.terminate
      instance.terminate
    end

    def terminate
      TimeoutMutex.synchronize{
        @timeout_info.clear
        @watcher&.kill&.join
      }
    end
  end
end

module TestXMLRPC
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

  def with_server(config, servlet)
    log = []
    logger = WEBrick::Log.new(log, WEBrick::BasicLog::WARN)
    addr = start_server(logger, config) {|w|
      servlet = servlet.call(w) if servlet.respond_to? :call
      w.mount('/RPC2', servlet)
    }
      client_thread = Thread.new {
        begin
          yield addr
        ensure
          @__server.shutdown
        end
      }
      server_thread = Thread.new {
        @__server_thread.join
        @__server = nil
        assert_equal([], log)
      }
      assert_join_threads([client_thread, server_thread])
  end
end
end
