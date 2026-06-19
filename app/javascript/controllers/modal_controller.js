import { Controller } from "@hotwired/stimulus"

// Controls a native <dialog class="modal"> element. Connects via data-controller="modal".
// open()  -> dialog.showModal() (native focus trap + Escape handling)
// close() -> dialog.close() and restores focus to the trigger.
//
// Trigger a modal from anywhere with:
//   <button data-action="click->modal#open" data-modal-id-param="my-modal">
// or call open()/close() on the controller scoped to the dialog.
export default class extends Controller {
  connect() {
    this.dialog = this.element.tagName === "DIALOG" ? this.element : this.element.querySelector("dialog")
    this.onClose = this.restoreFocus.bind(this)
    if (this.dialog) this.dialog.addEventListener("close", this.onClose)
  }

  disconnect() {
    if (this.dialog) this.dialog.removeEventListener("close", this.onClose)
  }

  open() {
    if (!this.dialog) return
    this.previouslyFocused = document.activeElement
    if (typeof this.dialog.showModal === "function") {
      this.dialog.showModal()
    } else {
      this.dialog.setAttribute("open", "")
    }
  }

  close() {
    if (!this.dialog) return
    if (typeof this.dialog.close === "function") {
      this.dialog.close()
    } else {
      this.dialog.removeAttribute("open")
      this.restoreFocus()
    }
  }

  restoreFocus() {
    if (this.previouslyFocused && typeof this.previouslyFocused.focus === "function") {
      this.previouslyFocused.focus()
    }
  }
}
