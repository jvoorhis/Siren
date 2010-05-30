require 'siren/c'
require 'siren/ast'
require 'siren/int'
require 'siren/float'
require 'siren/bool'
require 'siren/math'
require 'siren/code_generator'
require 'siren/voice'
require 'siren/dsp_kernel'
require 'siren/event'

require 'gamelan'

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
  module_function

  def init!
    C.InitDSPSystem
  end

  def audition(score, tempo, device_spec)
    Siren.init!
    device = Siren::DSPKernel.select_device(device_spec)
    kernel = Siren::DSPKernel.new(:device_id => device)
    scheduler = Gamelan::Scheduler.new(:tempo => tempo)
    score.schedule(0, scheduler, kernel)
    scheduler.at(score.duration) { scheduler.stop }
    kernel.start
    scheduler.run
    scheduler.join
    kernel.stop
  end
end
