import os
import sys
from pydub import AudioSegment
from pydub.silence import split_on_silence

def clean_voice_track(input_file, output_file, silence_thresh=-40, min_silence_len=400, keep_silence=100):
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.", file=sys.stderr)
        sys.exit(1)

    sound  = AudioSegment.from_file(input_file)
    chunks = split_on_silence(
        sound,
        min_silence_len=min_silence_len,
        silence_thresh=silence_thresh,
        keep_silence=keep_silence
    )

    if not chunks:
        print("Warning: no chunks after silence removal. Copying input as-is.")
        sound.export(output_file, format="mp3")
        return

    combined = AudioSegment.empty()
    for chunk in chunks:
        combined += chunk

    combined.export(output_file, format="mp3")
    print(f"Done. {len(chunks)} chunks -> {output_file}")

if __name__ == "__main__":
    inp     = sys.argv[1] if len(sys.argv) > 1 else "raw_voice.mp3"
    out     = sys.argv[2] if len(sys.argv) > 2 else "optimized_voice.mp3"
    thresh  = int(sys.argv[3])   if len(sys.argv) > 3 else -40
    min_sil = int(sys.argv[4])   if len(sys.argv) > 4 else 400
    keep    = int(sys.argv[5])   if len(sys.argv) > 5 else 100

    clean_voice_track(inp, out, thresh, min_sil, keep)
