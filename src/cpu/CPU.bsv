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
    RWire#(Bool) canSend <- mkRWire;
    Reg#(Bit#(32)) sendReg <- mkReg(fromInteger(valueOf(MessageLength)));


    // Rule
    rule incrementSendReg;
        if (isValid(startSignal.wget)) begin
            sendReg <= 0;    
        end else if (sendReg >= fromInteger(valueOf(MessageLength))) begin
            sendReg <= fromInteger(valueOf(MessageLength));
        end else if (isValid(canSend.wget)) begin
            sendReg <= sendReg + 1;
        end
    endrule

    rule sendBody if (isValid(canSend.wget) && !isValid(startSignal.wget) && (sendReg < fromInteger(valueOf(MessageLength) - 1)));
        nic.ingressPort.putBody(sendReg);
    endrule

    rule sendTail if (isValid(canSend.wget) && !isValid(startSignal.wget) && (sendReg == fromInteger(valueOf(MessageLength) - 1)));
        nic.ingressPort.putTail(sendReg);
    endrule

    
    // Interface
    interface controlPort = interface CPUControlPort
        method Bool initialized = nic.controlPort.initialized;

        method Action initialize(XIdx xIdx, YIdx yIdx);
            nic.controlPort.initialize(xIdx, yIdx);
        endmethod

        method Action startSend(Data data, XIdx xDest, YIdx yDest) if (sendReg == fromInteger(valueOf(MessageLength)));
            nic.ingressPort.putHead(data, xDest, yDest);
            startSignal.wset(True);
        endmethod
    endinterface;

    interface ingressPort = interface CPUIngressPort
        method Action putCredit(CreditSignal creditSignal);
            canSend.wset(True);
        endmethod
    endinterface;

    interface egressPort = interface CPUEgressPort
        method ActionValue#(Flit) getFlit;
            let flit <- nic.egressPort.getFlit;
            return flit;
        endmethod
    endinterface;
endmodule
