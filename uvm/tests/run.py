import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path)
args = parser.parse_args()
build = (args.output or Path(tempfile.mkdtemp(prefix="ip-framework-"))).resolve()
build.mkdir(parents=True, exist_ok=True)
uvm = Path(__file__).resolve().parents[1]
simv = build / "simv"
command = [
    "vcs",
    "-full64",
    "-sverilog",
    "-timescale=1ns/1ps",
    *shlex.split(os.environ["VCS_UVM_ARGS"]),
    f"+incdir+{uvm}/src/ip",
    f"+incdir+{uvm}/src/protocol/axis",
    str(uvm / "src/ip/package.sv"),
    str(uvm / "src/protocol/axis/interface.sv"),
    str(uvm / "src/protocol/axis/package.sv"),
    str(uvm / "tests/framework_tb.sv"),
    "-top",
    "framework_tb",
    "-o",
    str(simv),
]
with (build / "compile.log").open("w") as log:
    subprocess.run(command, cwd=build, stdout=log, stderr=subprocess.STDOUT, check=True)
loader = subprocess.check_output(
    ["patchelf", "--print-interpreter", str(simv)], text=True
).strip()
library_path = subprocess.check_output(
    ["patchelf", "--print-rpath", str(simv)], text=True
).strip()
cases = [
    ("pair", "scoreboard_test", 0, 0, None),
    ("reset", "scoreboard_test", 0, 0, None),
    ("missing", "scoreboard_test", 1, 0, "Unmatched transactions: expected=1 actual=0"),
    ("extra", "scoreboard_test", 1, 0, "Unmatched transactions: expected=0 actual=1"),
    ("mismatch", "scoreboard_test", 0, 1, "[IP_SCOREBOARD]"),
    ("unknown", "scoreboard_test", 0, 1, "[IP_SCOREBOARD]"),
    ("timeout", "scoreboard_test", 0, 1, "[IP_TIMEOUT]"),
    ("axis64", "axis64_test", 0, 0, "Checked 34 transfers"),
]
for scenario, test, errors, fatals, message in cases:
    result = subprocess.run(
        [
            loader,
            "--library-path",
            library_path,
            str(simv),
            "-no_save",
            f"+UVM_TESTNAME={test}",
            f"+scenario={scenario}",
        ],
        cwd=build,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=60,
    )
    (build / f"{scenario}.log").write_text(result.stdout)
    counts = dict(re.findall(r"UVM_(ERROR|FATAL)\s*:\s*(\d+)", result.stdout))
    assert counts == {"ERROR": str(errors), "FATAL": str(fatals)}, (
        scenario,
        counts,
        build,
    )
    assert message is None or message in result.stdout, (scenario, message, build)
    if not errors and not fatals:
        assert result.returncode == 0, (scenario, result.returncode, build)
    print(f"{scenario}: PASS")
print(f"Logs: {build}")
