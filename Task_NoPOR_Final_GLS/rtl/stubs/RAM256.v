(* blackbox *)

module RAM256 #(parameter   USE_LATCH=1,
                            WSIZE=4 ) 
(
    inout VPWR,	 
    
    input   wire                CLK,    // FO: 2
    input   wire [WSIZE-1:0]     WE0,     // FO: 2
    input                        EN0,     // FO: 2
    input   wire [7:0]           A0,      // FO: 5
    input   wire [(WSIZE*8-1):0] Di0,     // FO: 2
    output  wire [(WSIZE*8-1):0] Do0

);


endmodule
