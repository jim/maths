module Maths
  module Runtime
    class Error < RuntimeError
      attr_accessor :line, :column
      def initialize(line, column, message = nil)
        @line = line
        @column = column
        @message = message || "An error occured"
      end
      def message
        "#{@message} on line #{@line}, column #{@column}."
      end
    end

    def self.puts(*args)
      Kernel.puts(*args)
    end
  end
end
