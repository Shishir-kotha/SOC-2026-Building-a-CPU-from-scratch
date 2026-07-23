`timescale 1ns/1ps
module tb_i281_bubble_sort;
 reg clk=0, reset=1; reg [15:0] switches=0;
 wire [5:0] pc; wire [15:0] insn; wire [7:0] A,B,C,D; wire [3:0] flags; wire halted;
 i281_cpu #(.IMEM_FILE("bubble_sort.mem")) dut(
   .clk(clk),.reset(reset),.switches(switches),.pc_out(pc),.instruction_out(insn),
   .reg_a_out(A),.reg_b_out(B),.reg_c_out(C),.reg_d_out(D),.flags_out(flags),.halted(halted));
 always #5 clk=~clk;
 integer i, cycles;
 initial begin
   // Data from the architecture PDF's bubble-sort example.
   dut.dmem[0]=8'd7; dut.dmem[1]=8'd3; dut.dmem[2]=8'd2; dut.dmem[3]=8'd1;
   dut.dmem[4]=8'd6; dut.dmem[5]=8'd4; dut.dmem[6]=8'd5; dut.dmem[7]=8'd8;
   for(i=8;i<16;i=i+1) dut.dmem[i]=0;
   #12 reset=0;
   cycles=0;
   while(!halted && cycles<2000) begin @(posedge clk); #1; cycles=cycles+1; end
   $write("cycles=%0d data:",cycles);
   for(i=0;i<8;i=i+1) $write(" %0d",dut.dmem[i]);
   $display("");
   for(i=0;i<8;i=i+1)
     if(dut.dmem[i] !== i+1) begin $display("FAIL at %0d",i); $finish; end
   if(!halted) begin $display("FAIL timeout"); $finish; end
   $display("PASS: bubble sort completed"); $finish;
 end
endmodule
