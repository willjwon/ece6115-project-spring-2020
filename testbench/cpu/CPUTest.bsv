import CPU::*;
import TestbenchConfiguration::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;


(* synthesize *)
module mkCPUTest();
    // uut
    let cpu <- mkCPU;

    // Testbench Environment
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);

    // Initialize
    rule initialize if (!inited);
        cpu.controlPort.initialize(1, 1);
        inited <= cpu.controlPort.initialized;
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
    rule start if (inited && (cycle == 0));
        cpu.controlPort.startSend(Data{dataType: InputActivation, payload: 7}, 2, 1);
    endrule


    rule printFlit if (inited);
        let flit <- cpu.egressPort.getFlit;
        $display("Received: (%d) (%d, %d) (%d, %d)", flit.flitType, flit.data.dataType, flit.data.payload, flit.routeInfo.xHops, flit.routeInfo.yHops);
    endrule
endmodule
