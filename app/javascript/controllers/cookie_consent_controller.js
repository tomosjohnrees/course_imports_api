import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    if (!this.hasDismissed()) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  dismiss() {
    const maxAge = 365 * 24 * 60 * 60
    document.cookie = `cookie_consent=dismissed; path=/; max-age=${maxAge}; SameSite=Lax; Secure`
    this.bannerTarget.classList.add("hidden")
  }

  hasDismissed() {
    return document.cookie.split("; ").some(c => c.startsWith("cookie_consent="))
  }
}
