#!/bin/bash

# MIT License

# Copyright (c) 2020 Synergy Lab | Georgia Institute of Technology
# Author: William Won (william.won@gatech.edu)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Path
# Source path
TOP_DIR="$(dirname $(realpath $0))"
SRC_DIR="$TOP_DIR/src"

# # Build path
BUILD_DIR="$TOP_DIR/build"
B_DIR="$BUILD_DIR/bdir"
BIN_DIR="$BUILD_DIR/bin"
SIM_DIR="$BUILD_DIR/sim"
INFO_DIR="$BUILD_DIR/info"
VERILOG_DIR="$BUILD_DIR/verilog"

# Load default module
DEFAULT_DIR="$TOP_DIR/default"
source $DEFAULT_DIR/DefaultTestbench.sh
source $DEFAULT_DIR/DefaultVerilog.sh

# Include path
INCLUDE_PATH="+"

function compute_include_path {
    for directory in $(find $TOP_DIR -mindepth 1 -type d); do
		if ! [[ $directory =~ $TOP_DIR/\..* || $directory =~ $BUILD_DIR.* ]]; then
			INCLUDE_PATH="$INCLUDE_PATH:$directory"
		fi
    done
}

function clean {
    rm -rf $BUILD_DIR
}

function make_directories {
    mkdir -p $BUILD_DIR
    mkdir -p $B_DIR
    mkdir -p $BIN_DIR
    mkdir -p $SIM_DIR
    mkdir -p $INFO_DIR
    mkdir -p $VERILOG_DIR
}

function setup {
    clean
    compute_include_path
    make_directories
}

function compile_testbench {
    bsc -u -sim +RTS -K4096M -RTS -aggressive-conditions -no-warn-action-shadowing -check-assert -parallel-sim-link 8 -warn-scheduler-effort -steps-max-intervals 200000 -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -p $INCLUDE_PATH $1/$2.bsv
    bsc -u -sim -e mk$2 -o $BIN_DIR/$2 +RTS -K4096M -RTS -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -warn-scheduler-effort -parallel-sim-link 8 -Xc++ -O0
}

function compile_testbench_with_args {
    bsc -u -sim -D $3 +RTS -K4096M -RTS -aggressive-conditions -no-warn-action-shadowing -check-assert -parallel-sim-link 8 -warn-scheduler-effort -steps-max-intervals 200000 -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -p $INCLUDE_PATH $1/$2.bsv
    bsc -u -sim -e mk$2 -o $BIN_DIR/$2 +RTS -K4096M -RTS -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -warn-scheduler-effort -parallel-sim-link 8 -Xc++ -O0
}

function run_testbench {
    $BIN_DIR/$1
}

function compile_verilog {
    bsc -verilog -g mk$2 +RTS -K4096M -RTS -warn-scheduler-effort -steps-max-intervals 200000 -aggressive-conditions -no-warn-action-shadowing -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -p $INCLUDE_PATH -u $1/$2.bsv
    find $TOP_DIR -type f -name "*.v" -exec mv {} $VERILOG_DIR \;
}

function compile_verilog_with_args {
    bsc -verilog -g mk$2 -D $3 +RTS -K4096M -RTS -warn-scheduler-effort -steps-max-intervals 200000 -aggressive-conditions -no-warn-action-shadowing -bdir $B_DIR -simdir $SIM_DIR -info-dir $INFO_DIR -p $INCLUDE_PATH -u $1/$2.bsv
    find $TOP_DIR -type f -name "*.v" -exec mv {} $VERILOG_DIR \;
}

# Script
case "$1" in
-l|--clean)
    clean;;
-c|--compile)
    setup
    case "$2" in
    "")
        compile_testbench $DEFAULT_TEST_DIR $DEFAULT_TEST_MODULE;;
    *)
        case "$3" in
        "")
            compile_testbench_with_args $DEFAULT_TEST_DIR $DEFAULT_TEST_MODULE $2;;
        *)
            case "$4" in
            "")
                compile_testbench $2 $3;;
            *)
                compile_testbench_with_args $2 $3 $4;;
            esac;;
        esac;;
    esac;;
-r|--run)
    case "$2" in
    "")
        run_testbench $DEFAULT_TEST_MODULE;;
    *)
        run_testbench $2;;
    esac;;
-v|--verilog)
    setup
    case "$2" in
    "")
        compile_verilog $DEFAULT_VERILOG_DIR $DEFAULT_VERILOG_MODULE;;
    *)
        case "$3" in
        "")
            compile_verilog_with_args $DEFAULT_VERILOG_DIR $DEFAULT_VERILOG_MODULE $2;;
        *)
            case "$4" in
            "")
                compile_verilog $2 $3;;
            *)
                compile_verilog_with_args $2 $3 $4;;
            esac;;
        esac;;
    esac;;
-h|--help|*)
    printf "\n%s\n\n" "Usage: $0 <command> [<options>]"
    printf "\n%s\n" "Commands:"
    printf "    %-30s \n%s\n" "--help (-h)" "Shows this message"
    printf "    %-30s \n%s\n" "--clean (-l)" "Remove build folder"
    printf "    %-30s \n%s\n" "--compile (-c) [module]" "Compile [module] for simulation"
    printf "    %-30s \n%s\n" "--run (-r) [module]" "Run simulation for [module]"
    printf "    %-30s \n%s\n" "--verilog (-v) [module]" "Compile [module] in Verilog (saved in $TOP_DIR/build/verilog/)";;
esac
