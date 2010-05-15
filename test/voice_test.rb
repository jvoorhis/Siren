require File.join(File.dirname(__FILE__), 'test_helper')

class VoiceTest < Test::Unit::TestCase
  include Siren

  def test_new_voice
    kernel = DSPKernel.new
    kernel.start
    v1 = Oscil.new(kernel, :frequency => 330)
    sleep 0.25
    v2 = Oscil.new(kernel, :frequency => 440)
    sleep 0.25
    v3 = Oscil.new(kernel, :frequency => 495)
    sleep 1
    v3.dispose
    v2.dispose
    v1.dispose
    kernel.stop
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

