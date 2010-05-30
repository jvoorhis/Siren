require 'diatonic'
require 'fm'

include Diatonic::Ctors

TEMPO = 66

def fm(dur, fr, l = 0.1)
  dur = dur * 60.0 / TEMPO
  Siren::Event::Note.new(
    dur, FM,
    duration: dur,
    freq: fr,
    level: l
  )
end

def rest(dur)
  dur = dur * 60.0 / TEMPO
  Siren::Event::Rest.new(dur)
end

score = (
  # intro
  bass  = (((fm(3, g2, 0.8) | (rest(1) & (fm(2, b3) | fm(2, d4)  | fm(2, fs4)))) &
           (fm(3, d2, 0.8)  | (rest(1) & (fm(2, a3) | fm(2, cs4) | fm(2, fs4))))) * 2)
  motif = (rest(1) & fm(1, fs5) & fm(1, a5) & fm(1, g5) & fm(1, fs5) & fm(1, cs5) & fm(1, b4) & fm(1, cs5) & fm(1, d5) & fm(3, a4))
  (bass & (bass | motif) & (bass | fm(12, fs4)) & (bass | motif)) &
  ((fm(3, fs2) | (rest(1) & (fm(2, a3) | fm(2, cs4) | fm(2, fs4)))) | fm(3, cs5)) &
  (fm(3, b1) | (rest(1) & (fm(2, b3) | fm(2, d4) | fm(2, fs4))) | fm(3, fs5))
)

Siren.audition(score, TEMPO, /2ch/)

