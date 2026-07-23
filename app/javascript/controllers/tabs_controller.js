import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const index = Number(event.params.index)

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })

    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.classList.toggle("bg-white", active)
      tab.classList.toggle("dark:bg-slate-900", active)
      tab.classList.toggle("text-slate-900", active)
      tab.classList.toggle("dark:text-white", active)
      tab.classList.toggle("shadow-sm", active)
      tab.classList.toggle("text-slate-500", !active)
      tab.classList.toggle("dark:text-slate-400", !active)
    })
  }
}
