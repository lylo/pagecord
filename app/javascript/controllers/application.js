import { Application, defaultSchema } from "@hotwired/stimulus"

const application = Application.start(document.documentElement, {
  ...defaultSchema,
  keyMappings: { ...defaultSchema.keyMappings, period: "." }
})

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
