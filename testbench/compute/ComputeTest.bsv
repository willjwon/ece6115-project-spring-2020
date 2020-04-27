import Compute::*;
import TestbenchConfiguration::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;


(* synthesize *)
module mkComputeTest();
    // uut
    let compute <- mkCompute;

    // Testbench Environment
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);

    // Run Testbench
    rule runTestbench if (inited && (cycle < maxCycle));
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (inited && (cycle >= maxCycle));
        $display("[Finish] Cycle %d reached.", maxCycle);
        $finish(0);
    endrule
endmodule
