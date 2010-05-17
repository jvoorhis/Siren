module Siren
  class Float
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def self.const(x)
      Float.new(LiteralFloat.new(x))
    end

    def coerce(x)
      case x
      when Float then [x, self]
      else [self.class.const(x), self]
      end
    end

    def +(rhs)
      case rhs
      when Float
        Float.new(FAdd.new(self.node, rhs.node))
      else
        b, a = coerce(rhs)
	a + b
      end
    end

    def -(rhs)
      case rhs
      when Float
        Float.new(FSub.new(self.node, rhs.node))
      else
        b, a = coerce(rhs)
        a - b
      end
    end

    def *(rhs)
      case rhs
      when Float
        Float.new(FMul.new(self.node, rhs.node))
      else
        b, a = coerce(rhs)
        a * b
      end
    end

    def /(rhs)
      case rhs
      when Float
        Float.new(FDiv.new(self.node, rhs.node))
      else
        b, a = coerce(rhs)
        a / b
      end
    end

    def accept(visitor)
      @node.accept(visitor)
    end
  end
end
