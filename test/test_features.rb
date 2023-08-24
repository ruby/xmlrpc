# frozen_string_literal: false
require 'test/unit'
require "xmlrpc/create"
require "xmlrpc/parser"
require "xmlrpc/config"

module TestXMLRPC
class Test_Features < Test::Unit::TestCase

  def setup
    @params = [nil, {"test" => nil}, [nil, 1, nil]]
  end

  def test_nil_create
    XMLRPC::XMLWriter.each_installed_writer do |writer|
      c = XMLRPC::Create.new(writer)

      XMLRPC::Config.enable_nil_create = false
      assert_raise(RuntimeError) { c.methodCall("test", *@params) }

      XMLRPC::Config.enable_nil_create = true
      assert_nothing_raised { c.methodCall("test", *@params) }
    end
  end

  def test_nil_parse
    XMLRPC::Config.enable_nil_create = true

    XMLRPC::XMLWriter.each_installed_writer do |writer|
      c = XMLRPC::Create.new(writer)
      str = c.methodCall("test", *@params)
      XMLRPC::XMLParser.each_installed_parser do |parser|
        para = nil

        XMLRPC::Config.enable_nil_parser = false
        assert_raise(RuntimeError) { para = parser.parseMethodCall(str) }

        XMLRPC::Config.enable_nil_parser = true
        assert_nothing_raised { para = parser.parseMethodCall(str) }
        assert_equal(para[1], @params)
      end
    end
  end

end
end
