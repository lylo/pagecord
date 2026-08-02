import { Controller } from "@hotwired/stimulus"
import CodeMirror from "codemirror"
import "codemirror/mode/css/css"
import "codemirror/mode/xml/xml"
import "codemirror/mode/javascript/javascript"
import "codemirror/mode/htmlmixed/htmlmixed"
import "codemirror/addon/edit/matchbrackets"
import "codemirror/addon/edit/closebrackets"
import "codemirror/addon/fold/xml-fold"
import "codemirror/addon/edit/closetag"
import "codemirror/addon/edit/matchtags"
import "codemirror/addon/hint/show-hint"
import "codemirror/addon/hint/css-hint"

// Connects to data-controller="code-editor"
export default class extends Controller {
  static targets = ["textarea"]
  static values = { mode: { type: String, default: "css" } }

  connect() {
    this.initializeEditor()
    this.setupFormSync()
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
    }
  }

  get html() {
    return this.modeValue === "htmlmixed"
  }

  initializeEditor() {
    this.editor = CodeMirror.fromTextArea(this.textareaTarget, {
      mode: this.modeValue,
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      lineWrapping: true,
      tabSize: 2,
      viewportMargin: Infinity,
      autoCloseTags: this.html,
      matchTags: this.html ? { bothTags: true } : false,
      extraKeys: this.html ? {} : { "Ctrl-Space": "autocomplete" }
    })

    if (!this.html) this.setupCssAutocomplete()
  }

  // Trigger autocomplete on typing
  setupCssAutocomplete() {
    this.editor.on("inputRead", (editor, change) => {
      if (change.origin !== "setValue" && change.text[0].match(/[a-z0-9._-]/i)) {
        editor.showHint({ completeSingle: false })
      }
    })
  }

  setupFormSync() {
    this.element.closest("form")?.addEventListener("submit", () => {
      this.editor.save()
    })
  }
}
