module Siren
  E  = Math::E
  PI = Math::PI

  module_function

  def sin(x)
    Float.new(Sin.new(x.node))
  end

  def cos(x)
    Float.new(Cos.new(x.node))
  end

  def tan(x)
    Float.new(Tan.new(x.node))
  end

end
