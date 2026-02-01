import { Controller } from "@hotwired/stimulus"
import CodeMirror from "codemirror"
import "codemirror/mode/javascript/javascript"
import "codemirror/addon/edit/matchbrackets"
import "codemirror/addon/edit/closebrackets"

// Connects to data-controller="js-editor"
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
      mode: "javascript",
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      lineWrapping: true,
      tabSize: 2,
      viewportMargin: Infinity
    })
  }

  setupFormSync() {
    this.element.closest("form")?.addEventListener("submit", () => {
      this.editor.save()
    })
  }
}
