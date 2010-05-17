module Siren
  class LiteralFloat
    attr_reader :value
    
    def initialize(value)
      @value = value.to_f
    end

    def accept(visitor)
      visitor.visit_literal_float(@value)
    end
  end

  class Data
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def accept(visitor)
      visitor.visit_data(@data)
    end
  end

  class FMul
    attr_reader :lhs, :rhs

    def initialize(lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end

    def accept(visitor)
      l = @lhs.accept(visitor)
      r = @rhs.accept(visitor)
      visitor.visit_fmul(l, r)
    end
  end

  class FDiv
    attr_reader :lhs, :rhs

    def initialize(lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end

    def accept(visitor)
      l = @lhs.accept(visitor)
      r = @lhs.accept(visitor)
      visitor.visit_fdiv(l, r)
    end
  end

  class FAdd
    attr_reader :lhs, :rhs
    
    def initialize(lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end

    def accept(visitor)
      l = @lhs.accept(visitor)
      r = @rhs.accept(visitor)
      visitor.visit_fadd(l, r)
    end
  end

  class FSub
    attr_reader :lhs, :rhs

    def initialize(lhs, rhs)
      @lhs, @rhs = lhs, rhs
    end

    def accept(visitor)
      l = @lhs.accept(visitor)
      r = @rhs.accept(visitor)
      visitor.visit_fsub(l, r)
    end
  end

  class Sin
    attr_reader :arg

    def initialize(arg)
      @arg = arg
    end

    def accept(visitor)
      a = @arg.accept(visitor)
      visitor.visit_sin(a)
    end
  end

  class Seq
    attr_reader :fst, :snd

    def initialize(fst, snd)
      @fst, @snd = fst, snd
    end

    def accept(visitor)
      @fst.accept(visitor)
      @snd.accept(visitor)
    end
  end

  class Get
    attr_reader :variable

    def initialize(variable)
      @variable = variable
    end

    def accept(visitor)
      visitor.visit_get(@variable)
    end
  end

  class Set
    attr_reader :variable, :value

    def initialize(variable, value)
      @variable, @value = variable, value
    end

    def accept(visitor)
      v = @value.accept(visitor)
      visitor.visit_put(@variable, v)
    end
  end
  
  class Var < Struct.new(:name, :type, :default)
    def target_type
      target_type_for(self.type)
    end
  end
end
