// MIT License

// Copyright (c) 2020 William Won (william.won@gatech.edu)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Assert::*;

import SystolicArrayType::*;
import SystolicArray::*;


Bit#(32) maxCycle = 1000;


(* synthesize *)
module mkSystolicArrayTest();
    // Unit Under Test
    SystolicArray#(4, 3, Bit#(32)) systolicArray <- mkSystolicArray;
    

    // Testbench Environment
    Reg#(Bit#(32)) cycle <- mkReg(0);


    // Run Testbench
    rule runTestbench if (cycle < maxCycle);
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("[Finish] Cycle %d reached.", maxCycle);
        $finish(0);
    endrule


    // Systolic Array setup
    for (Integer row = 0; row < 3; row = row + 1) begin
        rule discardRightmostValue;
            let discardValue <- systolicArray.east[row].get;
        endrule
    end
    

    // Test cases
    rule setLoadWeight if (cycle == 1);
        systolicArray.control.setStateTo(Load);
    endrule

    rule putWeight if (2 <= cycle && cycle <= 3);
        // 
        // Loaded weight:
        // 2 3 4 x
        // 3 4 5 x
        // x x x x
        //
        for (Integer i = 0; i < 3; i = i + 1) begin
            systolicArray.north[i].put(cycle + fromInteger(i));
        end
    endrule

    rule doCompute if (cycle == 7);
        systolicArray.control.setStateTo(Compute);
    endrule

    rule putValues if (cycle == 17);
        systolicArray.north[0].put(0);
        systolicArray.west[0].put(3);
    endrule

    rule putValue0 if (cycle == 21);
        systolicArray.west[1].put(5);
    endrule

    rule putValues1 if (cycle == 23);
        systolicArray.north[1].put(5);
    endrule

    rule testResult if (cycle == 37);
        $display("testResult");

        // 0 + (2 * 3) + (3 * 5) = 21
        let south0 <- systolicArray.south[0].get;
        dynamicAssert(south0 == 21, "Should be 21");

        // 5 + (3 * 3) + (4 * 5) = 34
        let south1 <- systolicArray.south[1].get;
        dynamicAssert(south1 == 34, "Should be 34");
    endrule

    rule putValueTo0 if (cycle == 45);
        systolicArray.north[0].put(7);
        systolicArray.west[0].put(3);
    endrule

    rule putvauleTo2 if (cycle == 57);
        systolicArray.north[2].put(3);
    endrule

    rule getResult2 if (cycle == 73);
        $display("getResult2");

        // 3 + (4 * 3) + (5 * 5) = 40
        let south2 <- systolicArray.south[2].get;
        dynamicAssert(south2 == 40, "Should be 40");
    endrule

    rule doReset if (cycle == 100);
        systolicArray.control.setStateTo(Reset);
    endrule

    rule doLoadWeight if (cycle == 101);
        systolicArray.control.setStateTo(Load);
    endrule

    rule reload if (103 <= cycle && cycle <= 105);
        // 1 2 3 x
        // 2 3 4 x 
        // 3 4 5 x
        // x x x x
        for (Integer i = 0; i < 3; i = i + 1) begin
            systolicArray.north[i].put(cycle - 102 + fromInteger(i));
        end
    endrule

    rule dodoCompute if (cycle == 120);
        systolicArray.control.setStateTo(Compute);
    endrule

    rule stage1 if (cycle == 121);
        for (Integer i = 0; i < 3; i = i + 1) begin
            // put (1, 2, 3)
            systolicArray.north[i].put(0);
            systolicArray.west[i].put(1 + fromInteger(i));
        end
    endrule

    rule stage2 if (cycle == 124);
        for (Integer i = 0; i < 3; i = i + 1) begin
            // put (2, 3, 4)
            systolicArray.north[i].put(0);
            systolicArray.west[i].put(2 + fromInteger(i));
        end
    endrule

    // Correct result:
    //      1 4 9 = 14
    //      2 6 12 = 20
    //      3 8 15 = 26
    //
    //      2 6 12 = 20
    //      4 9 16 = 29
    //      6 12 20 = 38
    //
    for (Integer i = 0; i < 4; i = i + 1) begin
        rule printResult if (cycle> 122);
            let southResult <- systolicArray.south[i].get;
            $display("cycle %d, south %d -> %d", cycle, i, southResult);
        endrule
    end
endmodule
