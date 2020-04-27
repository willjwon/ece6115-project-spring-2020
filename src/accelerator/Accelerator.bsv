import Network::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import CreditUnit::*;


interface Accelerator;

endinterface


(* synthesize *)
module mkAccelerator(Accelerator);
    // Submodule
    Network network <- mkNetwork;

    // Combinational logic
    Vector#(MeshHeight, Vector#(MeshWidth, CreditUnit)) creditUnits <- replicateM(replicateM(mkCreditUnit));
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j < valueOf(MeshWidth); j = j + 1) begin
            mkConnection(creditUnits[i][j].getCredit, network.ingressPort[i][j].putCredit);
        end
    end
    

endmodule


(* synthesize *)
module mkMultiFlitTest();

    

    // Testbench
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);
    
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
                totalHops = totalHops + statLoggers[i][j].getHops;
                totalInflightLatency = totalInflightLatency + statLoggers[i][j].getInflightLatency;

            end
        end
        
        $display("Total injected packet: %d", totalSent);
        $display("Total received packet: %d", totalReceived);
        $display("Total latency: %d", totalLatency);
        $display("Total hops: %d", totalHops);
        $display("Total inflight latency : %d", totalInflightLatency);
        $finish(0);
    endrule

    // Test cases
    rule putFlit3 if (inited && cycle == 3);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Head;
        flit.data = 3;

        flit.routeInfo.nextPortOneHot = eastOneHot;
        flit.routeInfo.dirX = WestToEast;
        flit.routeInfo.xHops = 2;
        flit.routeInfo.dirY = NorthToSouth;
        flit.routeInfo.yHops = 1;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit4 if (inited && cycle == 4);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 4;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit5 if (inited && cycle == 5);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 5;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit6 if (inited && cycle == 6);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 6;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit7 if (inited && cycle == 7);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 7;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit8 if (inited && cycle == 8);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 8;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule

    rule putFlit9 if (inited && cycle == 9);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = 9;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule


    rule putFlit10 if (inited && cycle == 10);
        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Tail;
        flit.data = 10;

        flit.stat.hopCount = 0;
        flit.stat.injectedCycle = cycle;
        flit.stat.inflightCycle = cycle;
        flit.stat.destX = 2;
        flit.stat.destY = 1;
        flit.stat.srcX = 0;
        flit.stat.srcY = 0;

        network.ingressPort[0][0].putFlit(flit);
        let credit <- network.egressPort[0][0].getCredit;

        statLoggers[0][0].countSend;
    endrule


    // Initialize
    rule initialize if (!inited);
        cycle <= 0;
        inited <= network.initialized;
    endrule

    // Credit process
    for (Integer i = 0; i < valueOf(MeshHeight); i = i + 1) begin
        for (Integer j = 0; j<valueOf(MeshWidth); j = j + 1) begin
            rule getFlit if (inited);
                let flit <- network.egressPort[i][j].getFlit;
                $display("(%d, %d) received flit, payload: %d", i, j, flit.data);

                if (flit.flitType == Tail || flit.flitType == HeadTail) begin
                    creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: True});
                end else begin
                    creditUnits[i][j].putCredit(tagged Valid CreditSignal_{vc: flit.vc, isTailFlit: False});
                end

                statLoggers[i][j].countReceive;
            
                statLoggers[i][j].incrementLatency(cycle - flit.stat.injectedCycle);
                statLoggers[i][j].incrementInflightLatency(cycle - flit.stat.inflightCycle);
                statLoggers[i][j].incrementHops(flit.stat.hopCount);
            endrule
        end
    end
endmodule
