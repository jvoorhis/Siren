require 'test/unit'
require 'siren'

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

class FFI::MemoryPointer
  def read_array_of_float(size)
    read_array_of_type(:float, :read_float, size)
  end

  def write_array_of_float(data)
    write_array_of_type(:float, :write_float, data)
  end
end
