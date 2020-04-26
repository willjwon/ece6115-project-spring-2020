import Vector::*;
import FIFOF::*;
import SpecialFIFOs::*;
import CReg::*;
import NetworkConfiguration::*;
import TestbenchConfiguration::*;
import MessageType::*;
import RoutingType::*;


interface TrafficGeneratorBuffer;
    method Bit#(32) remainingFlitsCount;
    method Action putFlit(Flit flit);
    method ActionValue#(Flit) getFlit;
endinterface


(* synthesize *)
module mkTrafficGeneratorBuffer(TrafficGeneratorBuffer);
    // Submodule
    FIFOF#(Flit) tempFifo <- mkSizedBypassFIFOF(valueOf(TrafficGeneratorSlotsCount));
    CReg#(2, Bit#(32)) remainingFlits <- mkCReg(0);
    

    // Interface
    method Bit#(32) remainingFlitsCount = remainingFlits[0];

    method Action putFlit(Flit flit);
        remainingFlits[0] <= remainingFlits[0] + 1;
        tempFifo.enq(flit);
    endmethod

    method ActionValue#(Flit) getFlit;
        remainingFlits[1] <= remainingFlits[1] - 1;

        let flit = tempFifo.first;
        tempFifo.deq;
        
        return flit;
    endmethod
endmodule
