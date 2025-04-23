require "test-unit"

module TestHelper
  def parser
    case ENV["XMLRPC_PARSER"]
    when "libxml"
      XMLRPC::XMLParser::LibXMLStreamParser.new
    else
      XMLRPC::XMLParser::REXMLStreamParser.new
    end
  end
end
