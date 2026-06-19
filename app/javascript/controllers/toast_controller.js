import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast after a delay. Connects via data-controller="toast".
// Optional data-toast-delay-value overrides the default timeout (ms).
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.remove()
  }
}
