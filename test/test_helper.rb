require 'test/unit'
require 'siren'

class FFI::MemoryPointer
  def read_array_of_float(size)
    read_array_of_type(:float, :read_float, size)
  end

  def write_array_of_float(data)
    write_array_of_type(:float, :write_float, data)
  end
end
