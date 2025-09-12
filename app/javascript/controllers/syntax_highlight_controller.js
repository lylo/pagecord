import { Controller } from "@hotwired/stimulus"
import { highlightAll } from "lexxy"

export default class extends Controller {
  connect() {
    highlightAll()
  }
}