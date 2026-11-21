import { Controller } from "@hotwired/stimulus"

const SKIP_SECONDS = 5
const BAR_PITCH = 3
const SPEEDS = [ 1, 1.2, 1.5, 2 ]

export default class extends Controller {
  static values = { playLabel: String, seekLabel: String, speedLabel: String, title: String, artist: String, artwork: String }

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
    this.seekTo(audio, this.position(audio) - SKIP_SECONDS)
  }

  forward({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, this.position(audio) + SKIP_SECONDS)
  }

  start({ currentTarget }) {
    this.seekTo(this.audioFor(currentTarget), 0)
  }

  end({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    this.seekTo(audio, this.duration(audio))
  }

  speed({ currentTarget }) {
    const audio = this.audioFor(currentTarget)
    audio.playbackRate = SPEEDS[(SPEEDS.indexOf(audio.playbackRate) + 1) % SPEEDS.length]
    currentTarget.textContent = `${audio.playbackRate}×`
  }

  started({ target: audio }) {
    audio.previousElementSibling.classList.add("audio-player--started")
    document.querySelectorAll("audio").forEach(other => other === audio || other.pause())
    if (!("mediaSession" in navigator)) return

    navigator.mediaSession.metadata = new MediaMetadata({
      title: this.titleValue,
      artist: this.artistValue,
      artwork: this.artworkValue ? [ { src: this.artworkValue } ] : []
    })
  }

  resume({ target: audio }) {
    if (!("seek" in audio.dataset)) return

    audio.currentTime = audio.dataset.seek
    delete audio.dataset.seek
  }

  render({ target: audio }) {
    const player = audio.previousElementSibling
    const duration = this.duration(audio)
    const position = this.position(audio)
    const played = duration ? position / duration : 0
    const bars = player.querySelectorAll(".audio-player__bar")
    const waveform = player.querySelector(".audio-player__waveform")
    const clock = player.querySelector(".audio-player__time")
    const total = this.format(duration)
    const elapsed = this.format(position)

    bars.forEach((bar, index) => bar.classList.toggle("audio-player__bar--played", index / bars.length < played))
    player.querySelector(".audio-player__toggle").setAttribute("aria-pressed", !audio.paused)
    const widest = total.replace(/\d/g, "0")
    clock.dataset.time = position > 0 ? elapsed : total
    if (clock.textContent !== widest) clock.textContent = widest
    waveform.setAttribute("aria-valuemax", Math.floor(duration))
    waveform.setAttribute("aria-valuenow", Math.floor(position))
    waveform.setAttribute("aria-valuetext", `${elapsed} / ${total}`)
  }

  restore({ target: audio }) {
    const player = audio.previousElementSibling
    this.resizeObserver.unobserve(player.querySelector(".audio-player__waveform"))
    player.remove()
    delete audio.dataset.action
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
    const speed = this.build("button", "audio-player__speed", { type: "button", "aria-label": this.speedLabelValue, "data-action": "audio-player#speed" })
    speed.textContent = "1×"
    const track = this.build("div", "audio-player__track")
    const tags = this.build("div", "audio-player__tags")
    tags.append(speed, clock)
    track.append(waveform, tags)
    player.append(toggle, track)
    audio.before(player)
    audio.dataset.action = [ "play", "pause", "timeupdate", "durationchange" ].map(event => `${event}->audio-player#render`).concat("play->audio-player#started", "canplay->audio-player#resume", "playing->audio-player#resume", "error->audio-player#restore").join(" ")
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

  position(audio) {
    return "seek" in audio.dataset ? Number(audio.dataset.seek) : audio.currentTime
  }

  seekTo(audio, seconds) {
    const time = Math.min(Math.max(seconds, 0), this.duration(audio))
    audio.readyState > 2 ? audio.currentTime = time : audio.dataset.seek = time
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
