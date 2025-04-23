# frozen_string_literal: true

require_relative 'helper'

require 'stringio'
require 'xmlrpc/client'
require 'xmlrpc/server'

class TestXMLRPCServer < Test::Unit::TestCase
  include TestHelper

  def test_port
    s = nil
    begin
      stdout, $stdout = $stdout, StringIO.new
      stderr, $stderr = $stderr, StringIO.new
      s = XMLRPC::Server.new(0, '127.0.0.1', 1)
      s.set_parser(parser)
    ensure
      $stdout = stdout
      $stderr = stderr
    end
    refute_equal(0, s.port, 'Selected random port')

    s.add_handler('test.add') { |a, b| a + b }
    srv_thread = Thread.new { s.serve }

    begin
      c = XMLRPC::Client.new('127.0.0.1', '/', s.port)
      c.set_parser(parser)
      assert_equal(7, c.call('test.add', 3, 4))
    ensure
      s.shutdown
      srv_thread.kill
    end
  end
end
