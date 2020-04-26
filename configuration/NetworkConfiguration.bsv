import Vector::*;


// Payload
typedef Bit#(32) Data;

// Mesh structure
typedef 4 MeshWidth;
typedef 4 MeshHeight;

// VC
typedef 2 VCsCount;
typedef 1 VCDepth;

// Routing
typedef enum { XY, YX } RoutingAlgorithms deriving (Bits, Eq);
RoutingAlgorithms currentRoutingAlgorithm = XY;
