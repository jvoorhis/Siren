module Siren
  class Bool
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def self.const(x)
      Bool.new(LiteralBool.new(x))
    end

    def &(rhs)
      case rhs
      when Bool
        Bool.new(And.new(self.node, rhs.node))
      else
        b, a = coerce(rhs)
	a & b
      end
    end
    
    def accept(visitor)
      @node.accept(visitor)
    end
  end

  module_function

  def Bool(x)
    case x
    when Bool then x
    else
      Bool.new(LiteralBool.new(x))
    end
  end

  TRUE  = Bool(true)
  FALSE = Bool(false)
end

