require 'parslet/transform'

module Maths
  class Rewriter < Parslet::Transform
    rule(split: subtree(:tree)) { |dictionary| rewrite(dictionary[:tree]) }

    def self.rewrite(tree)
      first, second, *rest = tree
      return tree unless first.key?(:left) && !first.key?(:right)
      merged = first.merge(second)
      rest.empty? ? merged : rewrite(rest.unshift({left: merged}))
    end
  end
end
