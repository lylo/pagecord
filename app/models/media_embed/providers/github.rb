module MediaEmbed
  module Providers
    class Github < Base
      REGEX = %r{\Ahttps://gist\.github\.com/([a-zA-Z0-9_.-]+)/([a-zA-Z0-9]+)}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        username, gist_id = match.captures
        iframe = iframe(nil,
          class: "gist-embed-iframe",
          srcdoc: srcdoc(username, gist_id),
          style: "margin-block: 0; width: 100%; height: 400px; border: none")

        @view.tag.div(iframe,
          class: "gist-embed-container",
          style: style(
            "margin-block: 0 var(--lexxy-content-margin, 1em)",
            "border: 1px solid var(--border-color, rgba(128, 128, 128, 0.3))",
            "border-radius: 6px",
            "overflow: hidden"
          ))
      end

      private

        def srcdoc(username, gist_id)
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <base target="_parent">
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>html,body{margin:0;padding:0;overflow:hidden;-webkit-text-size-adjust:100%;text-size-adjust:100%;}body>.gist{margin:0!important;}.gist>.gist-file{margin-bottom:0!important;}@media(max-width:767px){.gist .blob-wrapper,.gist .blob-code,.gist .blob-num{font-size:12px!important;line-height:1.4!important;}}</style>
              </head>
              <body>
                <script src="https://gist.github.com/#{username}/#{gist_id}.js"></script>
              </body>
            </html>
          HTML
        end
    end
  end
end
