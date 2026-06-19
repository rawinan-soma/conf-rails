import { Controller } from "@hotwired/stimulus"

// Controls a native <dialog class="modal"> element. Connects via data-controller="modal".
// open()  -> dialog.showModal() (native focus trap + Escape handling)
// close() -> dialog.close() and restores focus to the trigger.
//
// To open the modal, call open() on the controller scoped to the dialog element:
//   this.application.getControllerForElementAndIdentifier(dialogEl, "modal").open()
// Or dispatch a custom event from inside the dialog's subtree:
//   <button data-action="click->modal#open"> (must be inside the <dialog> element)
// Note: data-controller="modal" is on the <dialog> itself, so Stimulus only routes
// actions from elements within that dialog's subtree.
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
    // Guard against double-open: showModal() throws InvalidStateError if already open.
    if (this.dialog.open) return
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
