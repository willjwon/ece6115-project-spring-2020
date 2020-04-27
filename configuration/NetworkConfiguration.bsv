import Vector::*;


// Payload
typedef enum { Weight, InputActivation, OutputActivation } DataType deriving (Bits, Eq);
typedef Bit#(32) PayloadType;
typedef struct {
    DataType dataType;
    PayloadType payload;
} Data deriving (Bits, Eq);

// Mesh structure
typedef 4 MeshWidth;
typedef 4 MeshHeight;

// VC
typedef 2 VCsCount;
typedef 1 VCDepth;

// Routing
typedef enum { XY, YX } RoutingAlgorithms deriving (Bits, Eq);
RoutingAlgorithms currentRoutingAlgorithm = XY;
