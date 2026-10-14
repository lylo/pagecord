import { Application } from "@hotwired/stimulus"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"

lazyLoadControllersFrom("controllers", Application.start())
