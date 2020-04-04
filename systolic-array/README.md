<!-- MIT License

Copyright (c) 2020 William Won (william.won@gatech.edu)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. -->

# SystolicArray
SystolicArray implementation using Bluespec System Verilog

## Import
```bluespec
import SystolicArrayType::*;
import SystolicArray::*;
```

## Instantiation and Setup
```bluespec
// SystolicArray(Size, DataType)
SystolicArray#(8, Bits#(32)) systolicArray <- mkSystolicArray;  // 8x8 SystolicArray using 32-bit Integer
```

Should discard rightmost value.
```bluespec
for (Integer i = 0; i < 8; i = i + 1) begin
    rule discardRightmostValues;
        let unusedValue <- systolicArray.east[i].get;
    endrule
end
```

## Loading Weight
```bluespec
systolicArray.control.setStateTo(Load);  // Takes 1 cycle

// 1 cycle later, put weights using north port
for (Integer i = 0; i < 8; i = i + 1) begin
    systolicArray.north[i].put(1);
end
```

## Compute
```bluespec
systolicArray.control.setStateTo(Compute);  // Takes 1 cycle

// 1 cycle later: put inputActivation to west[0], put initial psum to north ports
systolicArray.west[0].put(3);
for (Integer i = 0; i < 8; i = i + 1) begin
    systolicArray.north[i].put(0);
end

// following cycles: put inputActivation to west[1], west[2], ...
// 1 cycle later
systolicArray.west[1].put(2);

// 1 cycle later
systolicArray.west[2].put(3);

...
systolicArray.west[7].put(3);

// 1 cycle later
systolicArray.west[0].put(5);
for (Integer i = 0; i < 8; i = i + 1) begin
    systolicArray.north[i].put(0);
end
```

## Get result
```bluespec
for (Integer i = 0; i < 8; i = i + 1) begin
    let result <- systolicArray.south[i].get;
end
```

## Reset
```bluespec
systolicArray.control.setStateTo(Reset);
```
