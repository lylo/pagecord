import * as Lexxy from "lexxy"

// Lexxy's link input is type="url", which refuses a path such as /about. Remove once Lexxy accepts them.
export default class RelativeLinksExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  initializeToolbar(lexxyToolbar) {
    const input = lexxyToolbar.querySelector("lexxy-link-dropdown input")
    if (!input) return

    Object.assign(input, {
      type: "text",
      inputMode: "url",
      autocapitalize: "off",
      spellcheck: false,
      pattern: "[a-zA-Z][a-zA-Z0-9+.\\-]*:.+|[\\/#].*",
      title: "A full URL, or a path on your blog such as /about"
    })
  }
}
