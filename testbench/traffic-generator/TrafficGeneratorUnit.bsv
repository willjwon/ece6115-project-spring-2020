import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import NetworkConfiguration::*;
import TestbenchConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import TrafficGenerator::*;
import VCAllocationUnit::*;


interface TrafficGeneratorUnit;
    method Action initialize(YIdx yID, XIdx xID);
    method Action generateFlit(Bit#(32) currentClock);
    method ActionValue#(Flit) getFlit;
    method Action putCredit(CreditSignal creditSignal);
endinterface


(* synthesize *)
module mkTrafficGeneratorUnit(TrafficGeneratorUnit);
    // Submodule
    VCAllocationUnit vcAllocationUnit <- mkVCAllocationUnit;
    TrafficGenerator trafficGenerator <- mkUnifornRandomTrafficGenerator;

    FIFOF#(Flit) generatedFlit <- mkSizedBypassFIFOF(valueOf(TrafficGeneratorSlotsCount));
    FIFO#(Flit) resultFlit <- mkBypassFIFO;


    // Rule
    rule assignVC;
        let flit = generatedFlit.first;
        generatedFlit.deq;

        let vc <- vcAllocationUnit.getFreeVC;

        flit.vc = vc;
        resultFlit.enq(flit);
    endrule


    // Interface
    method Action initialize(YIdx yID, XIdx xID);
        trafficGenerator.initialize(yID, xID);
    endmethod

    method Action generateFlit(Bit#(32) currentClock);
        let flit <- trafficGenerator.getFlit;
        flit.stat.injectedCycle = currentClock;
        generatedFlit.enq(flit);
    endmethod

    method ActionValue#(Flit) getFlit;
        resultFlit.deq;
        return resultFlit.first;
    endmethod

    method Action putCredit(CreditSignal creditSignal);
        if (creditSignal matches tagged Valid .credit) begin
            vcAllocationUnit.putFreeVC(credit.vc);
        end
    endmethod
endmodule
