module Siren
  class DSPKernel
    attr_reader :fs, :ts

    def self.devices
      count = C.DSPKernelDeviceCount
      (0...count).map do |device_id|
        p = FFI::MemoryPointer.new(:pointer)
        C.DSPKernelDeviceName(device_id, p)
        p.read_pointer.read_string unless p.null?
      end
    end

    def self.select_device(pattern)
      devices.map.with_index.detect { |d,i| pattern === d }[1]
    end
     
    def initialize(options = {})
      @device_id = options.fetch(:device_id, 0)
      @channels  = options.fetch(:channels, 2)
      @fs        = options.fetch(:fs, 44100.0).to_f
                 
      FFI::MemoryPointer.new(:pointer) do |p|
        unless C.NewDSPKernel(@device_id, @channels, @fs, p).zero?
          fail "Couldn't initialize DSPKernel" 
        end
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
