#!/usr/bin/env bash

SRC="$1"

if [ -z "$SRC" ]; then
    echo "Usage: $0 source.c|source.cpp"
    exit 1
fi

if [ ! -f "$SRC" ]; then
    echo "File not found: $SRC"
    exit 1
fi

C_COMPILERS=("gcc" "clang")
CPP_COMPILERS=("g++" "clang++")

C_STANDARDS=("c89" "c99" "c11" "c17" "c23" "gnu89" "gnu99" "gnu11")
CPP_STANDARDS=("c++98" "c++11" "c++14" "c++17" "c++20" "c++23" "c++26" "gnu++17" "gnu++20")

OPT_LEVELS=("0" "1" "2" "3" "s")

WARN_FLAGS="-Wall -Wextra -Wpedantic"
SAN_FLAGS="-fsanitize=address,undefined"

SUMMARY="test_summary.md"
DETAILS="test_details.txt"

cat > "$SUMMARY" <<EOF
| Compiler | Lang | Standard | Opt | Compile | Warnings | Exit | Runtime Output | Notes |
|----------|------|----------|-----|---------|----------|------|----------------|-------|
EOF

> "$DETAILS"

sanitize_output() {
    # Take first line, max 40 chars, escape pipes for Markdown
    head -n 1 "$1" | tr -d '\n' | cut -c1-40 | sed 's/|/\\|/g'
}

run_matrix() {
    COMPILER=$1
    LANG=$2
    STANDARDS=("${!3}")

    if ! command -v $COMPILER >/dev/null 2>&1; then
        return
    fi

    for STD in "${STANDARDS[@]}"; do
        for OPT in "${OPT_LEVELS[@]}"; do

            BIN="tmp_${COMPILER}_${STD}_O${OPT}"
            COMPILE_LOG="compile_err.txt"
            RUN_LOG="run_out.txt"

            CMD="$COMPILER -std=$STD -O$OPT $WARN_FLAGS $SAN_FLAGS $SRC -o $BIN"

            $CMD > /dev/null 2> "$COMPILE_LOG"
            COMPILE_STATUS=$?
            WARN_COUNT=$(grep -i "warning:" "$COMPILE_LOG" | wc -l)

            if [ $COMPILE_STATUS -ne 0 ]; then
                echo "| $COMPILER | $LANG | $STD | O$OPT | ❌ | $WARN_COUNT | - | - | Compile Error |" >> "$SUMMARY"

                {
                    echo "==== $COMPILER $LANG $STD O$OPT ===="
                    echo "Command: $CMD"
                    cat "$COMPILE_LOG"
                    echo
                } >> "$DETAILS"

                rm -f "$COMPILE_LOG"
                continue
            fi

            ./"$BIN" > "$RUN_LOG" 2>&1
            EXIT_CODE=$?

            RUNTIME_OUTPUT=$(sanitize_output "$RUN_LOG")

            NOTES="OK"
            grep -qi "runtime error" "$RUN_LOG" && NOTES="UBSan"
            grep -qi "AddressSanitizer" "$RUN_LOG" && NOTES="ASan"

            echo "| $COMPILER | $LANG | $STD | O$OPT | ✅ | $WARN_COUNT | $EXIT_CODE | $RUNTIME_OUTPUT | $NOTES |" >> "$SUMMARY"

            if [ "$WARN_COUNT" -gt 0 ] || [ "$NOTES" != "OK" ]; then
                {
                    echo "==== $COMPILER $LANG $STD O$OPT ===="
                    echo "Command: $CMD"
                    echo "--- Compile Output ---"
                    cat "$COMPILE_LOG"
                    echo "--- Runtime Output ---"
                    cat "$RUN_LOG"
                    echo
                } >> "$DETAILS"
            fi

            rm -f "$BIN" "$COMPILE_LOG" "$RUN_LOG"

        done
    done
}

run_matrix "gcc" "C" C_STANDARDS[@]
run_matrix "clang" "C" C_STANDARDS[@]
run_matrix "g++" "C++" CPP_STANDARDS[@]
run_matrix "clang++" "C++" CPP_STANDARDS[@]

echo "Markdown summary written to $SUMMARY"
echo "Detailed logs written to $DETAILS"
