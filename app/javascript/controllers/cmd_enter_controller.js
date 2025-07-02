import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="cmd-enter"
export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", (e) => {
      if (!(e.keyCode == 13 && e.metaKey)) return;
      if (this.element.form) this.element.form.requestSubmit();
    });
  }
}
