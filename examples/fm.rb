require 'siren'

class FM < Siren::Voice
  # shared state
  param :freq,     :float, 0.0
  param :ratio,    :float, 3.0
  param :duration, :float, 1.0

  # carrier amplitude
  param :level,    :float, 0.1

  # modulator amplitude
  param :index,    :float, 0.4

  def render(gt, vt, c)
    trem(0.3, 0.79, c, gt,
      # operator 1
      env(0.3 * level, duration, 0.01, 15, 0.2, vt) * sin(2 * PI * freq * vt +
        # operator 2
        index * env(1, 3, 0.01, 3, 0.01, vt) * sin(2 * PI * freq * ratio * vt +
          # operator 3
          index * env(0.5, 0.1, 0.01, 0.1, 0.01, vt) * sin(2 * PI * 880 * vt))))
  end

  # envelope generator
  def env(level, duration, a, d, r, t)
    level * (
      u(t)                * (1 - u(t - a))            * t / a +
      u(t - a)            * (1 - u(t - duration + r)) * (1 - (t - a) / d) +
      u(t - duration + r) * (1 - u(t - duration))     * (1 - (t - a) / d) * (1 - (t - duration + r) / r)
    )
  end

  # stereo tremolo
  def trem(mix, freq, chan, phase, sig)
    sig * (mix * sin((chan.to_f + PI) * 2 * PI * freq * phase) + (1 - mix))
  end

  def tail
    1.0
  end
end

