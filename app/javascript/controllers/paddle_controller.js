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
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        subscription_id: this.data.get('id')
      })
    })
    .then(response => response.json())
    .then(data => {
      Paddle.Checkout.open({
        transactionId: data.transaction_id
      });
    });
  }
}