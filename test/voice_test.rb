require File.join(File.dirname(__FILE__), 'test_helper')

class VoiceTest < Test::Unit::TestCase
  include Siren

  def test_new_voice
    using_kernel do |k|
      Siren::C.DSPKernelStart(k)
      v1 = Oscil.new(k, :frequency => 330)
      sleep 0.25
      v2 = Oscil.new(k, :frequency => 440)
      sleep 0.25
      v3 = Oscil.new(k, :frequency => 495)
      sleep 1
      v3.dispose
      v2.dispose
      v1.dispose
      Siren::C.DSPKernelStop(k)
    end
  end
  
  class Oscil < Siren::Voice
    include Siren

    var :frequency, :float, 0.0
    var :phase, :float, 0.0

    def transition
      phase(phase + 1/44100.0)
    end

    def render
      0.2 * Siren.sin(2.0 * Math::PI * frequency * phase)
    end 
  end
end

