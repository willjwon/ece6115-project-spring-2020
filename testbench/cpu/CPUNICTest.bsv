import CPUNIC::*;
import TestbenchConfiguration::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;


(* synthesize *)
module mkCPUNICTest();
    // uut
    let nic <- mkCPUNIC;

    // Testbench Environment
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);

    // Initialize
    rule initialize if (!inited);
        nic.controlPort.initialize(1, 1);
        inited <= nic.controlPort.initialized;
    endrule


    // Run Testbench
    rule runTestbench if (inited && (cycle < maxCycle));
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (inited && (cycle >= maxCycle));
        $display("[Finish] Cycle %d reached.", maxCycle);
        $finish(0);
    endrule


    // Test cases
    rule putFlit1 if (inited && (cycle == 0));
        nic.ingressPort.putHead(Data{dataType: Weight, payload: 3}, 0, 0);
    endrule

    rule putFlit2 if (inited && (cycle == 1));
        nic.ingressPort.putBody(1);
    endrule

    rule putFlit3 if (inited && (cycle == 2));
        nic.ingressPort.putBody(2);
    endrule

    rule putFlit4 if (inited && (cycle == 3));
        nic.ingressPort.putTail(3);
    endrule

    rule printFlit;
        let flit <- nic.egressPort.getFlit;
        $display("Received: (%d) (%d, %d) (%d, %d)", flit.flitType, flit.data.dataType, flit.data.payload, flit.routeInfo.xHops, flit.routeInfo.yHops);
    endrule
endmodule
