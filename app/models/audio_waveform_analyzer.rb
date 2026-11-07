class AudioWaveformAnalyzer < ActiveStorage::Analyzer::AudioAnalyzer
  BARS = 150
  ALLOWED_FORMATS = "mov,mp3,wav"
  MAX_SAMPLE_RATE = 4_000
  MAX_SECONDS = 6.hours.to_i
  MAX_CPU_SECONDS = 120
  FIRST_CHUNK_BYTES = 256

  def metadata
    download_blob_to_tempfile do |file|
      @probe = probe_from(file)
      super.merge(waveform: waveform_from(file)).compact
    end
  end

  private
    def waveform_from(file)
      return unless sample_rate&.positive?

      levels = energies_from(file)&.then { to_bars(it) }&.map { Math.sqrt(it) }
      loudest = levels&.max
      levels.map { (it / loudest * 100).round } if loudest&.positive?
    end

    # Merges the bars in pairs and doubles the chunk size whenever they fill up, so the file's headers can't affect the size of the output.
    def energies_from(file)
      energies = []
      bytes = FIRST_CHUNK_BYTES

      IO.popen(decode_command(file), "rb", err: File::NULL) do |pcm|
        while chunk = pcm.read(bytes)
          samples = chunk.unpack("s<*")
          energies << samples.sum { it * it }.fdiv(samples.size)

          if energies.size == BARS * 2
            energies = energies.each_slice(2).map { it.sum / 2 }
            bytes *= 2
          end
        end
      end

      energies if $?.success?
    end

    def to_bars(energies)
      count = energies.size
      return energies if count <= BARS

      Array.new(BARS) do |bar|
        part = energies[(bar * count / BARS)...((bar + 1) * count / BARS)]
        part.sum / part.size
      end
    end

    def decode_command(file)
      [ ActiveStorage.paths[:ffmpeg] || "ffmpeg", "-nostdin", "-v", "error",
        "-timelimit", MAX_CPU_SECONDS.to_s, "-format_whitelist", ALLOWED_FORMATS,
        "-i", file.path, "-map", "0:a:0", "-t", MAX_SECONDS.to_s, "-ac", "1",
        "-ar", [ sample_rate, MAX_SAMPLE_RATE ].min.to_s, "-f", "s16le", "-" ]
    end
end
