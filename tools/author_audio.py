#!/usr/bin/env python3
"""Original Brackenward score and sound synthesis; no sampled instrument library.

Authoring dependencies: Python 3, NumPy, libsndfile/Vorbis and FFmpeg. The game ships
only the reviewed Ogg exports. Seeded authoring noise never enters simulation.
"""
from pathlib import Path
import hashlib
import json
import ctypes
import ctypes.util
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
SECONDS = 90
BPM = 80
BEAT = 60 / BPM
RNG = np.random.default_rng(730149)


class SoundInfo(ctypes.Structure):
    _fields_ = [("frames", ctypes.c_int64), ("samplerate", ctypes.c_int), ("channels", ctypes.c_int),
                ("format", ctypes.c_int), ("sections", ctypes.c_int), ("seekable", ctypes.c_int)]


SOUND_LIBRARY = ctypes.util.find_library("sndfile")
if not SOUND_LIBRARY: raise SystemExit("Authoring needs libsndfile with Vorbis encoding support")
SOUND = ctypes.CDLL(SOUND_LIBRARY)
SOUND.sf_open.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(SoundInfo)]
SOUND.sf_open.restype = ctypes.c_void_p
SOUND.sf_writef_double.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_double), ctypes.c_int64]
SOUND.sf_writef_double.restype = ctypes.c_int64
SOUND.sf_command.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p, ctypes.c_int]
SOUND.sf_close.argtypes = [ctypes.c_void_p]
SOUND.sf_close.restype = ctypes.c_int
SOUND.sf_strerror.argtypes = [ctypes.c_void_p]
SOUND.sf_strerror.restype = ctypes.c_char_p
SOUND.sf_version_string.restype = ctypes.c_char_p
CHORDS = {"D": [50, 54, 57], "G": [43, 47, 50], "Bm": [47, 50, 54],
          "A": [45, 49, 52], "Em": [40, 43, 47]}
PROGRESSIONS = {
    "day": ["D", "G", "Bm", "A", "D", "Em", "G", "A", "Em", "A"],
    "night": ["D", "Bm", "G", "A", "D", "G", "Em", "A", "G", "A"],
    "tension": ["Bm", "Bm", "Em", "Em", "G", "G", "Em", "A", "Bm", "A"],
}
MELODY = [74, 76, 78, 81, 78, 76, 74, 71, 69, 71, 74, 76, 78, 76, 71, 69,
          74, 78, 81, 83, 81, 78, 76, 74, 71, 74, 76, 78, 76, 73]


def tone(midi, duration, instrument="pluck", rise=False):
    t = np.arange(round(duration * RATE)) / RATE
    frequency = 440 * 2 ** ((midi - 69) / 12)
    phase = 2 * np.pi * frequency * (t - (0.10 * (1 - np.exp(-t * 12)) / 12 if rise else 0))
    if instrument == "woodwind":
        phase += 0.025 * np.sin(2 * np.pi * 5.1 * t)
        sound = np.sin(phase) + 0.18 * np.sin(phase * 2) + 0.07 * np.sin(phase * 3)
        envelope = np.minimum(t / 0.09, 1) * np.minimum((duration - t) / 0.22, 1)
    elif instrument == "bell":
        sound = (np.sin(phase) * np.exp(-t * 1.8) + 0.35 * np.sin(phase * 2.01) * np.exp(-t * 2.6)
                 + 0.12 * np.sin(phase * 4.12) * np.exp(-t * 5.0))
        envelope = np.minimum(t / 0.004, 1) * np.minimum((duration - t) / 0.08, 1)
    else:
        sound = (np.sin(phase) + 0.34 * np.sin(phase * 2) * np.exp(-t * 4)
                 + 0.16 * np.sin(phase * 3) * np.exp(-t * 8) + 0.08 * np.sin(phase * 5) * np.exp(-t * 12))
        envelope = np.minimum(t / 0.003, 1) * np.exp(-t * 2.5) * np.minimum((duration - t) / 0.04, 1)
    return sound * np.maximum(envelope, 0)


def add(buffer, sound, at, gain, pan=0):
    # Circular placement preserves release tails across the exact loop boundary.
    indices = (round(at * RATE) + np.arange(len(sound))) % len(buffer)
    buffer[indices, 0] += sound * gain * np.sqrt((1 - pan) / 2)
    buffer[indices, 1] += sound * gain * np.sqrt((1 + pan) / 2)


def percussion(duration=0.22):
    t = np.arange(round(duration * RATE)) / RATE
    noise = RNG.normal(0, 0.12, len(t))
    membrane = np.sin(2 * np.pi * (84 * t + 2 * (1 - np.exp(-t * 25))))
    return (membrane * 0.7 + noise) * np.minimum(t / 0.003, 1) * np.exp(-t * 25)


def music(theme):
    result = np.zeros((RATE * SECONDS, 2), dtype=np.float64)
    progression = PROGRESSIONS[theme]
    for bar in range(30):
        at = bar * BEAT * 4
        chord = CHORDS[progression[bar % 10]]
        density = 8 if theme in ("day", "tension") else 4
        for note in range(density):
            pitch = chord[note % 3] + 12 + (12 if note % 4 == 3 else 0)
            gain = 0.15 if theme == "night" else 0.19
            add(result, tone(pitch, 2.4), at + note * BEAT * 4 / density, gain, (-0.35, 0.25, 0.05)[note % 3])
        # The melody varies independently from the arpeggios but resolves to D.
        if bar % (3 if theme == "night" else 2) == 0:
            pitch = MELODY[bar] - (12 if theme == "night" else 0)
            add(result, tone(pitch, BEAT * (3.3 if theme == "night" else 2.2), "woodwind"),
                at + BEAT * 0.5, 0.10 if theme != "tension" else 0.07, 0.15)
        add(result, tone(chord[0] - (12 if chord[0] > 45 else 0), 2.8), at, 0.13, -0.1)
        if theme == "tension" or (theme == "day" and bar % 2 == 1):
            for beat in ([0, 2, 3.5] if theme == "tension" else [0, 2]):
                add(result, percussion(), at + beat * BEAT, 0.11 if beat == 0 else 0.06, -0.2 if beat == 0 else 0.3)
    return normalize(result, 0.52)


def periodic_noise(seconds, low, high, seed):
    count = round(seconds * RATE)
    rng = np.random.default_rng(seed)
    frequency = np.fft.rfftfreq(count, 1 / RATE)
    magnitude = np.maximum(frequency, 20) ** -0.45
    magnitude *= (1 - np.exp(-(frequency / low) ** 4)) * np.exp(-(frequency / high) ** 4)
    spectrum = (rng.normal(size=len(frequency)) + 1j * rng.normal(size=len(frequency))) * magnitude
    spectrum[0] = 0
    sound = np.fft.irfft(spectrum, n=count)
    return sound / np.std(sound)


def ambient(kind):
    seconds = 12
    t = np.arange(RATE * seconds) / RATE
    result = np.zeros((len(t), 2))
    bands = {"rain": (500, 7200), "river": (70, 4200), "wind": (35, 1100), "fire": (140, 5400)}
    low, high = bands[kind]
    for channel in range(2):
        noise = periodic_noise(seconds, low, high, 9100 + list(bands).index(kind) * 2 + channel)
        envelope = 0.65 + 0.12 * np.sin(2 * np.pi * t / 6 + channel * 0.3)
        if kind == "wind": envelope = 0.5 + 0.2 * np.cos(2 * np.pi * t / 12) + 0.15 * np.sin(2 * np.pi * t / 4)
        if kind == "river": envelope += 0.10 * np.sin(2 * np.pi * t * 2)
        result[:, channel] = noise * envelope
    if kind == "fire":
        for moment in [0.7, 2.1, 3.6, 4.7, 6.4, 7.0, 9.2, 10.8]:
            crackle = RNG.normal(0, 0.22, round(RATE * 0.045)) * np.exp(-np.arange(round(RATE * 0.045)) / (RATE * 0.007))
            add(result, crackle, moment, 0.65, (-0.35 if int(moment) % 2 else 0.35))
    return normalize(result, 0.33)


def normalize(sound, peak):
    sound = sound - sound.mean(axis=0)
    return sound * peak / np.max(np.abs(sound))


def signal(kind):
    result = np.zeros((RATE * {"warning": 2, "critical": 3, "opportunity": 1}[kind], 2))
    if kind == "warning":
        for at, note in [(0, 74), (0.22, 78)]: add(result, tone(note, 1.5, "bell"), at, 0.28)
    elif kind == "critical":
        for at, note in [(0, 50), (0.48, 50), (0.96, 50)]: add(result, tone(note, 1.8, "bell"), at, 0.31)
    else:
        add(result, tone(74, 0.85, rise=True), 0, 0.30)
    return normalize(result, 0.50)


def export(sound, destination, loop):
    destination.parent.mkdir(parents=True, exist_ok=True)
    info = SoundInfo(0, RATE, 2, 0x200000 | 0x0060, 0, 0)  # SF_FORMAT_OGG | SF_FORMAT_VORBIS
    handle = SOUND.sf_open(str(destination).encode(), 0x20, ctypes.byref(info))  # SFM_WRITE
    if not handle: raise RuntimeError(SOUND.sf_strerror(None).decode())
    quality = ctypes.c_double(0.4)
    try:
        SOUND.sf_command(handle, 0x1300, ctypes.byref(quality), ctypes.sizeof(quality))  # SFC_SET_VBR_ENCODING_QUALITY
        contiguous = np.ascontiguousarray(sound, dtype=np.float64)
        written = SOUND.sf_writef_double(handle, contiguous.ctypes.data_as(ctypes.POINTER(ctypes.c_double)), len(sound))
        if written != len(sound): raise RuntimeError(SOUND.sf_strerror(handle).decode())
    finally:
        closed = SOUND.sf_close(handle)
    if closed: raise RuntimeError("Vorbis file did not close cleanly")
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(destination), "-f", "f32le", "-acodec", "pcm_f32le", "-"])
    decoded = np.frombuffer(raw, dtype="<f4").reshape(-1, 2)
    probe = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=duration", "-of", "json", str(destination)]))
    stats = {"seconds": float(probe["streams"][0]["duration"]), "decoded_seconds": len(decoded) / RATE,
             "decoded_trim_frames": len(sound) - len(decoded), "sample_rate": RATE, "channels": 2,
             "peak": float(np.max(np.abs(decoded))), "rms": float(np.sqrt(np.mean(decoded ** 2))),
             "loop": loop, "boundary_step": float(np.max(np.abs(decoded[0] - decoded[-1]))),
             "maximum_sample_step": float(np.max(np.abs(np.diff(decoded, axis=0)))),
             "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()}
    assert np.all(np.isfinite(decoded)) and 0.003 < stats["rms"] < 0.4 and stats["peak"] < 0.95
    assert abs(stats["seconds"] - len(sound) / RATE) < 1 / RATE
    assert abs(stats["decoded_seconds"] - len(sound) / RATE) < (0.01 if loop else 0.02)
    if loop: assert stats["boundary_step"] < max(0.04, stats["maximum_sample_step"] * 0.85)
    return stats


def main():
    manifest_path = ROOT / "assets/licenses/manifest.json"
    manifest = json.loads(manifest_path.read_text())
    names = ["music_" + key for key in PROGRESSIONS] + ["ambient_" + key for key in ("rain", "river", "wind", "fire")] + ["cue_" + key for key in ("warning", "critical", "opportunity")]
    manifest = [asset for asset in manifest if asset["id"] not in names]
    report = {"author": "Brackenward project", "rate": RATE, "bpm": BPM, "bars": 30,
              "music_seconds": SECONDS, "chords_midi": CHORDS, "progressions": PROGRESSIONS,
              "melody_midi": MELODY, "numpy": np.__version__, "libsndfile": SOUND.sf_version_string().decode(),
              "ffmpeg": subprocess.check_output(["ffmpeg", "-version"], text=True).splitlines()[0], "assets": {}}
    for ident in names:
        group, name = ident.split("_", 1)
        sound = music(name) if group == "music" else (ambient(name) if group == "ambient" else signal(name))
        path = ROOT / "assets/exported/audio" / (ident + ".ogg")
        stats = export(sound, path, group != "cue")
        report["assets"][ident] = stats
        manifest.append({"id": ident, "path": str(path.relative_to(ROOT)), "source": "tools/author_audio.py",
                         "author": "Brackenward project", "license": "Original project asset",
                         "sha256": stats["sha256"], "edited": False, "evidence": "assets/licenses/original_audio.md"})
        print(ident, f"{stats['seconds']:.3f}s", f"peak {stats['peak']:.3f}", flush=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    (ROOT / "data/audio_score.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
