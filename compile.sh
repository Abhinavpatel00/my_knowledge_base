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

OUTFILE="test_results.txt"

echo "Compiler | Lang | Std     | Opt | Compiles | Exit | Output" > "$OUTFILE"
echo "--------------------------------------------------------------------------" >> "$OUTFILE"

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

            $COMPILER -std=$STD -O$OPT $WARN_FLAGS $SAN_FLAGS "$SRC" -o "$BIN" 2> "$COMPILE_LOG"

            if [ $? -ne 0 ]; then
                echo "$COMPILER | $LANG | $STD | O$OPT | NO | - | Compile Error" >> "$OUTFILE"
                rm -f "$COMPILE_LOG"
                continue
            fi

            ./"$BIN" > "$RUN_LOG" 2>&1
            EXIT_CODE=$?

            OUTPUT=$(head -n 1 "$RUN_LOG" | tr -d '\n' | cut -c1-40)

            echo "$COMPILER | $LANG | $STD | O$OPT | YES | $EXIT_CODE | $OUTPUT" >> "$OUTFILE"

            rm -f "$BIN" "$COMPILE_LOG" "$RUN_LOG"

        done
    done
}

run_matrix "gcc"    "C"   C_STANDARDS[@]
run_matrix "clang"  "C"   C_STANDARDS[@]
run_matrix "g++"    "C++" CPP_STANDARDS[@]
run_matrix "clang++" "C++" CPP_STANDARDS[@]

echo "Results written to $OUTFILE"

