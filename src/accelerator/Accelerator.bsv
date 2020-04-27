import Vector::*;
import Network::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import CreditUnit::*;
import Connectable::*;
import CPU::*;
import Compute::*;


interface AcceleratorControlPort;
    method Bool initialized;
endinterface


interface Accelerator;
    interface AcceleratorControlPort controlPort;
endinterface


(* synthesize *)
module mkAccelerator(Accelerator);
    // Submodule
    let network <- mkNetwork;
    let cpu <- mkCPU;
    // Vector#(MeshHeight, Vector#(MeshWidth, Compute)) computeNodes <- replicateM(replicateM(mkCompute));

    Reg#(Bool) inited <- mkReg(False);
    Reg#(Bit#(32)) sendReg <- mkReg(0);
    Reg#(Bool) sendWeight <- mkReg(True);
    Reg#(Bool) sendInputActivation <- mkReg(False);
    Reg#(XIdx) xLoc <- mkReg(0);
    Reg#(YIdx) yLoc <- mkReg(0);

    rule incrementSendReg if (inited);
        sendReg <= sendReg + 1;
    endrule

    rule sendWeights if (inited && sendWeight && !sendInputActivation && (sendReg % 50 == 0));
        // start sending weight
        cpu.controlPort.startSend(Data{dataType: Weight, payload: 77}, xLoc, yLoc);
        
        // lookahead next location
        if (xLoc == 2) begin
            xLoc <= 0;

            if (yLoc == 2) begin
                yLoc <= 0;
                sendWeight <= False;
                sendInputActivation <= True;
            end else begin
                yLoc <= yLoc + 1;
            end 
        end else begin
            if (yLoc == 1) begin
                xLoc <= xLoc + 2;
            end else begin
                xLoc <= xLoc + 1;
            end
        end
    endrule

    rule sendInputActivations if (inited && !sendWeight && sendInputActivation && (sendReg % 50 == 0));
        // start sending weight
        cpu.controlPort.startSend(Data{dataType: InputActivation, payload: 77}, xLoc, yLoc);
        
        // lookahead next location
        if (xLoc == 2) begin
            xLoc <= 0;

            if (yLoc == 2) begin
                yLoc <= 0;
                sendInputActivation <= False;
            end else begin
                yLoc <= yLoc + 1;
            end 
        end else begin
            if (yLoc == 1) begin
                xLoc <= xLoc + 2;
            end else begin
                xLoc <= xLoc + 1;
            end
        end
    endrule

    // Initialize
    rule initialize if (!inited);
        cpu.controlPort.initialize(1, 1);
        inited <= cpu.controlPort.initialized;
    endrule

    // Combinational logic
    Vector#(MeshHeight, Vector#(MeshWidth, CreditUnit)) creditUnits <- replicateM(replicateM(mkCreditUnit));
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j < valueOf(MeshWidth); j = j + 1) begin
            mkConnection(creditUnits[i][j].getCredit, network.ingressPort[i][j].putCredit);
        end
    end

    // Get flit
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j<valueOf(MeshWidth); j = j + 1) begin
            if (i == 1 && j == 1) begin
                // CPU
                rule getFlit if (inited);
                    let flit <- network.egressPort[i][j].getFlit;
                    // cpu.ingressPort.putFlit(flit);

                    if (flit.flitType == Tail || flit.flitType == HeadTail) begin
                        creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: True});
                    end else begin
                        creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: False});
                    end        
                endrule
            end else begin
                let compute <- mkCompute;

                rule getFlit if (inited);
                    let flit <- network.egressPort[i][j].getFlit;
                    compute.ingressPort.putFlit(flit);

                    if (flit.flitType == Tail || flit.flitType == HeadTail) begin
                        creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: True});
                    end else begin
                        creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: False});
                    end        
                endrule
            end
        end
    end

    mkConnection(cpu.egressPort.getFlit, network.ingressPort[1][1].putFlit);
    mkConnection(network.egressPort[1][1].getCredit, cpu.ingressPort.putCredit);

    // Interface
    interface controlPort = interface AcceleratorControlPort
        method Bool initialized;
            return inited;
        endmethod
    endinterface;
endmodule
