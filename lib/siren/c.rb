require 'ffi'

module Siren
  module C
    extend FFI::Library
    ffi_lib 'ext/libsiren.dylib'

    typedef :int32, :OSSpinLock

    attach_function :InitDSPSystem, [], :int
    attach_function :NewDSPKernel, [:double, :pointer], :int
    attach_function :DisposeDSPKernel, [:pointer], :int
    attach_function :DSPKernelCallback, [:pointer, :pointer, :ulong, :pointer, :int, :pointer], :int
    attach_function :DSPKernelStart, [:pointer], :int
    attach_function :DSPKernelStop, [:pointer], :int
    attach_function :NewVoice, [:pointer, :pointer, :pointer], :pointer
    attach_function :RemoveVoice, [:pointer, :pointer], :int

    class Voice < FFI::Struct
      layout :func,  :pointer,
             :frame, :int,
             :state, :pointer,
             :next,  :pointer
    end

    class DSPKernel < FFI::ManagedStruct
      layout :fs,        :double,
             :stream,    :pointer,
             :frame,     :int,
	     :channels,  :int,
             :voiceList, :pointer,
             :lock,      :OSSpinLock
      
      def self.release(ptr)
        C.DisposeDSPKernel(ptr)
      end
    end 
  end
end
