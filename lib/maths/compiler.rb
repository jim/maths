module Maths
  class Compiler < Rubinius::Compiler

    attr_accessor :transform

    def self.compile(string, file_name='(maths)', line_number=1)
      compiler = new :maths_parser, :compiled_method
      compiler.parser.input string
      compiler.generator.line_number line_number
      compiler.generator.file_name file_name
      yield compiler if block_given?
      compiler.run
    end

    class Generator < Rubinius::Compiler::Stage
      stage :maths_generator
      next_stage Rubinius::Compiler::Encoder

      attr_accessor :variable_scope

      def line_number(number)
        @line = number
      end

      def file_name(name)
        @file = name
      end

      def initialize(compiler, last)
        super
        compiler.generator = self
      end

      def run
        @input.variable_scope = @variable_scope if @variable_scope
        g = Rubinius::Generator.new
        g.name = :call
        g.file = @file.intern

        g.set_line @line

        g.required_args = 0
        g.total_args = 0
        g.splat_index = nil

        g.local_count = 0
        g.local_names = []

        @input.bytecode(g)

        g.ret
        g.close

        g.local_count = @input.local_count
        g.local_names = @input.local_names

        @output = g
        run_next
      end
    end

    class Transform < Rubinius::Compiler::Stage
      stage :maths_transform
      next_stage Generator

      def initialize(compiler, last)
        super
        compiler.transform = self
      end

      def print_ast(enable=true)
        @print_ast = enable
      end

      def print_sexp(enable=true)
        @print_sexp = enable
      end

      def run
        @output = Maths::Transform.new.apply(@input)
        @output.graph if @print_ast
        pp @output.to_sexp if @print_sexp
        run_next
      end
    end

    class Parser < Rubinius::Compiler::Stage
      stage :maths_parser
      next_stage Maths::Compiler::Transform

      def initialize(compiler, last)
        super
        compiler.parser = self
      end

      def print_tree(enable=true)
        @print_tree = enable
      end

      def run
        @output = Maths::Parser.new.parse_with_debug(@input)
        pp @output if @print_tree
        run_next
      end
    end

  end
end
