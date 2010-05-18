require 'siren/c'
require 'siren/ast'
require 'siren/float'
require 'siren/bool'
require 'siren/math'
require 'siren/code_generator'
require 'siren/voice'
require 'siren/dsp_kernel'

module Kernel
  def target_type_for(tag)
    case tag
    when :float then LLVM::Float
    else
      fail "Unsupported type #{v.type}"
    end
  end
  module_function :target_type_for    
end

module Siren
  def init
    C.InitDSPSystem
  end
  module_function :init
end
