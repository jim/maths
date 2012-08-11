require 'parslet'
require 'parslet/convenience'

module Maths

  class Parser < Parslet::Parser
    rule(:space)        { str(' ').repeat(1) }
    rule(:space?)       { space.maybe }

    rule(:empty)        { str('') }

    rule(:line_break)   { str("\n") }

    rule(:op_plus)      { str('+') }
    rule(:op_minus)     { str('-') }
    rule(:op_multiply)  { str('*') }
    rule(:op_divide)    { str('/') }
    rule(:op_assign)    { str('=') }

    rule(:left_paren)   { str('(') }
    rule(:right_paren)  { str(')') }

    rule(:integer)  {
      ( str('-').maybe >> match['\d'].repeat(1) ).as(:int)
    }

    rule(:decimal) {
      ( str('-').maybe >>
        match['\d'].repeat >>
        str('.') >>
        match['\d'].repeat(1)
      ).as(:dec)
    }

    rule(:variable) { match['a-z'].repeat(1).as(:var) }

    rule(:print) {
      ( str('Print') >> space >> expression ).as(:print)
    }

    rule(:assignment) {
      ( variable.as(:left) >> space? >>
        op_assign.as(:op) >> space? >>
        assignment.as(:right) ) |
      additive
    }

    rule(:additive) {
      ( multiplicative.as(:left) >> space? >>
        ( op_plus | op_minus ).as(:op) >> space? >>
        additive.as(:right) ) |
      multiplicative
    }

    rule(:multiplicative) {
      ( primary.as(:left) >> space? >>
        ( op_multiply | op_divide ).as(:op) >> space? >>
        multiplicative.as(:right) ) |
      primary
    }

    rule(:primary) {
      ( left_paren >> space? >> additive >> space? >> right_paren ) |
      variable |
      decimal |
      integer
    }

    rule(:expression) { assignment }

    rule(:line) {
      print | expression | empty
    }

    rule(:script) { (line >> ( line_break >> line ).repeat).as(:script) }

    root(:script)
  end
end

# sources
# http://nathansuniversity.com/turtle2.html (PEG arithmetic infix notation) 7/17/2012
