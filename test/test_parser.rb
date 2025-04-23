# frozen_string_literal: false
require 'test/unit'
require 'xmlrpc/create'
require 'xmlrpc/datetime'
require 'xmlrpc/parser'
require 'yaml'

# This must be required after xmlrpc/create and xmlrpc/parser.
require 'xmlrpc/config'

module GenericParserTest
  def datafile(base)
    File.join(File.dirname(__FILE__), "data", base)
  end

  def load_data(name)
    [File.read(datafile(name) + ".xml"), YAML.load(File.read(datafile(name) + ".expected"))]
  end

  def setup
    @xml1, @expected1 = load_data('xml1')
    @xml2, @expected2 = load_data('bug_covert')
    @xml3, @expected3 = load_data('bug_bool')
    @xml4, @expected4 = load_data('value')

    @cdata_xml, @cdata_expected = load_data('bug_cdata')

    @datetime_xml = File.read(datafile('datetime_iso8601.xml'))
    @datetime_expected = XMLRPC::DateTime.new(2004, 11, 5, 1, 15, 23)

    @marshallable_xml, @marshallable_expected = load_data('marshallable')

    @fault_doc = File.read(datafile('fault.xml'))
    @marshallable = File.read(datafile('marshallable.xml'))
  end

  # test parseMethodResponse --------------------------------------------------

  def test_parseMethodResponse1
    assert_equal(@expected1, @p.parseMethodResponse(@xml1))
  end

  def test_parseMethodResponse2
    assert_equal(@expected2, @p.parseMethodResponse(@xml2))
  end

  def test_parseMethodResponse3
    assert_equal(@expected3, @p.parseMethodResponse(@xml3))
  end

  def test_cdata
    assert_equal(@cdata_expected, @p.parseMethodResponse(@cdata_xml))
  end

  def test_dateTime
    assert_equal(@datetime_expected, @p.parseMethodResponse(@datetime_xml)[1])
  end

  def test_marshallable
    assert_equal(@marshallable_expected, @p.parseMethodResponse(@marshallable))
  end

  # test parseMethodCall ------------------------------------------------------

  def test_parseMethodCall
    assert_equal(@expected4, @p.parseMethodCall(@xml4))
  end

  # test fault ----------------------------------------------------------------

  def test_fault
    flag, fault = @p.parseMethodResponse(@fault_doc)
    assert_equal(flag, false)
    assert_kind_of(XMLRPC::FaultException, fault, "must be an instance of class XMLRPC::FaultException")
    assert_equal(fault.faultCode, 4)
    assert_equal(fault.faultString, "an error message")
  end

  def test_fault_message
    fault = XMLRPC::FaultException.new(1234, 'an error message')
    assert_equal('an error message', fault.to_s)
    assert_equal('#<XMLRPC::FaultException: an error message>', fault.inspect)
  end
end

# create test class for each installed parser
XMLRPC::XMLParser.each_installed_parser do |parser|
  klass = parser.class
  name = klass.to_s.split("::").last

  test_class = Class.new(Test::Unit::TestCase) do
    include GenericParserTest

    define_method(:setup_parser) do
      @p = klass.new
    end
    setup :setup_parser
  end
  self.class.const_set("Test#{name}", test_class)
end
