import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;


typedef Bit#(32) StatData;


interface StatLogger;
    method Action countSend;
    method Action countReceive;
    method Action incrementLatency(StatData newLatency);
    method Action incrementHops(StatData newHops);
    method Action incrementInflightLatency(StatData newInflightLatency);
    method StatData getSentCount;
    method StatData getReceivedCount;
    method StatData getLatency;
    method StatData getHops;
    method StatData getInflightLatency;
endinterface


(* synthesize *)
module mkStatLogger(StatLogger);
    // Submodule
    Reg#(StatData) sentCount <- mkReg(0);
    Reg#(StatData) receivedCount <- mkReg(0);
    Reg#(StatData) latency <- mkReg(0);
    Reg#(StatData) hops <- mkReg(0);
    Reg#(StatData) inflightLatency <- mkReg(0);


    // Interface
    method Action countSend;
        sentCount <= sentCount + 1;
    endmethod

    method Action countReceive;
        receivedCount <= receivedCount + 1;
    endmethod

    method Action incrementLatency(StatData newLatency); 
        latency <= latency + newLatency;
    endmethod

    method Action incrementHops(StatData newHops);
        hops <= hops + newHops;
    endmethod

    method Action incrementInflightLatency(StatData newInflightLatency); 
        inflightLatency <= inflightLatency + newInflightLatency;
    endmethod

    method StatData getSentCount = sentCount;
    method StatData getReceivedCount = receivedCount;
    method StatData getLatency = latency;
    method StatData getHops = hops;
    method StatData getInflightLatency = inflightLatency;
endmodule
