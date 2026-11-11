import { Controller } from "@hotwired/stimulus"

// Light/dark toggle. Saves the choice in localStorage; with no choice the OS setting is used.
// The <head> script in application.html.erb applies the saved choice before the page paints.
export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.render = this.render.bind(this)
    this.media.addEventListener("change", this.render)
    this.render()
  }

  disconnect() {
    this.media.removeEventListener("change", this.render)
  }

  toggle() {
    const next = this.isDark ? "light" : "dark"
    document.documentElement.dataset.theme = next
    try { localStorage.setItem("theme", next) } catch (e) {}
    this.render()
  }

  get isDark() {
    const chosen = document.documentElement.dataset.theme
    return chosen ? chosen === "dark" : this.media.matches
  }

  render() {
    const dark = this.isDark
    this.iconTarget.textContent = dark ? "☀️" : "🌙"
    this.element.setAttribute("aria-pressed", String(dark))
    this.element.title = dark ? "เปลี่ยนเป็นโหมดสว่าง" : "เปลี่ยนเป็นโหมดมืด"
  }
}
