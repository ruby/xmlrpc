# frozen_string_literal: true
require 'test/unit'
require 'xmlrpc/base64'

module TestXMLRPC
  class Test_Base64 < Test::Unit::TestCase
    def test_equals
      refute_equal(XMLRPC::Base64.new('foobar'), 'foobar')
      refute_equal(XMLRPC::Base64.new('foo'), XMLRPC::Base64.new('bar'))
      assert_equal(XMLRPC::Base64.new('foobar'), XMLRPC::Base64.new('foobar'))
    end
  end
end
