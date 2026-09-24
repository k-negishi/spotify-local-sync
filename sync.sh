#!/bin/bash

set -u

SOURCE="$HOME/Music/Music/Media.localized"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DEST="$PROJECT_DIR/music"
TSV="$SCRIPT_DIR/sync.tsv"

AUDIO_EXTENSIONS="m4a mp3 aac flac wav aiff aif ogg"

if [ ! -d "$SOURCE" ]; then
  echo "ERROR: source not found:"
  echo "$SOURCE"
  exit 1
fi

if [ ! -f "$TSV" ]; then
  echo "ERROR: sync.tsv not found:"
  echo "$TSV"
  exit 1
fi

is_audio() {
  local ext="${1##*.}"
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')

  for allowed in $AUDIO_EXTENSIONS; do
    if [ "$ext" = "$allowed" ]; then
      return 0
    fi
  done

  return 1
}

copy_directory() {
  local src="$1"
  local dst="$2"

  find "$src" -type f -print0 |
  while IFS= read -r -d '' file; do
    if ! is_audio "$file"; then
      continue
    fi

    relative="${file#$src/}"
    target="$dst/$relative"

    mkdir -p "$(dirname "$target")"

    if [ -f "$target" ] && cmp -s "$file" "$target"; then
      echo "SKIP  $relative"
    else
      echo "COPY  $relative"
      cp -p "$file" "$target"
    fi
  done
}

normalize_track_name() {
  local name="$1"

  name="${name##*/}"
  name="${name%.*}"

  # "07 東京ループ" -> "東京ループ"
  name=$(printf '%s' "$name" | sed -E 's/^[0-9]+[[:space:]]+//')

  printf '%s' "$name"
}

copy_track() {
  local search_root="$1"
  local dest_root="$2"
  local wanted="$3"

  local found=0

  while IFS= read -r -d '' file; do
    if ! is_audio "$file"; then
      continue
    fi

    actual=$(normalize_track_name "$file")

    if [ "$actual" = "$wanted" ]; then
      relative="${file#$search_root/}"
      target="$dest_root/$relative"

      mkdir -p "$(dirname "$target")"

      if [ -f "$target" ] && cmp -s "$file" "$target"; then
        echo "SKIP  $relative"
      else
        echo "COPY  $relative"
        cp -p "$file" "$target"
      fi

      found=1
    fi
  done < <(find "$search_root" -type f -print0)

  if [ "$found" -eq 0 ]; then
    echo "WARN: track not found: $wanted"
  fi
}

echo
echo "Spotify local sync"
echo "SOURCE: $SOURCE"
echo "DEST:   $DEST"
echo

first_line=1

while IFS=$'\t' read -r artist album track extra || [ -n "${artist:-}" ]; do
  artist="${artist%$'\r'}"
  album="${album%$'\r'}"
  track="${track%$'\r'}"

  if [ "$first_line" -eq 1 ]; then
    first_line=0
    if [ "$artist" = "artist" ]; then
      continue
    fi
  fi

  if [ -z "$artist" ]; then
    continue
  fi

  case "$artist" in
    \#*)
      continue
      ;;
  esac

  artist_dir="$SOURCE/$artist"

  if [ ! -d "$artist_dir" ]; then
    echo "WARN: artist not found: $artist"
    continue
  fi

  echo
  echo "[$artist]"

  # artistのみ -> アーティスト全体
  if [ -z "$album" ] && [ -z "$track" ]; then
    copy_directory "$artist_dir" "$DEST/$artist"
    continue
  fi

  # album指定あり
  if [ -n "$album" ]; then
    album_dir="$artist_dir/$album"

    if [ ! -d "$album_dir" ]; then
      echo "WARN: album not found: $artist / $album"
      continue
    fi

    # artist + album -> アルバム全体
    if [ -z "$track" ]; then
      copy_directory "$album_dir" "$DEST/$artist/$album"
      continue
    fi

    # artist + album + track -> その曲
    copy_track "$album_dir" "$DEST/$artist/$album" "$track"
    continue
  fi

  # artist + track -> アーティスト配下の全アルバムから検索
  copy_track "$artist_dir" "$DEST/$artist" "$track"

done < "$TSV"

echo
echo "Done."
echo
echo "Mac Spotify local-files folder:"
echo "$DEST"
echo
echo "iPhone:"
echo "Files -> iCloud Drive -> SpotifyLocal -> music"
echo "必要な音源を「このiPhone内 -> Spotify」へコピーしてください。"
