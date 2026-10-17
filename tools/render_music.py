"""Render an opening-theme arrangement from the supplied score images.

Source, transcription limits, and rights status: docs/MUSIC.md.
Run with Python 3; no packages or network access are needed.
"""

from array import array
from functools import lru_cache
from math import exp, pi, sin
from pathlib import Path
import sys
import wave


SAMPLE_RATE = 22050
BPM = 100
SECONDS_PER_BEAT = 60 / BPM
INTRO_BEATS = 4
BAR_BEATS = 4
OUTPUT = Path(__file__).resolve().parents[1] / "assets/audio/esfahan_opening.wav"

MELODY = [
    "C5/8 C5/8 C5/8 C5/8 C5/8 C5/8 Eb5/16 D5/16 C5/8",
    "C5/8 C5/8 C5/8 C5/8 C5/8 C5/8 B4/16 Ab4/16 G4/8",
    "C5/8 C5/8 C5/8 C5/8 C5/8 C5/8 Eb5/16 D5/16 C5/8",
    "D5/16 C5/16 C5/16 B4/16 B4/16 Ab4/16 Ab4/16 G4/16 C5/8 C5/8 C5/4",
    "G4/8 G4/8 G4/8 G4/8 G4/8 G4/8 B4/16 Ab4/16 G4/8",
    "G4/8 G4/8 G4/8 G4/8 G4/8 G4/8 F4/16 Eb4/16 D4/16 C4/16",
    "G4/8 G4/8 G4/8 G4/8 G4/8 G4/8 B4/16 Ab4/16 G4/8",
    "G4/16 Ab4/16 G4/16 F4/16 Eb4/16 F4/16 Eb4/16 D4/16 C4/16 D4/16 Eb4/16 F4/16 G4/8 G4/8",
    "G5/16 Ab5/16 G5/16 Ab5/16 G5/16 Ab5/16 G5/16 Ab5/16 G5/16 Ab5/16 G5/16 F5/16 Eb5/16 F5/16 Eb5/16 D5/16",
    "F5/16 G5/16 F5/16 G5/16 F5/16 G5/16 F5/16 G5/16 F5/16 G5/16 F5/16 Eb5/16 D5/16 Eb5/16 D5/16 C5/16",
    "F5/16 Eb5/16 Eb5/16 D5/16 Eb5/16 D5/16 D5/16 C5/16 D5/16 C5/16 C5/16 B4/16 C5/4",
    "F5/16 Eb5/16 Eb5/16 D5/16 Eb5/16 D5/16 D5/16 C5/16 D5/16 C5/16 C5/16 B4/16 C5/4",
    "C5/16 B4/16 C5/8 C5/16 B4/16 C5/8 C5/16 B4/16 C5/8 C5/16 B4/16 C5/8",
    "C5/16 B4/16 C5/16 Eb5/16 D5/16 Eb5/16 D5/16 C5/16 B4/16 C5/16 B4/16 Ab4/16 G4/4",
    "G4/16 F#4/16 G4/16 Ab4/16 Bb4/16 Ab4/16 G4/8 Gb4/16 F4/16 Gb4/16 G4/16 Ab4/16 G4/16 F4/8",
    "F4/16 Eb4/16 F4/16 G4/16 Ab4/16 G4/16 F4/16 Eb4/16 F4/16 Eb4/16 G4/16 Eb4/16 Bb4/8 R/8",
]

BASS = [
    "C2/8 C3/8 G3/8 C4/8 Eb4/8 C4/8 G3/4",
    "C2/8 C3/8 G3/8 C4/8 Eb4/8 C4/8 G3/4",
    "C2/8 C3/8 G3/8 C4/8 Eb4/8 C4/8 G3/4",
    "B3/4 C4/4 D4/4 Eb4/4",
    "C2/8 C3/8 Eb3/8 G3/8 Eb3/8 C3/8 G2/4",
    "C2/8 C3/8 Eb3/8 G3/8 Eb3/8 C3/8 Ab2/4",
    "C2/8 C3/8 Eb3/8 G3/8 Eb3/8 C3/8 G2/4",
    "G2/8 C3/8 Eb3/8 G3/8 Eb3/8 C3/8 G2/4",
    "G3/8 C4/8 Eb4/8 G4/8 D4/8 F4/8 Ab4/8 F4/8",
    "G3/8 B3/8 D4/8 F4/8 C4/8 Eb4/8 G4/8 Eb4/8",
    "B3/4 C4/4 D4/4 Eb4/4",
    "B3/4 C4/4 D4/4 Eb4/4",
    "C3/8 G3/8 C4/8 G3/8 C3/8 G3/8 C4/8 G3/8",
    "C3/8 Eb3/8 G3/8 G3/8 G2/8 D3/8 G3/4",
    "C3/8 Ab3/8 F3/8 Ab3/8 C3/8 G3/8 Eb3/8 G3/8",
    "F2/8 A2/8 C3/8 F3/8 F2/8 Bb2/8 D3/8 F3/8",
]


def parse_bar(text):
    events = []
    position = 0.0
    for token in text.split():
        pitch, denominator = token.split("/")
        duration = 4 / int(denominator)
        events.append((position, pitch, duration))
        position += duration
    if abs(position - BAR_BEATS) > 0.00001:
        raise ValueError(f"Bar has {position} beats, expected {BAR_BEATS}: {text}")
    return events


def frequency(pitch):
    offsets = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    accidental = 1 if "#" in pitch else -1 if "b" in pitch else 0
    midi_note = (int(pitch[-1]) + 1) * 12 + offsets[pitch[0]] + accidental
    return 440 * 2 ** ((midi_note - 69) / 12)


@lru_cache(maxsize=None)
def voice(pitch, duration, accompaniment):
    fundamental = frequency(pitch)
    sustain = duration * SECONDS_PER_BEAT
    length = int((sustain + 0.45) * SAMPLE_RATE)
    samples = array("f")
    harmonics = (1.0, 0.32, 0.18, 0.08) if accompaniment else (1.0, 0.45, 0.22, 0.11)
    for frame in range(length):
        seconds = frame / SAMPLE_RATE
        attack = min(1.0, seconds / 0.004)
        release = exp(-max(0.0, seconds - sustain * 0.78) / 0.085)
        tone = 0.0
        for overtone, amplitude in enumerate(harmonics, 1):
            if fundamental * overtone < SAMPLE_RATE / 2:
                decay = exp(-seconds * (2.8 + overtone * 1.3))
                tone += amplitude * decay * sin(2 * pi * fundamental * overtone * seconds)
        samples.append(tone * attack * release)
    return samples


def render():
    if len(MELODY) != 16 or len(BASS) != 16:
        raise ValueError("Both staves must contain 16 bars")
    melody_bars = [parse_bar(bar) for bar in MELODY]
    bass_bars = [parse_bar(bar) for bar in BASS]
    intro_frames = round(INTRO_BEATS * SECONDS_PER_BEAT * SAMPLE_RATE)
    loop_frames = round(16 * BAR_BEATS * SECONDS_PER_BEAT * SAMPLE_RATE)
    frame_count = intro_frames + loop_frames
    channels = [array("f", [0]) * frame_count, array("f", [0]) * frame_count]

    def add_note(pitch, start_beat, duration, gain, accompaniment=False, wrap=False):
        if pitch == "R":
            return
        start_frame = round(start_beat * SECONDS_PER_BEAT * SAMPLE_RATE)
        balance = (0.65, 0.92) if accompaniment else (0.95, 0.72)
        for offset, value in enumerate(voice(pitch, duration, accompaniment)):
            frame = start_frame + offset
            if frame >= frame_count:
                if not wrap:
                    break
                frame = intro_frames + (frame - frame_count) % loop_frames
            channels[0][frame] += value * gain * balance[0]
            channels[1][frame] += value * gain * balance[1]
            echo_frame = frame + round(0.11 * SAMPLE_RATE)
            if echo_frame >= frame_count and wrap:
                echo_frame = intro_frames + (echo_frame - frame_count) % loop_frames
            if echo_frame < frame_count:
                channels[0][echo_frame] += value * gain * 0.10 * balance[1]
                channels[1][echo_frame] += value * gain * 0.10 * balance[0]

    for index, pitch in enumerate(["C4", "G4", "C5", "Eb5", "G5", "Eb5", "D5", "B4"]):
        add_note(pitch, index * 0.5, 0.5, 0.11 + index * 0.008)
    for pitch in ["C2", "G2", "C3"]:
        add_note(pitch, 0, 3.5, 0.12, True)
    for bar_index, (melody, bass) in enumerate(zip(melody_bars, bass_bars)):
        for position, pitch, duration in melody:
            accent = 1.12 if position % 1 == 0 else 1.0
            add_note(pitch, INTRO_BEATS + bar_index * BAR_BEATS + position, duration, 0.22 * accent, wrap=True)
        for position, pitch, duration in bass:
            add_note(pitch, INTRO_BEATS + bar_index * BAR_BEATS + position, duration, 0.15, True, True)
        if bar_index in [3, 10, 11]:
            for position in [0, 2]:
                add_note("G3", INTRO_BEATS + bar_index * BAR_BEATS + position, 2, 0.08, True, True)

    peak = max(max(abs(value) for value in channel) for channel in channels)
    scale = min(1.0, 0.78 / peak)
    pcm = array("h")
    for frame in range(frame_count):
        for channel in channels:
            pcm.append(round(channel[frame] * scale * 32767))
    if sys.byteorder != "little":
        pcm.byteswap()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm.tobytes())
    print(f"Rendered {OUTPUT.name}: {frame_count / SAMPLE_RATE:.1f}s, intro {intro_frames} frames, loop {loop_frames} frames, peak {peak * scale:.3f}")


if __name__ == "__main__":
    render()
