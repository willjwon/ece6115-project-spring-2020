import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;
import Randomizable::*;
import NetworkConfiguration::*;
import TestbenchConfiguration::*;
import MessageType::*;
import RoutingType::*;


interface TrafficGenerator;
    method Action initialize(YIdx yID, XIdx xID);
    method ActionValue#(Flit) getFlit;
endinterface


(* synthesize *)
module mkUnifornRandomTrafficGenerator(TrafficGenerator);
    // Submodule
    Randomize#(XIdx) xRandomizer <- mkConstrainedRandomizer(0, fromInteger(valueOf(MeshWidth) - 1));
    Randomize#(YIdx) yRandomizer <- mkConstrainedRandomizer(0, fromInteger(valueOf(MeshHeight) - 1));
    Randomize#(Bit#(32)) injectionRandomizer <- mkConstrainedRandomizer(0, 99); 

    Reg#(XIdx) xIdx <- mkRegU;
    Reg#(YIdx) yIdx <- mkRegU;
    
    FIFO#(Flit) resultFlit <- mkBypassFIFO;

    Reg#(Bool) inited <- mkReg(False);
    Reg#(Bool) startInit <- mkReg(False);
    Reg#(Bit#(32)) initReg <- mkReg(0);


    // Rule
    rule doInitialize if (!inited && startInit);
        if (initReg == 0) begin
            yRandomizer.cntrl.init;
            xRandomizer.cntrl.init;
            injectionRandomizer.cntrl.init;
        end else if (initReg < zeroExtend(xIdx) + zeroExtend(yIdx)) begin
            let injRnd <- injectionRandomizer.next;
            let wRnd <- xRandomizer.next;
            let hRnd <- yRandomizer.next;
        end else begin
            inited <= True;
        end
        
        initReg <= initReg + 1;
    endrule

    rule generateFlit if (inited);
        let injectionProb <- injectionRandomizer.next;
        if (injectionProb < fromInteger(valueOf(InjectionRate))) begin
            Flit flit = ?;
		
            flit.vc = 0;

            let xDest <- xRandomizer.next;
            flit.routeInfo.dirX = (xDest > xIdx) ? WestToEast : EastToWest;
            XIdx xHops = (xDest > xIdx)? (xDest-xIdx) : (xIdx-xDest);
            flit.routeInfo.xHops = xHops;

            let yDest <- yRandomizer.next;
            flit.routeInfo.dirY = (yDest > yIdx)? NorthToSouth : SouthToNorth;
            YIdx yHops = (yDest > yIdx)? (yDest-yIdx) : (yIdx-yDest);
            flit.routeInfo.yHops = yHops;

            case (currentRoutingAlgorithm)
            XY: begin
                if (xDest != xIdx) begin
                    flit.routeInfo.nextPortOneHot = (xDest > xIdx) ? eastOneHot : westOneHot;
                end else if (yDest != yIdx) begin
                    flit.routeInfo.nextPortOneHot = (yDest > yIdx) ? southOneHot : northOneHot;
                end else begin
                    flit.routeInfo.nextPortOneHot = localOneHot;
                end
            end

            YX: begin
                if (yDest != yIdx) begin
                    flit.routeInfo.nextPortOneHot = (yDest > yIdx) ? southOneHot : northOneHot;
                end else if (xDest != xIdx) begin
                    flit.routeInfo.nextPortOneHot = (xDest > xIdx) ? eastOneHot : westOneHot;
                end else begin
                    flit.routeInfo.nextPortOneHot = localOneHot;
                end
            end
            endcase

            flit.flitType = HeadTail; 

            flit.stat.hopCount = 0;
            flit.stat.destX = xDest;
            flit.stat.destY = yDest;
            flit.stat.srcX = xIdx;
            flit.stat.srcY = yIdx;

            if (flit.routeInfo.nextPortOneHot != localOneHot) begin
                resultFlit.enq(flit);
            end
        end
    endrule


    // Interface
    method Action initialize(YIdx yID, XIdx xID) if (!inited && !startInit);
        yIdx <= yID;
        xIdx <= xID;

        startInit <= True;
    endmethod

    method ActionValue#(Flit) getFlit if (inited);
        resultFlit.deq;
        return resultFlit.first;
    endmethod
endmodule
