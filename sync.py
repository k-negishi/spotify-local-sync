#!/usr/bin/env python3
"""Music.app のローカル音源を Spotify 用ディレクトリへコピーする。"""

import csv
import filecmp
import os
import re
import shutil
import sys
from pathlib import Path
from typing import Iterator, Tuple


SOURCE = Path.home() / "Music" / "Music" / "Media.localized"
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DEST = PROJECT_DIR / "music"
TSV = SCRIPT_DIR / "sync.tsv"

AUDIO_EXTENSIONS = {".m4a", ".mp3", ".aac", ".flac", ".wav", ".aiff", ".aif", ".ogg"}
TRACK_NUMBER = re.compile(r"^[0-9]+\s+")


def audio_files(root: Path) -> Iterator[Path]:
    """root 配下の音声ファイルを、シンボリックリンクを辿らず列挙する。"""
    for directory, _, filenames in os.walk(str(root), followlinks=False):
        directory_path = Path(directory)
        for filename in filenames:
            path = directory_path / filename
            if path.is_file() and not path.is_symlink() and path.suffix.lower() in AUDIO_EXTENSIONS:
                yield path


def copy_file(source: Path, source_root: Path, destination_root: Path) -> None:
    relative = source.relative_to(source_root)
    target = destination_root / relative
    target.parent.mkdir(parents=True, exist_ok=True)

    if target.is_file() and filecmp.cmp(str(source), str(target), shallow=False):
        print("SKIP  {}".format(relative))
        return

    print("COPY  {}".format(relative))
    shutil.copy2(str(source), str(target))


def copy_directory(source_root: Path, destination_root: Path) -> None:
    for source in audio_files(source_root):
        copy_file(source, source_root, destination_root)


def normalize_track_name(path: Path) -> str:
    filename = path.name
    name = filename.rsplit(".", 1)[0] if "." in filename else filename
    return TRACK_NUMBER.sub("", name)


def copy_track(search_root: Path, destination_root: Path, wanted: str) -> None:
    found = False
    for source in audio_files(search_root):
        if normalize_track_name(source) != wanted:
            continue
        copy_file(source, search_root, destination_root)
        found = True

    if not found:
        print("WARN: track not found: {}".format(wanted))


def sync_entries(tsv: Path) -> Iterator[Tuple[str, str, str]]:
    with tsv.open("r", encoding="utf-8", newline="") as stream:
        reader = csv.reader(stream, delimiter="\t")
        for line_number, row in enumerate(reader, start=1):
            columns = (row + ["", "", ""])[:3]
            artist, album, track = columns

            if line_number == 1 and artist == "artist":
                continue
            if not artist or artist.startswith("#"):
                continue

            yield artist, album, track


def run() -> int:
    if not SOURCE.is_dir():
        print("ERROR: source not found:", file=sys.stderr)
        print(SOURCE, file=sys.stderr)
        return 1

    if not TSV.is_file():
        print("ERROR: sync.tsv not found:", file=sys.stderr)
        print(TSV, file=sys.stderr)
        return 1

    print()
    print("Spotify local sync")
    print("SOURCE: {}".format(SOURCE))
    print("DEST:   {}".format(DEST))

    for artist, album, track in sync_entries(TSV):
        artist_dir = SOURCE / artist
        if not artist_dir.is_dir():
            print("WARN: artist not found: {}".format(artist))
            continue

        print()
        print("[{}]".format(artist))

        if not album and not track:
            copy_directory(artist_dir, DEST / artist)
            continue

        if album:
            album_dir = artist_dir / album
            if not album_dir.is_dir():
                print("WARN: album not found: {} / {}".format(artist, album))
                continue

            if not track:
                copy_directory(album_dir, DEST / artist / album)
                continue

            copy_track(album_dir, DEST / artist / album, track)
            continue

        copy_track(artist_dir, DEST / artist, track)

    print()
    print("Done.")
    print()
    print("Mac Spotify local-files folder:")
    print(DEST)
    print()
    print("iPhone:")
    print("Files -> iCloud Drive -> SpotifyLocal -> music")
    print("必要な音源を「このiPhone内 -> Spotify」へコピーしてください。")
    return 0


def main() -> int:
    try:
        return run()
    except (OSError, csv.Error) as error:
        print("ERROR: {}".format(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
