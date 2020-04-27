import CreditType::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CPUNIC::*;
import RWire::*;


interface CPUControlPort;
    method Action initialize(XIdx xIdx, YIdx yIdx);
    method Bool initialized;
    method Action startSend(Data data, XIdx xDest, YIdx yDest);
endinterface

interface CPUIngressPort;
    method Action putCredit(CreditSignal creditSignal);
endinterface

interface CPUEgressPort;
    method ActionValue#(Flit) getFlit;
endinterface

interface CPU;
    interface CPUControlPort controlPort;
    interface CPUIngressPort ingressPort;
    interface CPUEgressPort egressPort;
endinterface


(* synthesize *)
module mkCPU(CPU);
    // Submodule
    let nic <- mkCPUNIC;
    RWire#(Bool) startSignal <- mkRWire;
    Reg#(Bit#(32)) sendReg <- mkReg(5);


    // Rule
    rule incrementSendReg;
        if (isValid(startSignal.wget)) begin
            sendReg <= 0;    
        end else if (sendReg >= 4) begin
            sendReg <= 4;
        end else begin
            sendReg <= sendReg + 1;
        end
    endrule

    rule sendBody if (!isValid(startSignal.wget) && (sendReg < 3));
        nic.ingressPort.putBody(sendReg);
    endrule

    rule sendTail if (!isValid(startSignal.wget) && (sendReg == 3));
        nic.ingressPort.putTail(3);
    endrule

    
    // Interface
    interface controlPort = interface CPUControlPort
        method Bool initialized = nic.controlPort.initialized;

        method Action initialize(XIdx xIdx, YIdx yIdx);
            nic.controlPort.initialize(xIdx, yIdx);
        endmethod

        method Action startSend(Data data, XIdx xDest, YIdx yDest);
            nic.ingressPort.putHead(data, xDest, yDest);
            startSignal.wset(True);
        endmethod


    endinterface;

    interface ingressPort = interface CPUIngressPort
        method Action putCredit(CreditSignal creditSignal);
            noAction;
        endmethod
    endinterface;

    interface egressPort = interface CPUEgressPort
        method ActionValue#(Flit) getFlit;
            let flit <- nic.egressPort.getFlit;
            return flit;
        endmethod
    endinterface;
endmodule
