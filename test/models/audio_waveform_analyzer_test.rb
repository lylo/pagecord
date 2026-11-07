require "test_helper"

class AudioWaveformAnalyzerTest < ActiveSupport::TestCase
  setup { skip "needs ffmpeg" unless system("which ffmpeg", out: File::NULL) }

  test "records levels that follow the loudness of the track" do
    blob = upload_wav(tone(8_000) + silence(8_000))

    blob.analyze
    waveform = blob.reload.metadata[:waveform]

    assert_equal 100, waveform.max
    assert_operator waveform.first, :>, 50
    assert_equal 0, waveform.last
    assert_equal 2.0, blob.metadata[:duration]
  end

  test "never records more than the maximum number of bars" do
    blob = upload_wav(tone(240_000))

    blob.analyze

    assert_equal AudioWaveformAnalyzer::BARS, blob.reload.metadata[:waveform].size
  end

  test "doesn't upsample a file with a tiny sample rate" do
    blob = upload_wav(tone(100_000), sample_rate: 1)

    Timeout.timeout(10) { blob.analyze }

    assert_equal AudioWaveformAnalyzer::BARS, blob.reload.metadata[:waveform].size
  end

  test "leaves silence without a waveform" do
    blob = upload_wav(silence(8_000))

    blob.analyze

    assert blob.reload.analyzed?
    assert_nil blob.metadata[:waveform]
  end

  test "leaves an undecodable file without a waveform" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("not audio"), filename: "track.mp3", content_type: "audio/mpeg")

    blob.analyze

    assert blob.reload.analyzed?
    assert_nil blob.metadata[:waveform]
  end

  test "reaches the rendered audio element with its duration" do
    blob = upload_wav(tone(8_000) + silence(8_000))
    blob.analyze
    post = blogs(:joel).posts.create!(title: "Track", content: ActionText::Attachment.from_attachable(blob).to_html)

    audio = Nokogiri::HTML.fragment(post.content.to_s).at_css("audio")

    assert_equal blob.reload.metadata[:waveform], JSON.parse(audio["data-waveform"])
    assert_equal "2.0", audio["data-duration"]
  end

  private
    def tone(count)
      Array.new(count) { |i| i % 8 < 4 ? 20_000 : -20_000 }
    end

    def silence(count)
      [ 0 ] * count
    end

    def upload_wav(samples, sample_rate: 8_000)
      pcm = samples.pack("s<*")
      header = [ "RIFF", 36 + pcm.bytesize, "WAVE", "fmt ", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16, "data", pcm.bytesize ].pack("a4Va4a4VvvVVvva4V")

      ActiveStorage::Blob.create_and_upload!(io: StringIO.new(header + pcm), filename: "track.wav", content_type: "audio/wav")
    end
end
