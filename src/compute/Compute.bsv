
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import FIFOF::*;
import SpecialFIFOs::*;


interface ComputeIngressPort;
    method Action putFlit(Flit flit);
endinterface

// interface ComputeEgressPort;
// endinterface


interface Compute;
    interface ComputeIngressPort ingressPort;
endinterface


(* synthesize *)
module mkCompute(Compute);
    // Submodule
    FIFOF#(Flit) flitBuffer <- mkBypassFIFOF;

    // Rule
    rule get;
        let flit = flitBuffer.first;
        flitBuffer.deq;

        $display("compute received (type: %d, payload: %d)", flit.data.dataType, flit.data.payload);
    endrule

    // Interface
    interface ingressPort = interface ComputeIngressPort
        method Action putFlit(Flit flit);
            flitBuffer.enq(flit);
        endmethod
    endinterface;
endmodule
