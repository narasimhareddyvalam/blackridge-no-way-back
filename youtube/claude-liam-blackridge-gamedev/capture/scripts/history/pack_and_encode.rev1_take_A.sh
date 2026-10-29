#!/usr/bin/env bash
# pack_and_encode.sh <prefix> <expected_frames> [sample frame indices...]
#
# 1. Packs capture/raw/frames_<prefix>/<prefix>_%05d.jpg (the rig's offline-rendered
#    frames, JPEG quality 0.95) into capture/raw/<prefix>_raw_mjpeg.mov by stream copy
#    (no re-encode) and checks that every packet is byte-identical (framemd5).
# 2. Encodes capture/<prefix>.mp4: H.264, -crf 14 -preset slow, yuv420p, native size,
#    60 fps, no audio. JPEG decodes as BT.601 full range, so the chain converts it to
#    RGB explicitly and then to BT.709 limited range, and tags the stream BT.709.
# 3. Verifies the MP4 (size, fps, frame count, tags) and compares decoded frames with the
#    source JPEGs (verify_clip.py). Only then removes the JPEG folder; the .mov raw take
#    keeps the identical JPEG data.
set -euo pipefail

CAP=/Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back/youtube/claude-liam-blackridge-gamedev/capture
prefix=$1
expected=$2
shift 2
frames="$CAP/raw/frames_$prefix"
raw="$CAP/raw/${prefix}_raw_mjpeg.mov"
mp4="$CAP/$prefix.mp4"
log="$CAP/logs/encode_$prefix.log"
work=$(mktemp -d "${TMPDIR:-/tmp}/pack_${prefix}.XXXXXX")

count=$(find "$frames" -name "${prefix}_*.jpg" | wc -l | tr -d ' ')
echo "frames on disk: $count (expected $expected)" | tee "$log"
[ "$count" -eq "$expected" ]

ffmpeg -hide_banner -loglevel error -y -framerate 60 -start_number 0 \
	-i "$frames/${prefix}_%05d.jpg" -c:v copy -an "$raw"
ffmpeg -hide_banner -loglevel error -framerate 60 -start_number 0 \
	-i "$frames/${prefix}_%05d.jpg" -c copy -f framemd5 - | grep -v '^#' | cut -d, -f5,6 > "$work/jpg.md5"
ffmpeg -hide_banner -loglevel error -i "$raw" -c copy -f framemd5 - | grep -v '^#' | cut -d, -f5,6 > "$work/mov.md5"
if cmp -s "$work/jpg.md5" "$work/mov.md5" && [ "$(wc -l < "$work/mov.md5" | tr -d ' ')" -eq "$expected" ]; then
	echo "raw take: $raw holds the $expected JPEG frames byte-identically (framemd5)" | tee -a "$log"
else
	echo "raw take: packet mismatch" | tee -a "$log"
	exit 1
fi

chain="scale=in_color_matrix=bt601:in_range=full:flags=accurate_rnd+full_chroma_int,format=rgb24"
chain="$chain,scale=out_color_matrix=bt709:out_range=tv:flags=accurate_rnd+full_chroma_int,format=yuv420p"
echo "encode: ffmpeg -i $raw -vf $chain -c:v libx264 -crf 14 -preset slow -pix_fmt yuv420p" \
	"-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -r 60 -an" \
	"-movflags +faststart $mp4" | tee -a "$log"
ffmpeg -hide_banner -loglevel error -y -i "$raw" -vf "$chain" \
	-c:v libx264 -crf 14 -preset slow -pix_fmt yuv420p \
	-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv \
	-r 60 -an -movflags +faststart "$mp4"

ffprobe -v error -select_streams v:0 -count_frames \
	-show_entries stream=codec_name,width,height,r_frame_rate,avg_frame_rate,nb_read_frames,pix_fmt,color_space,color_primaries,color_transfer,color_range \
	-show_entries format=duration -of default=nw=1 "$mp4" | tee -a "$log"
streams=$(ffprobe -v error -show_entries stream=codec_type -of csv=p=0 "$mp4" | sort | uniq | tr '\n' ' ')
echo "streams: $streams" | tee -a "$log"
[ "$streams" = "video " ]

python3 -I "$CAP/scripts/verify_clip.py" "$frames" "$prefix" "$mp4" "$expected" "$@" | tee -a "$log"

rm -rf "$work"
rm -rf "$frames"
echo "removed $frames (identical JPEG data kept in $raw)" | tee -a "$log"
