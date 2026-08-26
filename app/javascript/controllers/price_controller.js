import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount"]

  connect() {
    if (!this.hasAmountTarget) return

    fetch("/prices.json", { headers: { Accept: "application/json" } })
      .then((response) => (response.ok ? response.json() : null))
      .then((prices) => prices && this.#apply(prices))
      .catch(() => {})
  }

  #apply(prices) {
    this.amountTargets.forEach((amount) => {
      const price = prices[amount.dataset.pricePlan]
      if (price) amount.textContent = price
    })
  }
}
