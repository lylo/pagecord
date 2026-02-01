import { Controller } from "@hotwired/stimulus"
import CodeMirror from "codemirror"
import "codemirror/mode/xml/xml"
import "codemirror/mode/javascript/javascript"
import "codemirror/mode/css/css"
import "codemirror/mode/htmlmixed/htmlmixed"
import "codemirror/addon/edit/matchbrackets"
import "codemirror/addon/edit/closebrackets"
import "codemirror/addon/fold/xml-fold"
import "codemirror/addon/edit/matchtags"
import "codemirror/addon/edit/closetag"

// Connects to data-controller="html-editor"
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
      mode: "htmlmixed",
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      matchTags: { bothTags: true },
      autoCloseTags: true,
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
