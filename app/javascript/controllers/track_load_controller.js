import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  track() {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/plain"
      },
      keepalive: true
    })
  }
}
