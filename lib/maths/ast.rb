module Maths
  module AST
    class Node
      attr_accessor :line, :column

      def graph
        Rubinius::AST::AsciiGrapher.new(self, Node).print
      end

      def pos(g)
        g.set_line line
      end
    end

    class Script < Node
      include Rubinius::Compiler::LocalVariables

      def initialize(expressions)
        @expressions = expressions
        @variables = {}
      end

      def new_local(name)
        variable = Rubinius::Compiler::LocalVariable.new allocate_slot
        variables[name] = variable
      end

      def assign_local_reference(node)
        unless variable = variables[node.name]
          variable = new_local node.name
        end

        node.variable = variable.reference
      end

      def bytecode(g)
        g.push_state self
        @expressions.each do |exp|
          exp.bytecode(g)
        end
        g.pop_state
      end

      def local_count
        @variables.size
      end

      def local_names
        @variables.keys
      end

      def to_sexp
        [:script, @expressions.map(&:to_sexp)]
      end
    end

    class Call < Node
      def initialize(line, column, receiver, message, argument)
        @line = line
        @column = column
        @receiver = receiver
        @message = message
        @argument = argument
      end

      def bytecode(g)
        @receiver.bytecode(g)
        @argument.bytecode(g)
        pos(g)
        g.send @message, 1
      end

      def to_sexp
        [:op, @message, @receiver.to_sexp, @argument.to_sexp]
      end
    end

    class Integer < Node
      def initialize(line, column, value)
        @line = line
        @column = column
        @value = value
      end

      def bytecode(g)
        g.push_literal(@value)
      end

      def to_sexp
        @value
      end
    end

    class Float < Node
      def initialize(line, column, value)
        @line = line
        @column = column
        @value = value
      end

      def bytecode(g)
        g.push_literal(@value)
      end

      def to_sexp
        @value
      end
    end

    class Print < Node
      def initialize(line, column, value)
        @line = line
        @column = column
        @value = value
      end

      def bytecode(g)
        g.push_const :'Maths'
        g.find_const :'Runtime'
        @value.bytecode(g)
        g.send :puts, 1
      end

      def to_sexp
        [:print, @value.to_sexp]
      end
    end

    class VariableAssignment < Node
      attr_reader :name
      attr_accessor :variable

      def initialize(line, column, name, value)
        @line = line
        @column = column
        @name = name
        @value = value
        @variable = nil
      end

      def bytecode(g)
        unless @variable
          g.state.scope.assign_local_reference self
        end

        if @value
          @value.bytecode(g)
        end

        pos(g)

        @variable.set_bytecode(g)
      end

      def to_sexp
        [:assign, @name, @value.to_sexp]
      end
    end

    class VariableReference < Node
      attr_reader :name
      attr_accessor :variable

      def initialize(line, column, name)
        @line = line
        @column = column
        @name = name
        @variable = nil
      end

      def bytecode(g)
        pos(g)

        unless @variable
          g.state.scope.assign_local_reference self
        end

        @variable.get_bytecode(g)
      end

      def to_sexp
        @name
      end
    end
  end
end
