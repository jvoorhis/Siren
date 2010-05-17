module Siren
  PI = Math::PI

  def sin(x)
    Float.new(Sin.new(x.node))
  end
  module_function :sin

end
