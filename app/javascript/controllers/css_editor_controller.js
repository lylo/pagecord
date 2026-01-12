import { Controller } from "@hotwired/stimulus"
import CodeMirror from "codemirror"
import "codemirror/mode/css/css"
import "codemirror/addon/edit/matchbrackets"
import "codemirror/addon/edit/closebrackets"
import "codemirror/addon/hint/show-hint"
import "codemirror/addon/hint/css-hint"

// Connects to data-controller="css-editor"
export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    this.initializeEditor()
    this.setupFormSync()
  }

  disconnect() {
    if (this.editor) {
      this.editor.toTextArea()
    }
  }

  initializeEditor() {
    this.editor = CodeMirror.fromTextArea(this.textareaTarget, {
      mode: "css",
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      lineWrapping: true,
      tabSize: 2,
      viewportMargin: Infinity,
      extraKeys: { "Ctrl-Space": "autocomplete" }
    })

    // Trigger autocomplete on typing
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
