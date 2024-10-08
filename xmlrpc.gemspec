# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xmlrpc'

Gem::Specification.new do |spec|
  spec.name          = "xmlrpc"
  spec.version       = XMLRPC::VERSION
  spec.authors       = ["SHIBATA Hiroshi", "Sutou Kouhei"]
  spec.email         = ["hsbt@ruby-lang.org", "kou@cozmixng.org"]

  spec.summary       = %q{XMLRPC is a lightweight protocol that enables remote procedure calls over HTTP.}
  spec.description   = %q{XMLRPC is a lightweight protocol that enables remote procedure calls over HTTP.}
  spec.homepage      = "https://github.com/ruby/xmlrpc"
  spec.licenses      = ["Ruby", "BSD-2-Clause"]

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.3"

  spec.add_dependency "rexml"
  spec.add_dependency "webrick"
end
