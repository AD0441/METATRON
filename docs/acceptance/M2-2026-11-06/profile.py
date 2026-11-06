#!/usr/bin/env python3
"""Measure the release CLI on the synthetic M1 corpus. Usage: profile.py CLI FIXTURES OUTPUT."""
import hashlib
import json
import re
import shutil
import statistics
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import unquote, urlsplit
from uuid import uuid4


def digest(path):
    hashed = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            hashed.update(block)
    return hashed.hexdigest()


def verify(destination, output_count, extension):
    receipts = list(destination.glob("metatron-*.json"))
    if len(receipts) != 1:
        raise RuntimeError("Expected one receipt per CLI invocation")
    entries = json.loads(receipts[0].read_text())
    if len(entries) != output_count or len(list(destination.iterdir())) != output_count + 1:
        raise RuntimeError("Unexpected published file count")
    for entry in entries:
        path = Path(unquote(urlsplit(entry["url"]).path))
        if (path.parent.resolve() != destination.resolve() or path.suffix != extension
                or path.stat().st_size != entry["bytes"] or digest(path) != entry["digest"]):
            raise RuntimeError(f"Receipt does not match {path.name}")


def measure(cli, destination, args, count, extension):
    started = time.perf_counter()
    result = subprocess.run(["/usr/bin/time", "-l", str(cli), *map(str, args), "-o", str(destination)],
                            capture_output=True, text=True, check=True)
    wall = time.perf_counter() - started
    match = re.search(r"^\s*(\d+)\s+maximum resident set size", result.stderr, re.MULTILINE)
    if match is None:
        raise RuntimeError("macOS time -l did not report peak RSS")
    verify(destination, count, extension)
    return {"wall_s": round(wall, 4), "peak_rss_bytes": int(match[1]),
            "outputs_verified": count, "receipts_verified": 1}


def main(cli, fixtures, root):
    root.mkdir()
    input_dir = root / "input"
    input_dir.mkdir()
    for name in ("imagen.png", "texto.pdf", "escaneado.pdf", "voz-larga.wav"):
        shutil.copyfile(fixtures / name, input_dir / name)
    images = [input_dir / f"imagen-{i}.png" for i in range(1, 6)]
    for path in images:
        shutil.copyfile(input_dir / "imagen.png", path)
    originals = {path.name: digest(path) for path in sorted(input_dir.iterdir())}
    recipe = root / "jpg.json"
    recipe.write_text(json.dumps({
        "id": str(uuid4()), "name": "M2 PNG a JPG", "suffix": "-m2",
        "quality": 0.85, "preserveMetadata": True,
        "steps": [{"id": str(uuid4()), "action": "convert.jpg", "number": 1920, "text": ""}],
    }))
    cases = {
        "5_png_to_jpg": (["run", *images, "--recipe", recipe], 5, ".jpg"),
        "text_pdf_to_md": (["convert", input_dir / "texto.pdf", "--to", "md"], 1, ".md"),
        "scanned_pdf_to_md": (["convert", input_dir / "escaneado.pdf", "--to", "md"], 1, ".md"),
        "long_audio_to_txt": (["transcribe", input_dir / "voz-larga.wav", "--locale", "es-CL"], 1, ".txt"),
    }
    rows = {}
    for case, (args, count, extension) in cases.items():
        runs = []
        for iteration in range(1, 4):
            runs.append(measure(cli, root / f"{case}-{iteration}", args, count, extension))
            print(case, iteration, runs[-1], flush=True)
        rows[case] = {"runs": runs,
                      "median_wall_s": statistics.median(run["wall_s"] for run in runs),
                      "max_peak_rss_bytes": max(run["peak_rss_bytes"] for run in runs)}
    if originals != {path.name: digest(path) for path in sorted(input_dir.iterdir())}:
        raise RuntimeError("Input hashes changed")
    (root / "results.json").write_text(json.dumps({"cli_sha256": digest(cli),
                                                 "original_sha256": originals,
                                                 "cases": rows}, indent=2) + "\n")


if __name__ == "__main__":
    main(*(Path(arg).resolve() for arg in sys.argv[1:]))
