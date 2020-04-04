#!/bin/bash

# MIT License

# Copyright (c) 2020 William Won (william.won@gatech.edu)

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
TOP_DIRECTORY=$(dirname $(readlink -f "$0"))
SRC_DIRECTORY="$TOP_DIRECTORY/src"
TESTBENCH_DIRECTORY="$TOP_DIRECTORY/testbench"

# Include path
INCLUDE_PATH="+"

# Build path
BUILD_DIRECTORY="$TOP_DIRECTORY/build"
B_DIRECTORY="$BUILD_DIRECTORY/bdir"
BIN_DIRECTORY="$BUILD_DIRECTORY/bin"
SIM_DIRECTORY="$BUILD_DIRECTORY/sim"
INFO_DIRECTORY="$BUILD_DIRECTORY/info"
VERILOG_DIRECTORY="$BUILD_DIRECTORY/verilog"


# Load configuration
CONFIGURATION_DIRECTORY="$TOP_DIRECTORY/configuration"
source $CONFIGURATION_DIRECTORY/DefaultTestbenchModule.sh
source $CONFIGURATION_DIRECTORY/DefaultVerilogModule.sh


# Functions
function clean {
    printf "%s\n" "[SCRIPT] Removing build directory at: $BUILD_DIRECTORY"
    rm -rf $BUILD_DIRECTORY
}

function make_directories {
    printf "\n%s\n" "[SCRIPT] Making build directories at: $BUILD_DIRECTORY"
    mkdir -p $BUILD_DIRECTORY
    mkdir -p $B_DIRECTORY
    mkdir -p $BIN_DIRECTORY
    mkdir -p $SIM_DIRECTORY
    mkdir -p $INFO_DIRECTORY
    mkdir -p $VERILOG_DIRECTORY
}

function setup {
    clean
    make_directories
    compute_include_path
}

function compute_include_path {
    printf "\n%s\n" "[SCRIPT] Computing include path"
    INCLUDE_PATH="+"
    for directory in $(find $TOP_DIRECTORY -mindepth 1 -maxdepth 1 -type d); do
		if ! [[ $directory =~ $TOP_DIRECTORY/\..* || $directory =~ $BUILD_DIRECTORY.* ]]; then
			INCLUDE_PATH="$INCLUDE_PATH:$directory"

			for subdirectory in $(find $directory -mindepth 1 -type d); do
				INCLUDE_PATH="$INCLUDE_PATH:$subdirectory"
			done
		fi
    done
}

function compile_testbench {
    setup
    printf "\n%s\n" "[SCRIPT] Compiling testbench: $1/$2Test.bsv"
    bsc -u -sim +RTS -K1024M -RTS -aggressive-conditions -no-warn-action-shadowing -check-assert -parallel-sim-link 8 -warn-scheduler-effort -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -p $INCLUDE_PATH $1/$2Test.bsv
    bsc -u -sim -e mk$2Test -o $BIN_DIRECTORY/$2Test +RTS -K1024M -RTS -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -warn-scheduler-effort -parallel-sim-link 8 -Xc++ -O0
    printf "\n%s\n" "[SCRIPT] Testbench compiled. Run with -r flag."
}

function compile_testbench_with_args {
    setup
    printf "\n%s\n" "[SCRIPT] Compiling testbench: $1/$2Test.bsv, with argument: $3"
    bsc -u -sim -D $3 +RTS -K1024M -RTS -aggressive-conditions -no-warn-action-shadowing -check-assert -parallel-sim-link 8 -warn-scheduler-effort -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -p $INCLUDE_PATH $1/$2Test.bsv
    bsc -u -sim -e mk$2Test -o $BIN_DIRECTORY/$2Test +RTS -K1024M -RTS -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -warn-scheduler-effort -parallel-sim-link 8 -Xc++ -O0
    printf "\n%s\n" "[SCRIPT] Testbench compiled. Run with -r flag."
}

function run_testbench {
    printf "%s\n\n" "[SCRIPT] Running simulation: $BIN_DIRECTORY/$1Test"
    $BIN_DIRECTORY/$1Test
}

function compile_verilog {
    setup
    printf "\n%s\n" "[SCRIPT] Compiling into Verilog: $1/$2.bsv"
    bsc -verilog -g mk$2 +RTS -K1024M -RTS -steps-max-intervals 200000 -aggressive-conditions -no-warn-action-shadowing -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -p $INCLUDE_PATH -u $1/$2.bsv
    find $SRC_DIRECTORY -name "*.v" -exec mv -t $VERILOG_DIRECTORY {} \+
    printf "\n%s\n" "[SCRIPT] Verilog files are saved at: $TOP_DIRECTORY/build/verilog/"
}

function compile_verilog_with_args {
    setup
    printf "\n%s\n" "[SCRIPT] Compiling into Verilog: $1/$2Test.bsv, with argument: $3"
    bsc -verilog -g mk$2 -D $3 +RTS -K1024M -RTS -steps-max-intervals 200000 -aggressive-conditions -no-warn-action-shadowing -bdir $B_DIRECTORY -simdir $SIM_DIRECTORY -info-dir $INFO_DIRECTORY -p $INCLUDE_PATH -u $1/$2.bsv
    find $SRC_DIRECTORY -name "*.v" -exec mv -t $VERILOG_DIRECTORY {} \+
    printf "\n%s\n" "[SCRIPT] Verilog files are saved at: $TOP_DIRECTORY/build/verilog/"
}

# Script
case "$1" in
    -l|--clean)
        clean;;
    -c|--compile)
        case "$2" in
            "")
                compile_testbench $DEFAULT_TEST_DIRECTORY $DEFAULT_TEST_MODULE;;
            *)
                case "$3" in
                "")
                    compile_testbench $TESTBENCH_DIRECTORY $2;;
                *)
                    compile_testbench_with_args $TESTBENCH_DIRECTORY $2 $3;;
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
        case "$2" in
            "")
                compile_verilog $DEFAULT_VERILOG_MODULE_DIRECTORY $DEFAULT_VERILOG_MODULE;;
            *)
                case "$3" in
                "")
                    compile_verilog $SRC_DIRECTORY $2;;
                *)
                    compile_verilog_with_args $SRC_DIRECTORY $2 $3;;
                esac;;
                
        esac;;
    -h|--help|*)
        printf "\n%s\n\n" "Usage: $0 <command> [<options>]"
        printf "\n%s\n" "Commands:"
        printf "    %-30s \n%s\n" "--help (-h)" "Shows this message"
        printf "    %-30s \n%s\n" "--clean (-l)" "Remove build folder"
        printf "    %-30s \n%s\n" "--compile (-c) [module]" "Compile [module] for simulation"
        printf "    %-30s \n%s\n" "--run (-r) [module]" "Run simulation for [module]"
        printf "    %-30s \n%s\n" "--verilog (-v) [module]" "Compile [module] in Verilog (saved in $TOP_DIRECTORY/build/verilog/)";;
esac
