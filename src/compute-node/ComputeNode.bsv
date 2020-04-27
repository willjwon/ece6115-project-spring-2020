import NetworkConfiguration::*;
import MessageType::*;
import RoutingType::*;
import CreditType::*;
import FIFOF::*;
import SpecialFIFOs::*;
import SystolicArrayType::*;
import SystolicArray::*;
import Vector::*;
import MatrixArbiter::*;


interface ComputeNodeControlPort;
    method Action initialize(XIdx xIdx, YIdx yIdx);
endinterface

interface ComputeNodeIngressPort;
    method Action putFlit(Flit flit);
endinterface

interface ComputeNodeEgressPort;
    method ActionValue#(Flit) getFlit;
endinterface


interface ComputeNode;
    interface ComputeNodeControlPort controlPort;
    interface ComputeNodeIngressPort ingressPort;
    interface ComputeNodeEgressPort egressPort;
endinterface


(* synthesize *)
module mkComputeNode(ComputeNode);
    // Submodule
    FIFOF#(Flit) flitBuffer <- mkBypassFIFOF;
    SystolicArray#(2, 2, Bit#(32)) systolicArray <- mkSystolicArray;
    Reg#(Bit#(32)) currentIndex <- mkReg(0);
    Reg#(Bit#(32)) resultAddress <- mkRegU;
    Vector#(2, FIFOF#(Flit)) resultFlitBuffer <- replicateM(mkSizedFIFOF(2));
    let arbiter <- mkSystolicArrayArbiter;
    Reg#(Tuple2#(XIdx, YIdx)) index <- mkRegU;

    // Systolic Array setup
    for (Integer row = 0; row < 2; row = row + 1) begin
        rule discardRightmostValue;
            let discardValue <- systolicArray.east[row].get;
        endrule
    end

    // Rule
    rule receiveFlit;
        let flit = flitBuffer.first;
        flitBuffer.deq;

        if (flit.flitType == Head) begin
            if (flit.data.dataType == Weight) begin
                systolicArray.control.setStateTo(Load);
            end else if (flit.data.dataType == InputActivation) begin
                resultAddress <= flit.data.payload;
                systolicArray.control.setStateTo(Compute);
            end
        end else begin
            if (flit.data.dataType == Weight) begin
                systolicArray.north[currentIndex].put(flit.data.payload);
            end else if (flit.data.dataType == InputActivation) begin
                systolicArray.west[currentIndex].put(flit.data.payload);
                systolicArray.north[currentIndex].put(0);
            end
        end

        if (currentIndex >= 1) begin
            currentIndex <= 0;
        end else begin
            currentIndex <= currentIndex + 1;
        end
    endrule

    for (Integer i = 0; i < 2; i = i + 1) begin
        rule generateFlit;
            let southResult <- systolicArray.south[i].get;

            Flit flit = ?;

            flit.vc = 1;
            flit.flitType = HeadTail;
            flit.data = Data{dataType: OutputActivation, payload: southResult};

            let xIdx = tpl_1(index);
            let xDest = 1;

            let yIdx = tpl_2(index);
            let yDest = 1;

            flit.routeInfo.dirX = (xDest > xIdx) ? WestToEast : EastToWest;
            XIdx xHops = (xDest > xIdx)? (xDest-xIdx) : (xIdx-xDest);
            flit.routeInfo.xHops = xHops;

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

            resultFlitBuffer[i].enq(flit);
        endrule
    end


    // Interface
    interface controlPort = interface ComputeNodeControlPort
        method Action initialize(XIdx xIdx, YIdx yIdx);
            index <= tuple2(xIdx, yIdx);
        endmethod
    endinterface;

    interface ingressPort = interface ComputeNodeIngressPort
        method Action putFlit(Flit flit);
            flitBuffer.enq(flit);
        endmethod
    endinterface;

    interface egressPort = interface ComputeNodeEgressPort
        method ActionValue#(Flit) getFlit if (resultFlitBuffer[0].notEmpty || resultFlitBuffer[1].notEmpty);
            if (resultFlitBuffer[0].notEmpty) begin
                resultFlitBuffer[0].deq;
                return resultFlitBuffer[0].first;
            end else begin
                resultFlitBuffer[1].deq;
                return resultFlitBuffer[1].first;
            end
        endmethod
    endinterface;
endmodule
