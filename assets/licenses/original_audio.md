# Original Brackenward audio

`tools/author_audio.py` is the editable synthesizer and score source. The three
90-second pieces use original harmonic plucks, soft woodwind-like sine tones and
synthesized hand percussion, with no sampled commercial instrument library.
The thirty-bar, 80 BPM scores, MIDI pitches, chord progressions, synthesis tool
versions and measured exported audio bounds are retained in `data/audio_score.json`.
These are Original project assets, with no blanket CC0 license assigned.

Day, night and tension share harmonic material so their transitions can blend.
Note release tails wrap around the exact 90-second boundary. Rain, river, wind
and fire use original seeded periodic filtered noise and sparse crackles. Warning
is a soft two-note chime, critical is three low bell strikes, and opportunity is
one upward pluck. Loops have no fade-to-silence gap. Exports are stereo 22,050 Hz
Ogg Vorbis; decoded duration, finite samples, RMS, peak and boundary step are
checked when authoring. Human listening and physical-phone audio remain separate
release gates. Rebuild with NumPy, libsndfile/Vorbis and FFmpeg; no Python ships at runtime.
