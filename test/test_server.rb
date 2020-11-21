# coding: utf-8
# frozen_string_literal: true

require 'test/unit'
require 'stringio'
require 'xmlrpc/client'
require 'xmlrpc/server'

module TestXMLRPC
class TestXMLRPCServer < Test::Unit::TestCase
  def test_port
    s = nil
    begin
      stdout, $stdout = $stdout, StringIO.new
      stderr, $stderr = $stderr, StringIO.new
      s = XMLRPC::Server.new(0, '127.0.0.1', 1)
    ensure
      $stdout = stdout
      $stderr = stderr
    end
    refute_equal(0, s.port, 'Selected random port')

    s.add_handler('test.add') { |a, b| a + b }
    srv_thread = Thread.new { s.serve }

    begin
      c = XMLRPC::Client.new('127.0.0.1', '/', s.port)
      assert_equal(7, c.call('test.add', 3, 4))
    ensure
      s.shutdown
      srv_thread.kill
    end
  end
end
end
