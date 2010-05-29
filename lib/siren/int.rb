module Siren
  class Int
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def self.const(x)
      Int.new(LiteralInt.new(x))
    end

    def coerce(x)
      case x
      when Int then [x, self]
      else [self.class.const(x), self]
      end
    end

    def to_f
      Float.new(IToF.new(self.node))
    end
  end
end
