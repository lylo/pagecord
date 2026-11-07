require "test_helper"

class AudioWaveformAnalyzerTest < ActiveSupport::TestCase
  setup { skip "needs ffmpeg" unless system("which ffmpeg", out: File::NULL) }

  test "records a level per bar that follows the loudness of the track" do
    blob = upload_wav(loud_then_silent)

    blob.analyze
    waveform = blob.reload.metadata[:waveform]

    assert_operator waveform.size, :<=, AudioWaveformAnalyzer::BARS
    assert_equal 100, waveform.first
    assert_equal 0, waveform.last
    assert_equal 2.0, blob.metadata[:duration]
  end

  test "leaves silence without a waveform" do
    blob = upload_wav([ 0 ] * 8_000)

    blob.analyze

    assert blob.reload.analyzed?
    assert_nil blob.metadata[:waveform]
  end

  test "reaches the rendered audio element" do
    blob = upload_wav(loud_then_silent)
    blob.analyze
    post = blogs(:joel).posts.create!(title: "Track", content: ActionText::Attachment.from_attachable(blob).to_html)

    audio = Nokogiri::HTML.fragment(post.content.to_s).at_css("audio")

    assert_equal blob.reload.metadata[:waveform], JSON.parse(audio["data-waveform"])
  end

  private
    def loud_then_silent
      Array.new(8_000) { |i| i.even? ? 20_000 : -20_000 } + [ 0 ] * 8_000
    end

    def upload_wav(samples)
      pcm = samples.pack("s<*")
      header = [ "RIFF", 36 + pcm.bytesize, "WAVE", "fmt ", 16, 1, 1, 8_000, 16_000, 2, 16, "data", pcm.bytesize ].pack("a4Va4a4VvvVVvva4V")

      ActiveStorage::Blob.create_and_upload!(io: StringIO.new(header + pcm), filename: "track.wav", content_type: "audio/wav")
    end
end
