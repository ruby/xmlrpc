# frozen_string_literal: true

require "test/unit"
require "rack/test"
require "xmlrpc/server"
require 'xmlrpc/create'
require 'xmlrpc/parser'

class TestRack < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    s = XMLRPC::RackApplication.new

    s.add_handler("test.add") do |a,b|
      a + b
    end

    s.add_handler("test.div") do |a,b|
      if b == 0
        raise XMLRPC::FaultException.new(1, "division by zero")
      else
        a / b
      end
    end

    s.set_default_handler do |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
            " or wrong number of parameters!")
    end

    s.add_introspection

    s
  end

  def test_successful_call
    assert_equal([true, 9],
                 call("test.add", 4, 5))
  end

  def test_fault_exception
    assert_equal([false, XMLRPC::FaultException.new(1, "division by zero")],
                 call("test.div", 1, 0))
  end

  def test_introspection
    assert_equal([true, methods = ["test.add", "test.div", "system.listMethods", "system.methodSignature", "system.methodHelp"]],
                 call("system.listMethods"))
  end

  def test_missing_handler
    assert_equal([false, XMLRPC::FaultException.new(-99, "Method test.nonexisting missing or wrong number of parameters!")],
                 call("test.nonexisting"))
  end

  def test_wrong_number_of_arguments
    assert_equal([false, XMLRPC::FaultException.new(-99, "Method test.add missing or wrong number of parameters!")],
                 call("test.add", 1, 2, 3))
  end

  def test_multibyte_characters
    assert_equal([true, "あいうえおかきくけこ"],
                 call("test.add", "あいうえお", "かきくけこ"))
  end

  def test_method_not_allowed
    get("/", "<stub />", "CONTENT_TYPE" => "text/xml")
    assert(last_response.method_not_allowed?, "Expected HTTP status code 405, got #{last_response.status} instead")
  end

  def test_bad_content_type
    post("/", "<stub />", "CONTENT_TYPE" => "text/plain")
    assert(last_response.bad_request?, "Expected HTTP status code 400, got #{last_response.status} instead")
  end

  def test_empty_request
    post("/", "", "CONTENT_TYPE" => "text/xml")
    assert_equal(411, last_response.status, "Expected HTTP status code 411, got #{last_response.status} instead")
  end

  def call(methodname, *args)
    create = XMLRPC::Create.new(XMLRPC::Config.default_writer.new)
    parser = XMLRPC::Config.default_parser.new

    request = create.methodCall(methodname, *args)
    post("/", request, "CONTENT_TYPE" => "text/xml")
    assert(last_response.ok?, "Expected HTTP status code 200, got #{last_response.status} instead")
    parser.parseMethodResponse(last_response.body)
  end
end
