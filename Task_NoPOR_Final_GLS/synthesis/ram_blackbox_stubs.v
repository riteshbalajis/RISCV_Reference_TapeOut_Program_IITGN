(* blackbox *) module RAM128(CLK, EN0, VGND, VPWR, A0, Di0, Do0, WE0);
input CLK, EN0, VGND, VPWR;
input [6:0] A0; input [31:0] Di0; input [3:0] WE0; output [31:0] Do0;
endmodule
(* blackbox *) module RAM256VPWR, VGND, CLK, WE0, EN0, A0, Di0, Do0);
inout VPWR, VGND; input CLK, EN0;
input [7:0] A0; input [31:0] Di0; input [3:0] WE0; output [31:0] Do0;
endmodule
