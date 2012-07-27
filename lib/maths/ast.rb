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

      attr_accessor :variable_scope

      def initialize(expressions)
        @expressions = expressions
      end

      def search_scopes(name)
        depth = 1
        scope = @variable_scope
        while scope
          if !scope.method.for_eval? and slot = scope.method.local_slot(name)
            return Compiler::NestedLocalVariable.new(depth, slot)
          elsif scope.eval_local_defined?(name, false)
            return Compiler::EvalLocalVariable.new(name)
          end

          depth += 1
          scope = scope.parent
        end
      end

      # Returns a cached reference to a variable or searches all
      # surrounding scopes for a variable. If no variable is found,
      # it returns nil and a nested scope will create the variable
      # in itself.
      def search_local(name)
        if variable = variables[name]
          return variable.nested_reference
        end

        if variable = search_scopes(name)
          variables[name] = variable
          return variable.nested_reference
        end
      end

      def new_local(name)
        variable = Rubinius::Compiler::EvalLocalVariable.new name
        variables[name] = variable
      end

      def assign_local_reference(node)
        unless reference = search_local(node.name)
          variable = new_local node.name
          reference = variable.reference
        end

        node.variable = reference
      end

      def bytecode(g)
        g.push_state self
        @expressions.each do |exp|
          exp.bytecode(g)
        end
        g.pop_state
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
