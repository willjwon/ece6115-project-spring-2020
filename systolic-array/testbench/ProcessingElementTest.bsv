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
import ProcessingElement::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkProcessingElementTest();
    // Unit Under Test
    ProcessingElement#(Bit#(32)) processingElement <- mkProcessingElement;
    
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


    rule setLoad if (cycle == 3);
        processingElement.control.setStateTo(Load);
    endrule

    rule doLoad if (cycle == 5);
        processingElement.north.put(3);
    endrule
    
    rule setCompute if (cycle == 10);
        processingElement.control.setStateTo(Compute);
    endrule

    rule putValues if (cycle == 13);
        processingElement.north.put(7);
        processingElement.west.put(2);
    endrule

    rule getResult if (cycle == 23);
        $display("Testing rule getResult");

        let eastValue <- processingElement.east.get;
        dynamicAssert(eastValue == 2, "Should forward west");

        let southValue <- processingElement.south.get;
        dynamicAssert(southValue == 13, "Should compute next psum");
    endrule
    
    rule putTrash if (cycle == 33);
        processingElement.west.put(1);
    endrule

    rule shouldNotPrint if (33 < cycle && cycle < 47);
        let eastValue <- processingElement.east.get;
        $display("failed: shouldNotPrint");
    endrule

    rule doReset if (cycle == 47);
        processingElement.control.setStateTo(Reset);
    endrule

    rule startCompute if (cycle == 63);
        processingElement.control.setStateTo(Compute);
    endrule

    rule doPut if (cycle == 76);
        processingElement.north.put(17);
        processingElement.west.put(32);
    endrule

    rule forward2 if (cycle == 83);
        $display("Testing rule forward2");

        let eastValue <- processingElement.east.get;
        dynamicAssert(eastValue == 32, "Should forward west");

        let southValue <- processingElement.south.get;
        dynamicAssert(southValue == 17, "Should forward south");
    endrule
endmodule
