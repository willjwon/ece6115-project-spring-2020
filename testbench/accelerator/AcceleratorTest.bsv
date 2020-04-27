import TestbenchConfiguration::*;
import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import Accelerator::*;


(* synthesize *)
module mkAcceleratorTest();
    // uut
    let accelerator <- mkAccelerator;

    // Testbench Environment
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Reg#(Bool) inited <- mkReg(False);

    // Initialize
    rule initialize if (!inited);
        inited <= accelerator.controlPort.initialized;
    endrule


    // Run Testbench
    rule runTestbench if (inited && (cycle < maxCycle));
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (inited && (cycle >= maxCycle));
        $display("[Finish] Cycle %d reached.", maxCycle);
        $finish(0);
    endrule
endmodule
