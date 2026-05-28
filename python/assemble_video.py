import os
import sys
import json
try:
    from moviepy import ImageClip, AudioFileClip, concatenate_videoclips
except ImportError:
    from moviepy.editor import ImageClip, AudioFileClip, concatenate_videoclips

def with_duration(clip, duration):
    return clip.with_duration(duration) if hasattr(clip, "with_duration") else clip.set_duration(duration)

def with_audio(clip, audio):
    return clip.with_audio(audio) if hasattr(clip, "with_audio") else clip.set_audio(audio)

def render_project(project_path=".", fps=24, codec="libx264", threads=4):
    os.chdir(project_path)

    audio_file = "optimized_voice.mp3"
    index_file = "index.json"

    if not os.path.exists(audio_file):
        print(f"Error: {audio_file} not found.", file=sys.stderr); sys.exit(1)
    if not os.path.exists(index_file):
        print(f"Error: {index_file} not found.", file=sys.stderr); sys.exit(1)

    audio = AudioFileClip(audio_file)

    with open(index_file, "r") as f:
        images = json.load(f)

    # Filter to only existing files
    images = [img for img in images if os.path.exists(img)]
    if not images:
        print("Error: No valid images found in index.json.", file=sys.stderr); sys.exit(1)

    duration_per_image = audio.duration / len(images)

    clips = [
        with_duration(ImageClip(img), duration_per_image)
        for img in images
    ]

    video = with_audio(concatenate_videoclips(clips, method="compose"), audio)
    video.write_videofile(
        "master_output.mp4",
        fps=fps,
        codec=codec,
        audio_codec="aac",
        threads=threads,
        logger=None  # suppress verbose moviepy bar
    )
    print("Render complete: master_output.mp4")

if __name__ == "__main__":
    path    = sys.argv[1] if len(sys.argv) > 1 else "."
    fps     = int(sys.argv[2])   if len(sys.argv) > 2 else 24
    codec   = sys.argv[3]        if len(sys.argv) > 3 else "libx264"
    threads = int(sys.argv[4])   if len(sys.argv) > 4 else 4

    render_project(path, fps, codec, threads)
