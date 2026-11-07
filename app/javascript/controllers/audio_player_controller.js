import { Controller } from "@hotwired/stimulus"

const SKIP_SECONDS = 5
const BAR_PITCH = 3

export default class extends Controller {
  static values = { playLabel: String, seekLabel: String }

  connect() {
    this.resizeObserver = new ResizeObserver(entries => entries.forEach(({ target }) => this.drawBars(target)))
    this.element.querySelectorAll(".audio-player").forEach(player => player.remove())
    this.element.querySelectorAll("audio[data-waveform]").forEach(audio => this.enhance(audio))
  }

  disconnect() {
    this.resizeObserver.disconnect()
  }

  toggle({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    audio.paused ? audio.play().catch(() => {}) : audio.pause()
  }

  seek(event) {
    const audio = this.audioFor(event.currentTarget)
    const { left, width } = event.currentTarget.getBoundingClientRect()
    this.seekTo(audio, (event.clientX - left) / width * this.duration(audio))
  }

  back({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, audio.currentTime - SKIP_SECONDS)
  }

  forward({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, audio.currentTime + SKIP_SECONDS)
  }

  start({ currentTarget }) {
    this.seekTo(this.audioFor(currentTarget), 0)
  }

  end({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, this.duration(audio))
  }

  render({ target: audio }) {
    const player = audio.previousElementSibling
    const duration = this.duration(audio)
    const played = duration ? audio.currentTime / duration : 0
    const bars = player.querySelectorAll(".audio-player__bar")
    const waveform = player.querySelector(".audio-player__waveform")
    const elapsed = player.querySelector(".audio-player__elapsed")
    const total = this.format(duration)
    const time = `${this.format(audio.currentTime)} / ${total}`
    const widest = total.replace(/\d/g, "0")

    bars.forEach((bar, index) => bar.classList.toggle("audio-player__bar--played", index / bars.length < played))
    player.querySelector(".audio-player__toggle").setAttribute("aria-pressed", !audio.paused)
    elapsed.dataset.time = this.format(audio.currentTime)
    if (elapsed.textContent !== widest) elapsed.textContent = widest
    player.querySelector(".audio-player__total").textContent = ` / ${total}`
    waveform.setAttribute("aria-valuemax", Math.floor(duration))
    waveform.setAttribute("aria-valuenow", Math.floor(audio.currentTime))
    waveform.setAttribute("aria-valuetext", time)
  }

  restore({ target: audio }) {
    const player = audio.previousElementSibling
    this.resizeObserver.unobserve(player.querySelector(".audio-player__waveform"))
    player.remove()
    delete audio.dataset.action
    audio.controls = true
  }

  enhance(audio) {
    if (audio.error || !this.levels(audio)) return

    const player = this.build("div", "audio-player")
    const toggle = this.build("button", "audio-player__toggle", { type: "button", "aria-label": this.playLabelValue, "data-action": "audio-player#toggle" })
    const waveform = this.build("div", "audio-player__waveform", {
      role: "slider",
      tabindex: 0,
      "aria-label": this.seekLabelValue,
      "aria-valuemin": 0,
      "data-action": [
        "click->audio-player#seek",
        "keydown.left->audio-player#back:prevent",
        "keydown.down->audio-player#back:prevent",
        "keydown.right->audio-player#forward:prevent",
        "keydown.up->audio-player#forward:prevent",
        "keydown.home->audio-player#start:prevent",
        "keydown.end->audio-player#end:prevent"
      ].join(" ")
    })

    const clock = this.build("span", "audio-player__time", { "aria-hidden": true })
    clock.append(this.build("span", "audio-player__elapsed"), this.build("span", "audio-player__total"))
    player.append(toggle, waveform, clock)
    audio.before(player)
    audio.controls = false
    audio.dataset.action = [ "play", "pause", "timeupdate", "durationchange" ].map(event => `${event}->audio-player#render`).concat("error->audio-player#restore").join(" ")
    this.render({ target: audio })
    this.resizeObserver.observe(waveform)
  }

  drawBars(waveform) {
    const audio = this.audioFor(waveform)
    const levels = this.fit(this.levels(audio), waveform.clientWidth)
    if (waveform.childElementCount === levels.length) return

    waveform.replaceChildren(...levels.map(level => {
      const bar = this.build("span", "audio-player__bar")
      bar.style.height = `${level}%`
      return bar
    }))
    this.render({ target: audio })
  }

  levels(audio) {
    try {
      const levels = JSON.parse(audio.dataset.waveform)
      return Array.isArray(levels) ? levels : null
    } catch {
      return null
    }
  }

  fit(levels, width) {
    const count = Math.min(levels.length, Math.floor(width / BAR_PITCH))
    return Array.from({ length: count }, (_, index) => {
      const start = Math.floor(index * levels.length / count)
      const end = Math.floor((index + 1) * levels.length / count)
      return Math.max(...levels.slice(start, end))
    })
  }

  audioFor(element) {
    return element.closest(".audio-player").nextElementSibling
  }

  duration(audio) {
    return (Number.isFinite(audio.duration) && audio.duration) || Number(audio.dataset.duration) || 0
  }

  seekTo(audio, seconds) {
    audio.currentTime = Math.min(Math.max(seconds, 0), this.duration(audio))
    this.render({ target: audio })
  }

  format(seconds) {
    const whole = Math.floor(seconds)
    return `${Math.floor(whole / 60)}:${String(whole % 60).padStart(2, "0")}`
  }

  build(tag, className, attributes = {}) {
    const element = document.createElement(tag)
    element.className = className
    Object.entries(attributes).forEach(([ name, value ]) => element.setAttribute(name, value))
    return element
  }
}
