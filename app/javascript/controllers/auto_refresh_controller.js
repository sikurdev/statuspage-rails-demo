import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Periodically re-renders the page. With <meta name="turbo-refresh-method"
// content="morph"> Turbo morphs the DOM in place, so only changed bars update.
export default class extends Controller {
  static values = { interval: { type: Number, default: 60000 } }

  connect() {
    this.timer = setInterval(() => Turbo.visit(window.location.href, { action: "replace" }), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
