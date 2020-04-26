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



import Vector::*;
import Connectable::*;
import SystolicArrayType::*;
import ProcessingElement::*;


interface SystolicArrayIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface SystolicArrayEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface SystolicArrayControlPort;
    method Action setStateTo(SystolicArrayState newState);
endinterface

interface SystolicArray#(numeric type systolicArrayWidth, numeric type systolicArrayHeight, type dataType);
    interface Vector#(systolicArrayWidth, SystolicArrayIngressPort#(dataType)) north;
    interface Vector#(systolicArrayHeight, SystolicArrayIngressPort#(dataType)) west;
    interface Vector#(systolicArrayWidth, SystolicArrayEgressPort#(dataType)) south;
    interface Vector#(systolicArrayHeight, SystolicArrayEgressPort#(dataType)) east;
    interface SystolicArrayControlPort control;
endinterface


module mkSystolicArray(SystolicArray#(systolicArrayWidth, systolicArrayHeight, dataType))
provisos (Bits#(dataType, dataTypeBitLength), Arith#(dataType));
    /**
    * Systolic Array
    */

    // Submodules
    Vector#(systolicArrayHeight, Vector#(systolicArrayWidth, ProcessingElement#(dataType))) processingElements <- replicateM(replicateM(mkProcessingElement));


    // Combinational Logics
    // 1. connect: column[0-(width-2)].east -> column[1-(width-1)].west
    // 2. connect: row[0-(width-2)].south -> row[0-(width-1)].north
    for (Integer row = 0; row < valueOf(systolicArrayHeight); row = row + 1) begin
        for (Integer column = 0; column < valueOf(systolicArrayWidth) - 1; column = column + 1) begin
            mkConnection(processingElements[row][column].east.get, processingElements[row][column + 1].west.put);
        end
    end

    for (Integer row = 0; row < valueOf(systolicArrayHeight) - 1; row = row + 1) begin
        for (Integer column = 0; column < valueOf(systolicArrayWidth); column = column + 1) begin
            mkConnection(processingElements[row][column].south.get, processingElements[row + 1][column].north.put);
        end
    end


    // Interfaces
    Integer lastRowIndex = valueOf(systolicArrayHeight) - 1;
    Integer lastColumnIndex = valueOf(systolicArrayWidth) - 1;

    Vector#(systolicArrayWidth, SystolicArrayIngressPort#(dataType)) northDefinition = newVector;
    Vector#(systolicArrayHeight, SystolicArrayIngressPort#(dataType)) westDefinition = newVector;
    Vector#(systolicArrayWidth, SystolicArrayEgressPort#(dataType)) southDefinition = newVector;
    Vector#(systolicArrayHeight, SystolicArrayEgressPort#(dataType)) eastDefinition = newVector;

    for (Integer column = 0; column < valueOf(systolicArrayWidth); column = column + 1) begin
        northDefinition[column] = interface SystolicArrayIngressPort#(dataType)
            method Action put(dataType data);
                processingElements[0][column].north.put(data);
            endmethod
        endinterface;

        southDefinition[column] = interface SystolicArrayEgressPort#(dataType)
            method ActionValue#(dataType) get;
                let southValue <- processingElements[lastRowIndex][column].south.get;
                return southValue;
            endmethod
        endinterface;
    end

    for (Integer row = 0; row < valueOf(systolicArrayHeight); row = row + 1) begin
        westDefinition[row] = interface SystolicArrayIngressPort#(dataType)
            method Action put(dataType data);
                processingElements[row][0].west.put(data);
            endmethod
        endinterface;

        eastDefinition[row] = interface SystolicArrayEgressPort#(dataType)
            method ActionValue#(dataType) get;
                let eastValue <- processingElements[row][lastColumnIndex].east.get;
                return eastValue;
            endmethod
        endinterface;
    end
        
    interface north = northDefinition;
    interface west = westDefinition;
    interface south = southDefinition;
    interface east = eastDefinition;

    interface control = interface SystolicArrayControlPort
        method Action setStateTo(SystolicArrayState newState);
            // Set all PEs to the given newState.
            for (Integer row = 0; row < valueOf(systolicArrayHeight); row = row + 1) begin
                for (Integer column = 0; column < valueOf(systolicArrayWidth); column = column + 1) begin
                    processingElements[row][column].control.setStateTo(newState);
                end
            end
        endmethod
    endinterface;
endmodule
