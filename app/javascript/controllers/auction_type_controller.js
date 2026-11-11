import { Controller } from "@hotwired/stimulus"

// Auction form: sealed auctions have no bid increment, and the starting-price label depends on the method.
export default class extends Controller {
  static targets = ["increment", "priceLabel"]

  change(event) {
    const type = event.target.value
    const sealed = type.endsWith("_sealed")
    const input = this.incrementTarget.querySelector("input")

    this.incrementTarget.hidden = sealed
    input.disabled = sealed
    input.required = !sealed

    const label = type === "reverse" ? "ราคาเพดาน" : sealed ? "ราคาขั้นต่ำ" : "ราคาเริ่มต้น"
    this.priceLabelTarget.textContent = `${label} (บาท) *`
  }
}
