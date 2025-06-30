import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { key: String };
  static targets = ["textarea"];

  connect() {
    this.storageKey =
      this.keyValue ||
      `persist_input_${
        this.textareaTarget.name || this.textareaTarget.id || "default"
      }`;
    this.restoreValue();
    this.textareaTarget.addEventListener("input", this.saveValue.bind(this));
    this.textareaTarget.addEventListener("change", this.saveValue.bind(this));
    this.element.addEventListener("submit", this.clearOnSubmit.bind(this));
  }

  disconnect() {
    this.textareaTarget.removeEventListener("input", this.saveValue.bind(this));
    this.textareaTarget.removeEventListener(
      "change",
      this.saveValue.bind(this),
    );
    this.element.removeEventListener("submit", this.clearOnSubmit.bind(this));
  }

  restoreValue() {
    const savedValue = localStorage.getItem(this.storageKey);
    if (savedValue && !this.textareaTarget.value) {
      this.textareaTarget.value = savedValue;
      this.textareaTarget.dispatchEvent(new Event("input", { bubbles: true }));
    }
  }

  saveValue() {
    if (this.textareaTarget.value.trim()) {
      localStorage.setItem(this.storageKey, this.textareaTarget.value);
    } else {
      localStorage.removeItem(this.storageKey);
    }
  }

  clear() {
    localStorage.removeItem(this.storageKey);
    this.textareaTarget.value = "";
    this.textareaTarget.dispatchEvent(new Event("input", { bubbles: true }));
  }

  clearOnSubmit() {
    localStorage.removeItem(this.storageKey);
  }
}
