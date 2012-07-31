require 'parslet/transform'

module Parslet
  class Slice
    def line
      line_and_column.first
    end
    def column
      line_and_column.last
    end
  end
end

module Maths
  class Transform < Parslet::Transform

    rule(left: simple(:l), op: '=', right: subtree(:r)) {
      Maths::AST::VariableAssignment.new(l.line + offset.to_i, l.column, l.name, r)
    }

    rule(left: subtree(:l), op: simple(:op), right: subtree(:r)) {
      Maths::AST::Call.new(l.line + offset.to_i, l.column, l, op.to_sym, r)
    }

    rule(float: simple(:x)) {
      Maths::AST::Float.new(x.line + offset.to_i, x.column, Float(x))
    }

    rule(int: simple(:x)) {
      Maths::AST::Integer.new(x.line + offset.to_i, x.column, Integer(x))
    }

    rule(var: simple(:x)) {
      Maths::AST::VariableReference.new(x.line + offset.to_i, x.column, x.to_s)
    }

    rule(print: subtree(:x)) {
      Maths::AST::Print.new(x.line + offset.to_i, x.column, x)
    }

    rule(script: subtree(:x)) {
      Maths::AST::Script.new(Array(x))
    }
  end
end
