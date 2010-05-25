module Siren
  module Event
    class Base
      def seq(rhs, &f) 
        Seq.new(self, rhs, &f)
      end
      alias :& :seq
     
      def par(rhs)
        Par.new(self, rhs)
      end
      alias :| :par

      def repeat(n)
        ([self] * n).reduce(:&)
      end
      alias :* :repeat
    end

    class Note < Base
      attr_reader :duration
     
      def initialize(dur, voice, params)
        @duration = dur
        @voice    = voice
        @params   = params
      end
    
      def schedule(t, scheduler, kernel)
        scheduler.at(t) do
          voice = @voice.new(kernel, @params)
          scheduler.at(t + @duration + voice.tail) do
            voice.dispose
          end
        end
      end
    end
    
    class Rest < Base
      attr_reader :duration
  
      def initialize(dur)
        @duration = dur
      end
   
      def schedule(t, scheduler, kernel)
      end
    end
  
    class Seq < Base
      attr_reader :duration

      def initialize(fst, snd)
        @fst = fst
        @snd = snd
        @duration = @fst.duration + @snd.duration
      end
     
      def schedule(t, scheduler, kernel)
        @fst.schedule(t, scheduler, kernel)
        @snd.schedule(t + @fst.duration, scheduler, kernel)
      end
    end
    
    class Par < Base
      attr_reader :duration
    
      def initialize(fst, snd)
        @fst, @snd = fst, snd
        @duration = [@fst.duration, @snd.duration].max
      end
     
      def schedule(t, scheduler, kernel)
        @fst.schedule(t, scheduler, kernel)
        @snd.schedule(t, scheduler, kernel)
      end
    end
  end
end

