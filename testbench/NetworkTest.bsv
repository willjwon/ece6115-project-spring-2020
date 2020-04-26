import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;
import Connectable::*;
import NetworkConfiguration::*;
import TestbenchConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import Network::*;
import TrafficGeneratorUnit::*;
import TrafficGeneratorBuffer::*;
import CreditUnit::*;
import StatLogger::*;


(* synthesize *)
module mkNetworkTest();
    // UUT
    Network network <- mkNetwork;

    // Combinational logic
    Vector#(MeshHeight, Vector#(MeshWidth, CreditUnit)) creditUnits <- replicateM(replicateM(mkCreditUnit));
    Vector#(MeshHeight, Vector#(MeshWidth, TrafficGeneratorUnit)) trafficGeneratorUnits <- replicateM(replicateM(mkTrafficGeneratorUnit));
    Vector#(MeshHeight, Vector#(MeshWidth, TrafficGeneratorBuffer)) trafficGeneratorBufferUnits <- replicateM(replicateM(mkTrafficGeneratorBuffer));
    Vector#(MeshHeight, Vector#(MeshWidth, StatLogger)) statLoggers <- replicateM(replicateM(mkStatLogger));
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j < valueOf(MeshWidth); j = j + 1) begin
            mkConnection(creditUnits[i][j].getCredit, network.ingressPort[i][j].putCredit);
            mkConnection(network.egressPort[i][j].getCredit, trafficGeneratorUnits[i][j].putCredit);
        end
    end

    // Testbench
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);
    Reg#(Bit#(32)) initCount <- mkReg(0);
    
    // Run simulation
    rule runSimulation if (inited && cycle < maxCycle);
        cycle <= cycle + 1;

        if (cycle % 10000 == 0) begin
            $display("Testing: Cycle %d", cycle);
        end
    endrule

    rule finishSimulation if (inited && cycle >= maxCycle);
        $display("Finished: Cycle %d", cycle);
        
        Bit#(32) totalSent = 0;
        Bit#(32) totalReceived = 0;
        Bit#(32) totalHops = 0;
        Bit#(32) remainingFlits = 0;
        Bit#(32) totalInflightLatency = 0;
        Bit#(32) totalLatency = 0;

        for (Integer i=0; i<valueOf(MeshHeight); i=i+1) begin
            for (Integer j=0; j<valueOf(MeshWidth); j=j+1) begin
                let sentCount = statLoggers[i][j].getSentCount;
                let receivedCount = statLoggers[i][j].getReceivedCount;
                $display("(%d, %d): %d Sent, %d Received", i, j, sentCount, receivedCount);

                totalSent = totalSent + sentCount;
                totalReceived = totalReceived + receivedCount;
                totalLatency = totalLatency + statLoggers[i][j].getLatency;
                remainingFlits = remainingFlits + trafficGeneratorBufferUnits[i][j].remainingFlitsCount;
                totalHops = totalHops + statLoggers[i][j].getHops;
                totalInflightLatency = totalInflightLatency + statLoggers[i][j].getInflightLatency;

            end
        end
        
        $display("Total injected packet: %d", totalSent);
        $display("Total received packet: %d", totalReceived);
        $display("Total latency: %d", totalLatency);
        $display("Total hops: %d", totalHops);
        $display("Total inflight latency : %d", totalInflightLatency);
        $display("Generated but not injected flits: %d", remainingFlits);
        $finish(0);
    endrule

    // Initialize
    rule initialize if (!inited);
        if (initCount == 0) begin
            cycle <= 0;

            for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
                for (Integer j = 0; j < valueOf(MeshWidth); j = j + 1) begin
                    trafficGeneratorUnits[i][j].initialize(fromInteger(i), fromInteger(j));
                end
            end
        end

        initCount <= initCount + 1;
        if (network.initialized && initCount > fromInteger(valueOf(MeshHeight)) + fromInteger(valueOf(MeshWidth))) begin
            inited <= True;
        end 
    endrule

    // Generate flits
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j<valueOf(MeshWidth); j = j + 1) begin

            rule generateFlits if (inited);
                trafficGeneratorUnits[i][j].generateFlit(cycle);
            endrule

            rule prepareFlits if (inited);
                let flit <- trafficGeneratorUnits[i][j].getFlit;
                trafficGeneratorBufferUnits[i][j].putFlit(flit);
            endrule

            rule putFlit if (inited);
                let flit <- trafficGeneratorBufferUnits[i][j].getFlit;
                flit.stat.inflightCycle = cycle;

                network.ingressPort[i][j].putFlit(flit);
                statLoggers[i][j].countSend;
            endrule

            rule getFlit if (inited);
                let flit <- network.egressPort[i][j].getFlit;
                creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: True});

                statLoggers[i][j].countReceive;
            
                statLoggers[i][j].incrementLatency(cycle - flit.stat.injectedCycle);
                statLoggers[i][j].incrementInflightLatency(cycle - flit.stat.inflightCycle);
                statLoggers[i][j].incrementHops(flit.stat.hopCount);
            endrule
        end
    end
endmodule
