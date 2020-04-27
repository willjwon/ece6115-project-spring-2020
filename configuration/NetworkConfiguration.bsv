import Vector::*;


// Payload
typedef enum { Weight, InputActivation, OutputActivation } DataType deriving (Bits, Eq);
typedef Bit#(32) PayloadType;
typedef struct {
    DataType dataType;
    PayloadType payload;
} Data deriving (Bits, Eq);

// Mesh structure
typedef 3 MeshWidth;
typedef 3 MeshHeight;

// VC
typedef 2 VCsCount;
typedef 1 VCDepth;

// Routing
typedef enum { XY, YX } RoutingAlgorithms deriving (Bits, Eq);
RoutingAlgorithms currentRoutingAlgorithm = XY;

// Message
typedef 4 MessageLength;
