import { Controller } from "@hotwired/stimulus"

const SKIP_SECONDS = 5
const BAR_PITCH = 3

export default class extends Controller {
  connect() {
    this.element.querySelectorAll(".audio-player").forEach(player => player.remove())
    this.element.querySelectorAll("audio[data-waveform]").forEach(audio => this.enhance(audio))
  }

  toggle({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    audio.paused ? audio.play() : audio.pause()
  }

  seek(event) {
    const audio = this.audioFor(event.currentTarget)
    const { left, width } = event.currentTarget.getBoundingClientRect()
    this.seekTo(audio, (event.clientX - left) / width * audio.duration)
  }

  back({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, audio.currentTime - SKIP_SECONDS)
  }

  forward({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, audio.currentTime + SKIP_SECONDS)
  }

  render({ target: audio }) {
    const player = audio.previousElementSibling
    const duration = audio.duration || 0
    const played = duration ? audio.currentTime / duration : 0
    const bars = player.querySelectorAll(".audio-player__bar")
    const waveform = player.querySelector(".audio-player__waveform")
    const clock = player.querySelector(".audio-player__time")
    const time =`${this.format(audio.currentTime)} / ${this.format(duration)}`

    bars.forEach((bar, index) => bar.classList.toggle("audio-player__bar--played", index / bars.length < played))
    player.querySelector(".audio-player__toggle").setAttribute("aria-pressed", !audio.paused)
    clock.dataset.time = time
    clock.textContent = `${this.format(duration)} / ${this.format(duration)}`.replace(/\d/g, "0")
    waveform.setAttribute("aria-valuemax", Math.floor(duration))
    waveform.setAttribute("aria-valuenow", Math.floor(audio.currentTime))
    waveform.setAttribute("aria-valuetext", time)
  }

  enhance(audio) {
    const levels = JSON.parse(audio.dataset.waveform)
    const player = this.build("div", "audio-player")
    const toggle = this.build("button", "audio-player__toggle", { type: "button", "aria-label": "Play", "data-action": "audio-player#toggle" })
    const waveform = this.build("div", "audio-player__waveform", {
      role: "slider",
      tabindex: 0,
      "aria-label": "Seek",
      "aria-valuemin": 0,
      "data-action": "click->audio-player#seek keydown.left->audio-player#back keydown.right->audio-player#forward"
    })

    player.append(toggle, waveform, this.build("span", "audio-player__time", { "aria-hidden": true }))
    audio.before(player)
    this.render({ target: audio })

    this.fit(levels, waveform.clientWidth).forEach(level => {
      const bar = this.build("span", "audio-player__bar")
      bar.style.height = `${level}%`
      waveform.append(bar)
    })

    audio.controls = false
    audio.dataset.action = "play->audio-player#render pause->audio-player#render timeupdate->audio-player#render durationchange->audio-player#render"
  }

  fit(levels, width) {
    const count = Math.min(levels.length, Math.floor(width / BAR_PITCH)) || levels.length
    return Array.from({ length: count }, (_, index) => {
      const start = Math.floor(index * levels.length / count)
      const end = Math.floor((index + 1) * levels.length / count)
      return Math.max(...levels.slice(start, end))
    })
  }

  audioFor(element) {
    return element.closest(".audio-player").nextElementSibling
  }

  seekTo(audio, seconds) {
    if (audio.duration) audio.currentTime = seconds
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
