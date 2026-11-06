import json
import statistics
import subprocess
import sys
import time


def cpu_seconds(value):
    return sum(float(part) * 60**i for i, part in enumerate(reversed(value.split(":"))))


pid, span, output = sys.argv[1:]
rows = []
start = time.monotonic()
for i in range(int(span) + 1):
    time.sleep(max(0, start + i - time.monotonic()))
    sampled = subprocess.check_output(["/bin/ps", "-p", pid, "-o", "rss=,time="], text=True)
    kib, cpu = sampled.split()
    rows.append({"elapsed_s": round(time.monotonic() - start, 4), "rss_kib": int(kib),
                 "cpu_s": cpu_seconds(cpu)})
cpu = 100 * (rows[-1]["cpu_s"] - rows[0]["cpu_s"]) / (rows[-1]["elapsed_s"] - rows[0]["elapsed_s"])
summary = {"samples": len(rows), "mean_cpu_percent": round(cpu, 4),
           "median_rss_kib": statistics.median(r["rss_kib"] for r in rows),
           "max_rss_kib": max(r["rss_kib"] for r in rows)}
with open(output, "w") as out:
    json.dump({"summary": summary, "samples": rows}, out, indent=2)
    out.write("\n")
print(summary)
