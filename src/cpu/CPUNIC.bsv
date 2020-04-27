import RoutingType::*;
import NetworkConfiguration::*;
import MessageType::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;


interface CPUNICControlPort;
    method Action initialize(XIdx xIdx, YIdx yIdx);
    method Bool initialized;
endinterface

interface CPUNICIngressPort;
    method Action putHead(Data data, XIdx xDest, YIdx yDest);
    method Action putBody(PayloadType payload);
    method Action putTail(PayloadType payload);
endinterface

interface CPUNICEgressPort;
    method ActionValue#(Flit) getFlit;
endinterface

interface CPUNIC;
    interface CPUNICControlPort controlPort;
    interface CPUNICIngressPort ingressPort;
    interface CPUNICEgressPort egressPort;
endinterface

(* synthesize *)
module mkCPUNIC(CPUNIC);
    // Submodule
    Reg#(Bool) inited <- mkReg(False);
    Reg#(Tuple2#(XIdx, YIdx)) index <- mkRegU;
    Reg#(Tuple3#(DataType, XIdx, YIdx)) header <- mkRegU; 
    FIFOF#(PayloadType) head <- mkPipelineFIFOF;
    FIFOF#(PayloadType) body <- mkPipelineFIFOF;
    FIFOF#(PayloadType) tail <- mkPipelineFIFOF;
    FIFO#(Flit) outFlit <- mkBypassFIFO;


    // Rule
    rule constructHeadFlit if (head.notEmpty && !body.notEmpty && !tail.notEmpty);
        head.deq;

        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Head;
        flit.data = Data{dataType: tpl_1(header), payload: head.first};

        let xIdx = tpl_1(index);
        let xDest = tpl_2(header);

        let yIdx = tpl_2(index);
        let yDest = tpl_3(header);

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

        outFlit.enq(flit);
    endrule

    rule constructBodyFlit if (!head.notEmpty && body.notEmpty && !tail.notEmpty);
        body.deq;

        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Body;
        flit.data = Data{dataType: tpl_1(header), payload: body.first};

        let xIdx = tpl_1(index);
        let xDest = tpl_2(header);

        let yIdx = tpl_2(index);
        let yDest = tpl_3(header);

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

        outFlit.enq(flit);
    endrule

    rule constructTailFlit if (!head.notEmpty && !body.notEmpty && tail.notEmpty);
        tail.deq;

        Flit flit = ?;

        flit.vc = 0;
        flit.flitType = Tail;
        flit.data = Data{dataType: tpl_1(header), payload: tail.first};

        let xIdx = tpl_1(index);
        let xDest = tpl_2(header);

        let yIdx = tpl_2(index);
        let yDest = tpl_3(header);

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

        outFlit.enq(flit);
    endrule


    // Interface
    interface controlPort = interface CPUNICControlPort
        method Bool initialized = inited;

        method Action initialize(XIdx xIdx, YIdx yIdx);
            index <= tuple2(xIdx, yIdx);
            inited <= True;
        endmethod
    endinterface;

    interface ingressPort = interface CPUNICIngressPort
        method Action putHead(Data data, XIdx xDest, YIdx yDest);
            header <= tuple3(data.dataType, xDest, yDest);
            head.enq(data.payload);
        endmethod

        method Action putBody(PayloadType payload);
            body.enq(payload);
        endmethod

        method Action putTail(PayloadType payload);
            tail.enq(payload);
        endmethod
    endinterface;

    interface egressPort = interface CPUNICEgressPort
        method ActionValue#(Flit) getFlit;
            outFlit.deq;
            return outFlit.first;
        endmethod
    endinterface;
endmodule
