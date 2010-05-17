module Siren
  class DSPKernel
    attr_reader :fs, :ts

    def initialize(options = {})
      @fs = options.fetch(:fs, 44100.0).to_f
                 
      FFI::MemoryPointer.new(:pointer) do |p|
        fail "Couldn't initialize DSPKernel" unless C.NewDSPKernel(@fs, p).zero?
	@kernel = C::DSPKernel.new(p.read_pointer)
      end
    end

    def ts
      1 / @fs
    end

    def to_ptr
      @kernel.to_ptr
    end

    def start
      fail "Couldn't start DSPKernel" unless C.DSPKernelStart(@kernel).zero?
    end

    def stop
      fail "Couldn't stop DSPKernel" unless C.DSPKernelStop(@kernel).zero?
    end
  end
end
