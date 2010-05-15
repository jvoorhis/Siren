require File.join(File.dirname(__FILE__), 'test_helper')

class RuntimeTest < Test::Unit::TestCase
  include Siren

  def setup
    C.InitDSPSystem
  end

  def test_new_kernel
    FFI::MemoryPointer.new(:pointer) do |p|
      assert_equal 0, C.NewDSPKernel(p), "Expected NewDSPKernel to return 0 for success."
      assert !p.read_pointer.null?, "Expected DSPKernel to be set on success."
      kernel = C::DSPKernel.new(p.read_pointer)
      assert !kernel[:stream].null?, "Expected stream to be initialized."
      assert kernel[:voiceList].null?, "Expected voiceList to be initialized to NULL."
    end
  end

  def test_callback
    kernel = DSPKernel.new
    frames = 16
    FFI::MemoryPointer.new(:float, frames) do |out|
      out.write_array_of_float Array.new(frames) { rand() }
      assert_equal 0,
      Siren::C.DSPKernelCallback(
        nil, out,
        frames, nil, 0, kernel)
      assert_equal Array.new(frames, 0.0),
        out.read_array_of_float(frames)
    end
  end

  def test_dsp_kernel_start
    kernel = DSPKernel.new
    assert_equal 0, C.DSPKernelStart(kernel), "Expected DSPKernelStart to return 0 for success."
    assert_equal 0, C.DSPKernelStop(kernel), "Expected DSPKernelStop to return 0 for success."
  end
end
