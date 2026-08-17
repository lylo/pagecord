import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.linkTarget.addEventListener("click", (event) => {
      event.preventDefault();
      this.updatePayment();
    })
  }

  updatePayment() {
    fetch("/billing/paddle/create_update_payment_method_transaction", {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.ok ? response.json() : Promise.reject(response))
    .then(data => {
      Paddle.Checkout.open({
        transactionId: data.transaction_id
      });
    })
    .catch(() => {
      this.element.querySelector(".payment-method-error")?.remove()
      this.linkTarget.insertAdjacentHTML("afterend",
        '<p class="payment-method-error pb-3 text-sm text-red-600 dark:text-red-400">Sorry, we couldn\'t open your card details just now. Please try again.</p>')
    });
  }
}