$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'test/unit'

module Test
  module Unit
    module Assertions

      # threads should respond to shift method.
      # Array can be used.
      def assert_join_threads(threads, message = nil)
        errs = []
        values = []
        while th = threads.shift
          begin
            values << th.value
          rescue Exception
            errs << [th, $!]
          end
        end
        if !errs.empty?
          msg = "exceptions on #{errs.length} threads:\n" +
          errs.map {|t, err|
            "#{t.inspect}:\n" +
            err.backtrace.map.with_index {|line, i|
              if i == 0
                "#{line}: #{err.message} (#{err.class})"
              else
                "\tfrom #{line}"
              end
            }.join("\n")
          }.join("\n---\n")
          if message
            msg = "#{message}\n#{msg}"
          end
          raise MiniTest::Assertion, msg
        end
        values
      end
    end
  end
end
