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


import FIFOF::*;
import SpecialFIFOs::*;

import SystolicArrayType::*;


interface ProcessingElementIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface ProcessingElementEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface ProcessingElementControlPort;
    method Action setStateTo(SystolicArrayState newState);
endinterface

interface ProcessingElement#(type dataType);
    interface ProcessingElementIngressPort#(dataType) north;
    interface ProcessingElementIngressPort#(dataType) west;
    interface ProcessingElementEgressPort#(dataType) south;
    interface ProcessingElementEgressPort#(dataType) east;
    interface ProcessingElementControlPort control;
endinterface


module mkProcessingElement(ProcessingElement#(dataType))
provisos (Bits#(dataType, dataTypeBitLength), Arith#(dataType));
    /**
    *
    * Systolic Array Processing Element (PE)
    *
    */

    // Input and output fifos
    FIFOF#(dataType) northFifo <- mkBypassFIFOF;
    FIFOF#(dataType) westFifo <- mkBypassFIFOF;
    FIFOF#(dataType) southFifo <- mkPipelineFIFOF;
    FIFOF#(dataType) eastFifo <- mkPipelineFIFOF;

    // Systolic array state
    Reg#(SystolicArrayState) processingElementState <- mkReg(Reset);

    // Loaded Value
    Reg#(Maybe#(dataType)) loadedValue <- mkReg(tagged Invalid);

    
    // Rules
    rule doReset if (processingElementState == Reset);
        northFifo.clear;
        westFifo.clear;
        southFifo.clear;
        eastFifo.clear;
        loadedValue <= tagged Invalid;
    endrule

    rule loadValue if (processingElementState == Load);
        // value to load would be fed into North port
        // 1. If already loaded, forward to south
        // 2. If not loaded, consume and load the value

        if (isValid(loadedValue)) begin
            // already loaded
            southFifo.enq(northFifo.first);
        end else begin
            // not loaded
            loadedValue <= tagged Valid northFifo.first;
        end

        northFifo.deq;
    endrule

    rule forwardValues if (processingElementState == Compute && !isValid(loadedValue));
        // just forward values
        if (northFifo.notEmpty) begin
            southFifo.enq(northFifo.first);
            northFifo.deq;
        end

        if (westFifo.notEmpty) begin
            eastFifo.enq(westFifo.first);
            westFifo.deq;
        end
    endrule

    rule doCompute if (processingElementState == Compute && isValid(loadedValue));
        // should compute.
        // if not all the values are ready, stall and wait for them (don't forward).
        let loadValue = validValue(loadedValue);
        let psum = northFifo.first;
        let inputActivation = westFifo.first;

        let newPsum = psum + (loadValue * inputActivation);
        eastFifo.enq(westFifo.first);
        southFifo.enq(newPsum);

        northFifo.deq;
        westFifo.deq;
    endrule

    
    // Interfaces
    interface north = interface ProcessingElementIngressPort
        method Action put(dataType data);
            northFifo.enq(data);
        endmethod
    endinterface;

    interface west = interface ProcessingElementIngressPort
        method Action put(dataType data);
            westFifo.enq(data);
        endmethod
    endinterface;

    interface south = interface ProcessingElementEgressPort
        method ActionValue#(dataType) get;
            southFifo.deq;
            return southFifo.first;
        endmethod
    endinterface;

    interface east = interface ProcessingElementEgressPort
        method ActionValue#(dataType) get;
            eastFifo.deq;
            return eastFifo.first;
        endmethod
    endinterface;

    interface control = interface ProcessingElementControlPort
        method Action setStateTo(SystolicArrayState newState);
            processingElementState <= newState;
        endmethod
    endinterface;
endmodule
