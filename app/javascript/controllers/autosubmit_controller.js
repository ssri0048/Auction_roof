import { Controller } from "@hotwired/stimulus"

// Submits the form as soon as a field changes (used for the inline role dropdown).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
