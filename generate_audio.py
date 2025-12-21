import wave
import struct
import math
import random
import os

# Note frequencies (A4 = 440 Hz)
notes = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}

def note_to_freq(note_str):
    if note_str == '---' or not note_str:
        return 0
    if '#' in note_str:
        return 0  # Noise
    parts = note_str.split('-')
    if len(parts) == 2:
        note, octave_str = parts
        octave = int(octave_str)
        semitone = notes[note] + (octave - 4) * 12
        return 440 * 2 ** ((semitone - 9) / 12)
    return 0

def parse_famitracker_snippet(snippet):
    lines = snippet.strip().split('\n')
    track_line = None
    instruments = {}
    pattern = []
    loop_point = None
    for line in lines:
        line = line.strip()
        if line.startswith('TRACK'):
            parts = line.split(' ', 4)
            bpm = int(parts[1])
            rows_per_beat = int(parts[2])
            speed = int(parts[3])
            name = parts[4].strip('"')
            track_line = (bpm, rows_per_beat, speed, name)
        elif line.startswith('INSTRUMENTS'):
            # Parse instruments block
            pass  # For simplicity, parse later
        elif line.startswith('PATTERN'):
            # Start parsing pattern
            pass
        elif line.startswith('ROW'):
            parts = line.split(':', 1)
            row_num = parts[0].split()[1]
            data = parts[1] if len(parts) > 1 else ''
            columns = [col.strip() for col in data.split(':')]
            pattern.append((row_num, columns))
        elif line.startswith('LOOP POINT'):
            loop_point = int(line.split()[2])
    # Parse instruments
    in_instruments = False
    current_inst = None
    for line in lines:
        line = line.strip()
        if line.startswith('INSTRUMENTS {'):
            in_instruments = True
        elif line == '}':
            in_instruments = False
        elif in_instruments:
            if line.strip()[0].isdigit() and ' : ' in line:
                parts = line.split(' : ', 1)
                inst_num = int(parts[0])
                if parts[1] == '{':
                    current_inst = {}
                    instruments[inst_num] = current_inst
            elif current_inst is not None:
                parts = line.split(' ', 1)
                if len(parts) == 2:
                    key, value = parts
                    if key == 'NAME':
                        current_inst['name'] = value.strip('"')
                    elif key == 'TYPE':
                        current_inst['type'] = int(value.split()[0])
                    elif key == 'SEQ_ENABLE':
                        current_inst['seq_enable'] = [int(x) for x in value.split() if x.isdigit()]
                    elif key == 'SEQ':
                        seq_value = value.split(' : ')[0]
                        current_inst['seq'] = [int(x) for x in seq_value.split() if x.isdigit()]
                    elif key == 'VIBRATO':
                        current_inst['vibrato'] = [int(x) for x in value.split() if x.isdigit()]
    return track_line, instruments, pattern, loop_point

def generate_waveform(wave_type, freq, duration, sample_rate, duty_cycle=0.5, volume=1.0):
    num_samples = int(duration * sample_rate)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        if wave_type == 0:  # Square
            cycle = (t * freq) % 1
            sample = 1.0 if cycle < duty_cycle else -1.0
        elif wave_type == 2:  # Triangle
            cycle = (t * freq) % 1
            sample = 2 * abs(2 * cycle - 1) - 1
        elif wave_type == 3:  # Noise
            sample = random.uniform(-1, 1)
        else:
            sample = 0
        samples.append(sample * volume)
    return samples

def apply_envelope(samples, envelope, sample_rate):
    if not envelope:
        return samples
    env_len = len(envelope)
    if env_len == 0:
        return samples
    num_samples = len(samples)
    step = num_samples / env_len
    for i in range(num_samples):
        env_index = int(i / step)
        if env_index >= env_len:
            env_index = env_len - 1
        vol = envelope[env_index] / 15.0  # Assuming 0-15
        samples[i] *= vol
    return samples

def generate_audio_for_sound(sound_name, snippet, is_music=False):
    track_line, instruments, pattern, loop_point = parse_famitracker_snippet(snippet)
    if not track_line:
        return []
    bpm, rows_per_beat, speed, name = track_line
    time_per_row = 60.0 / (bpm * 4)  # Approximate
    if is_music:
        num_loops = 4
    else:
        num_loops = 1
    sample_rate = 44100
    channels = len(pattern[0][1]) if pattern else 1
    audio = [[] for _ in range(channels)]
    for loop in range(num_loops):
        for row_num, columns in pattern:
            for col_idx, col_data in enumerate(columns):
                parts = col_data.split()
                if len(parts) < 4:
                    continue
                note_str = parts[0]
                inst_num = int(parts[1]) if parts[1] != '..' else 0
                vol = int(parts[3]) if parts[3] != '..' else 15
                if inst_num not in instruments:
                    continue
                inst = instruments[inst_num]
                wave_type = inst.get('type', 0)
                envelope = inst.get('seq', [])
                freq = 0
                freq = note_to_freq(note_str)
                if freq > 0:
                    samples = generate_waveform(wave_type, freq, time_per_row, sample_rate, volume=vol/15.0)
                    samples = apply_envelope(samples, envelope, sample_rate)
                    audio[col_idx].extend(samples)
                else:
                    # Rest
                    silence = [0] * int(time_per_row * sample_rate)
                    audio[col_idx].extend(silence)
    # Mix channels
    max_len = max(len(ch) for ch in audio)
    mixed = []
    for i in range(max_len):
        sample = sum(ch[i] if i < len(ch) else 0 for ch in audio) / channels
        mixed.append(int(sample * 32767))
    return mixed

def main():
    with open('resources/audio/sounds.famitracker', 'r') as f:
        content = f.read()
    sounds = content.split('\n# ')
    for sound_block in sounds:
        if not sound_block.strip():
            continue
        lines = sound_block.strip().split('\n')
        sound_name = lines[0].lstrip('# ').strip()
        # Find the Famitracker snippet
        in_snippet = False
        snippet = []
        for line in lines:
            if line.strip().startswith('```'):
                in_snippet = not in_snippet
            elif in_snippet:
                snippet.append(line)
        if snippet:
            snippet = '\n'.join(snippet)
            is_music = 'music' in sound_name.lower()
            audio = generate_audio_for_sound(sound_name, snippet, is_music)
            if audio:
                filename = f'resources/audio/{sound_name}.wav'
                with wave.open(filename, 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)
                    wav_file.setframerate(44100)
                    wav_file.writeframes(struct.pack('<' + 'h' * len(audio), *audio))
                print(f'Generated {filename}')

if __name__ == '__main__':
    main()