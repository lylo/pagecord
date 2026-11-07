class AudioWaveformAnalyzer < ActiveStorage::Analyzer::AudioAnalyzer
  BARS = 150
  SAMPLE_RATE = 8_000

  def metadata
    download_blob_to_tempfile do |file|
      @probe = probe_from(file)
      super.merge(waveform: waveform_from(file)).compact
    end
  end

  private
    def waveform_from(file)
      return unless duration&.positive?

      levels = levels_from(file)
      loudest = levels.max.to_f
      levels.map { |level| (level / loudest * 100).round } if loudest.positive?
    end

    def levels_from(file)
      IO.popen(decode_command(file), "rb", err: File::NULL) do |pcm|
        levels = []
        while chunk = pcm.read(bytes_per_bar)
          samples = chunk.unpack("s<*")
          levels << Math.sqrt(samples.sum { it * it }.fdiv(samples.size))
        end
        levels
      end
    end

    def decode_command(file)
      [ ActiveStorage.paths[:ffmpeg] || "ffmpeg", "-v", "error",
        *Shellwords.split(ActiveStorage.ffprobe_arguments),
        "-i", file.path, "-ac", "1", "-ar", SAMPLE_RATE.to_s, "-f", "s16le", "-" ]
    end

    def bytes_per_bar
      (duration * SAMPLE_RATE / BARS).ceil * 2
    end
end
