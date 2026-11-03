# DualClear gate execution runbook

This file is documentation, not an executable script. Run each step manually, in
order, from one Bash session. Do not run steps in parallel, in the background, or
from more than one terminal.

## Scope and fixed inputs

Repository root:

    $(git rev-parse --show-toplevel)

Workspace root:

    $(git rev-parse --show-toplevel)/gate

Pinned compiler:

    $(git rev-parse --show-toplevel)/.contest-tools/fe_linux_amd64

Required compiler identity:

    fe 26.5.0 (3dab95f)
    SHA-256 3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0

Workspace member names are exactly:

- dualclear_core
- dualclear_evm
- dualclear_native

The -i/--ingot value is a member name, while PATH must be the workspace root
gate. Never combine -i with gate/core, gate/evm, or gate/native.

## Hard rules

- Keep every heavy command serial.
- Use I/O idle priority, CPU nice level 19, and one test job.
- Set RAYON_NUM_THREADS=1 for compiler work.
- Do not use fe run; Fe 26.5.0 has no run subcommand.
- Stop at the first non-zero return code and classify it before any retry.
- Preserve failed logs and outputs under their original run ID.
- Do not modify source to make a resource or CLI failure disappear.
- A retry is allowed only once, under a new run ID, after an independently
  demonstrated infrastructure or resource-guard failure.
- Do not use EVM tracing, call traces, reports, or debug artifacts on the first
  pass. They are diagnostic reruns only.

## 1. Resource guard

Run the following read-only observations immediately before the EVM phase and
again before the native phase. Process inspection is restricted to PID, nice
level, CPU percentage, memory percentage, elapsed time, state, and command name:

    ROOT=$(git rev-parse --show-toplevel)
    nproc
    cat /proc/loadavg
    awk '$1 == "MemTotal:" || $1 == "MemAvailable:" { print }' /proc/meminfo
    df -Pk "$ROOT"
    export LC_ALL=C
    PS_FIELDS='pid=,ni=,pcpu=,pmem=,etime=,stat=,comm='
    SAMPLE_A=$(ps -eo "$PS_FIELDS" --sort=-pcpu)
    printf '%s\n' "$SAMPLE_A" | head -n 25
    sleep 15
    SAMPLE_B=$(ps -eo "$PS_FIELDS" --sort=-pcpu)
    printf '%s\n' "$SAMPLE_B" | head -n 25

Do not inspect process arguments, command lines, paths, working directories,
executables, environments, open files, or routing. In particular, do not use
ps args/cmd, pgrep -a/-f, /proc/PID/cmdline, /proc/PID/cwd, /proc/PID/exe, or
lsof to attribute an external process.

All of these conditions are required:

1. Neither sample contains an external Fe/compiler process name such as fe,
   fe_linux_amd64, cargo, or rustc. Before this run starts, any such process is
   treated as external because this run has not launched compiler work.
2. No external PID consumes at least 75.0 percent CPU in both samples. The
   samples are 15 seconds apart; this is the exact sustained-heavy-work guard
   and covers non-Fe work using roughly one CPU, regardless of its command name.
3. No other runner is operating on this repository.
4. The one-minute load average is at most half of nproc. This host currently has
   eight logical CPUs, so the current ceiling is 4.00.
5. MemAvailable is at least 4194304 KiB (4 GiB) AND at least 25 percent of
   MemTotal. Falling below either threshold is RG-STOP.
6. The filesystem containing ROOT has at least 20971520 KiB (20 GiB) available.

The following checks encode the thresholds without reading process arguments:

    printf '%s\n' "$SAMPLE_A" "$SAMPLE_B" | awk '
      $7 ~ /^(fe|fe_linux_amd64|cargo|rustc)$/ { found = 1 }
      END { exit found ? 1 : 0 }
    '
    awk '
      FNR == NR {
        if (($3 + 0) >= 75.0) hot[$1] = 1
        next
      }
      (($1 in hot) && (($3 + 0) >= 75.0)) {
        print
        found = 1
      }
      END { exit found ? 1 : 0 }
    ' <(printf '%s\n' "$SAMPLE_A") <(printf '%s\n' "$SAMPLE_B")
    LOAD1=$(awk '{ print $1 }' /proc/loadavg)
    CPUS=$(nproc)
    awk -v load="$LOAD1" -v cpus="$CPUS" 'BEGIN { exit !(load <= cpus / 2) }'
    awk '
      $1 == "MemTotal:" { total = $2 }
      $1 == "MemAvailable:" { available = $2 }
      END {
        exit !(available >= 4194304 && available * 4 >= total)
      }
    ' /proc/meminfo
    test "$(df -Pk "$ROOT" | awk 'NR == 2 { print $4 }')" -ge 20971520

If any condition fails, classify the attempt as RG-STOP. Do not start a heavy
command and do not count it as a product result. Sustained external heavy work
is the current RG-STOP reason even when no Fe process is present.

## 2. Run identity, provenance, and logging

Use a new UTC run ID. The .gate-artifacts directory is ignored by Git.

    ROOT=$(git rev-parse --show-toplevel)
    GATE="$ROOT/gate"
    FE="$ROOT/.contest-tools/fe_linux_amd64"
    RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
    ART="$ROOT/.gate-artifacts/$RUN_ID"
    mkdir -p "$ART/logs" "$ART/evm-build" "$ART/native-build"
    export RAYON_NUM_THREADS=1
    set -u -o pipefail

Capture provenance before the first heavy command:

    {
      date -u +%FT%TZ
      "$FE" --version
      sha256sum "$FE"
      uname -a
      git -C "$ROOT" rev-parse HEAD
      git -C "$ROOT" status --short
    } > "$ART/logs/00-provenance.log"

Require an exact toolchain match:

    test "$("$FE" --version)" = "fe 26.5.0 (3dab95f)"
    printf '%s  %s\n' \
      3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0 \
      "$FE" | sha256sum -c -

For every numbered command:

1. Write its exact command and UTC start time to its log.
2. Run it through timeout, ionice -c3, and nice -n19.
3. Send stdout and stderr to the named log.
4. Record the return code and UTC end time.
5. Continue only on RC 0.

With set -o pipefail, a tee pipeline returns the heavy command failure rather
than hiding it. Record the RC immediately after each pipeline.

## 3. EVM build

The EVM adapter transitively compiles the shared core. Sonatina is the EVM
backend name; there is no backend named evm.

    date -u +%FT%TZ | tee "$ART/logs/10-evm-build.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" build \
      --backend sonatina --profile release -O1 \
      --emit bytecode,runtime-bytecode,abi,metadata \
      --out-dir "$ART/evm-build" \
      -i dualclear_evm "$GATE" \
      2>&1 | tee -a "$ART/logs/10-evm-build.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/10-evm-build.log"
    test "$RC" -eq 0 || exit "$RC"

Expected evidence includes contract bytecode, runtime bytecode, ABI, metadata,
the complete log, and RC 0.

## 4. Sonatina tests

First test the shared core directly, then the EVM adapter. The commands are
separate so a core failure is distinguishable from an ABI adapter failure.

    date -u +%FT%TZ | tee "$ART/logs/20-sonatina-core-tests.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" test \
      --backend sonatina --profile test -O1 \
      --jobs 1 --grouped \
      -i dualclear_core "$GATE" \
      2>&1 | tee -a "$ART/logs/20-sonatina-core-tests.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/20-sonatina-core-tests.log"
    test "$RC" -eq 0 || exit "$RC"

    date -u +%FT%TZ | tee "$ART/logs/30-sonatina-adapter-tests.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" test \
      --backend sonatina --profile test -O1 \
      --jobs 1 --grouped \
      -i dualclear_evm "$GATE" \
      2>&1 | tee -a "$ART/logs/30-sonatina-adapter-tests.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/30-sonatina-adapter-tests.log"
    test "$RC" -eq 0 || exit "$RC"

Re-run the resource guard before continuing to native work.

## 5. Native executable build

Native executable output requires both --backend native and --emit executable.
Do not add --contract; native executable output rejects it.

    date -u +%FT%TZ | tee "$ART/logs/40-native-build.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" build \
      --backend native --profile release -O1 \
      --emit executable \
      --out-dir "$ART/native-build" \
      -i dualclear_native "$GATE" \
      2>&1 | tee -a "$ART/logs/40-native-build.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/40-native-build.log"
    test "$RC" -eq 0 || exit "$RC"

There must be exactly one user-executable regular file in native-build:

    find "$ART/native-build" -type f -perm -u+x -print \
      | sort | tee "$ART/logs/41-native-executable.txt"
    test "$(wc -l < "$ART/logs/41-native-executable.txt")" -eq 1
    NATIVE_EXE=$(sed -n '1p' "$ART/logs/41-native-executable.txt")
    test -n "$NATIVE_EXE"

## 6. Native executable run

The native main returns 0 only when its shared golden matches.

    date -u +%FT%TZ | tee "$ART/logs/50-native-run.log"
    timeout 30s ionice -c3 nice -n19 \
      "$NATIVE_EXE" \
      2>&1 | tee -a "$ART/logs/50-native-run.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/50-native-run.log"
    test "$RC" -eq 0 || exit "$RC"

## 7. Native tests

Test the same shared core under the native backend, then test the native wrapper.
The outer timeout is 30 minutes and every native test also has a 120-second
wall-time limit.

    date -u +%FT%TZ | tee "$ART/logs/60-native-core-tests.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" test \
      --backend native --profile test -O1 \
      --jobs 1 --grouped --native-timeout-secs 120 \
      -i dualclear_core "$GATE" \
      2>&1 | tee -a "$ART/logs/60-native-core-tests.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/60-native-core-tests.log"
    test "$RC" -eq 0 || exit "$RC"

    date -u +%FT%TZ | tee "$ART/logs/70-native-wrapper-tests.log"
    timeout 30m ionice -c3 nice -n19 \
      "$FE" test \
      --backend native --profile test -O1 \
      --jobs 1 --grouped --native-timeout-secs 120 \
      -i dualclear_native "$GATE" \
      2>&1 | tee -a "$ART/logs/70-native-wrapper-tests.log"
    RC=$?
    printf 'RC=%s END=%s\n' "$RC" "$(date -u +%FT%TZ)" \
      | tee -a "$ART/logs/70-native-wrapper-tests.log"
    test "$RC" -eq 0 || exit "$RC"

Do not pass EVM logging or tracing options to native tests. Options beginning
with --native- are valid only with --backend native.

## 8. Outputs and hashes

Before hashing, record all final RCs in GATE-LOG.md. Then make no further change
to source, logs, or artifacts included below.

Create a deterministic source manifest. It intentionally excludes .git,
.contest-tools, .gate-artifacts, and generated out directories.

    (
      cd "$ROOT"
      {
        printf '%s\0' \
          .gitignore README.md TOOLCHAIN.md GATE-LOG.md GATE-RUNBOOK.md
        find gate -type f \( -name 'fe.toml' -o -name '*.fe' \) -print0
      } | sort -z | xargs -0 sha256sum
    ) > "$ART/source.sha256"

Create the toolchain manifest:

    (
      cd "$ROOT"
      sha256sum .contest-tools/fe_linux_amd64
    ) > "$ART/toolchain.sha256"

Record sizes before hashing outputs:

    find "$ART/logs" "$ART/evm-build" "$ART/native-build" \
      -type f -printf '%s %p\n' | sort \
      > "$ART/80-output-inventory.txt"
    mv "$ART/80-output-inventory.txt" \
      "$ART/logs/80-output-inventory.txt"

Create the output manifest. It does not include itself:

    (
      cd "$ART"
      find logs evm-build native-build -type f -print0 \
        | sort -z | xargs -0 sha256sum
    ) > "$ART/outputs.sha256"

Finally hash the three manifests. The root manifest does not hash itself:

    (
      cd "$ART"
      sha256sum source.sha256 toolchain.sha256 outputs.sha256
    ) > "$ART/evidence-root.sha256"

Verify every manifest before accepting the evidence:

    (
      cd "$ROOT"
      sha256sum -c "$ART/source.sha256"
    )
    (
      cd "$ROOT"
      sha256sum -c "$ART/toolchain.sha256"
    )
    (
      cd "$ART"
      sha256sum -c outputs.sha256
      sha256sum -c evidence-root.sha256
    )

## 9. Failure classification

Use exactly one primary classification per failed step:

- RG-STOP: a resource-guard threshold fails, any external Fe/compiler process
  is present, or any external PID is sustained at 75 percent CPU or more. No
  product command starts and no gate result is inferred.
- PROVENANCE-STOP: compiler version or SHA-256 differs. Do not run anything
  heavy until the pinned toolchain is restored and independently verified.
- CLI-PLAN: the command is rejected before compilation because of an invalid
  member, path, backend, or emit combination. Correct the runbook command; do
  not change product source.
- INFRA: timeout caused by demonstrated host contention, OOM kill, filesystem
  exhaustion, lost SSH session, or an unavailable host dependency. Preserve
  evidence and allow at most one clean retry after the guard passes.
- CORE-KILL: the shared core reproducibly fails a correct build/test path,
  violates an allocation invariant, or fails its common golden under a passing
  resource guard. This is a KILL condition.
- EVM-S0: the Sonatina/EVM build or adapter test reproducibly fails while the
  shared core remains sound. This blocks the EVM gate path and requires HOLD
  until triage; it is not reclassified as a native-only problem.
- NATIVE-PLAN-B: the native executable build, wrapper test, native backend, or
  executable run fails in isolation while the shared core and the complete EVM
  path are green. This may select PLAN B EVM and is not automatically S0/KILL.
- CROSS-BACKEND-KILL: both backends validly execute the same shared case but
  disagree on allocation, fingerprint, ordering, or conservation. A confirmed
  semantic divergence is a KILL condition; inability to build or start only the
  native adapter is NATIVE-PLAN-B, not a semantic divergence.
- PERF-S1: the same bounded workload times out twice under passing guards,
  without an OOM or external contention explanation.
- EVIDENCE-STOP: output inventory or any hash verification fails. Do not issue
  GO until evidence is complete and stable.

A clean GO requires RC 0 for the EVM build, both Sonatina test suites, native
build, native executable run, and both native test suites; exactly one native
executable; a clean provenance record; and four verifying hash manifests.

PLAN B EVM is permitted only when the shared core and complete EVM path are
green and the failure is isolated and demonstrated in the native
adapter/backend/run path, with no valid semantic divergence. CORE-KILL or
CROSS-BACKEND-KILL requires KILL. Otherwise retain HOLD pending classification
and evidence.

## 10. Fe 26.5.0 CLI traps

Expected command-plan failures include:

- -i evm or -i native: those are directory names, not workspace member names.
- Passing gate/evm, gate/native, or gate/core with -i: -i requires a workspace
  root input path.
- Omitting PATH while the current directory is the repository root: fe.toml is
  under gate, not at the repository root.
- --backend evm: valid public backends are sonatina and native.
- fe run: the subcommand does not exist.
- --emit executable without --backend native.
- --contract on a native executable build.
- bytecode, runtime-bytecode, ABI, or metadata emission with the native backend.
- --emit elf: Fe 26.5.0 internally requires the unavailable sp1 backend despite
  advertising elf in generic help.
- EVM trace or log flags on native tests.
- --native-timeout-secs or --native-output-limit-kib without --backend native.

Do not build dualclear_core as a standalone artifact: it has neither a contract
nor main. The EVM and native builds compile it transitively; the two direct core
test commands exercise it under both backends.
