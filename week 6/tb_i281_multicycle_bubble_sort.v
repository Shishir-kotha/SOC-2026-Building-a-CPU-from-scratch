`timescale 1ns/1ps
module tb_i281_multicycle_bubble_sort;
  reg clk=0, reset=1;
  wire [5:0] pc; wire [15:0] ir; wire [3:0] state,flags;
  wire [7:0] A,B,C,D; wire halted;

  i281_multicycle_cpu #(.IMEM_FILE("bubble_sort.mem")) dut(
    .clk(clk),.reset(reset),.pc_out(pc),.ir_out(ir),.state_out(state),
    .reg_a_out(A),.reg_b_out(B),.reg_c_out(C),.reg_d_out(D),
    .flags_out(flags),.halted(halted));

  always #5 clk=~clk;
  integer i,cycles;
  initial begin
    dut.dmem[0]=7; dut.dmem[1]=3; dut.dmem[2]=2; dut.dmem[3]=1;
    dut.dmem[4]=6; dut.dmem[5]=4; dut.dmem[6]=5; dut.dmem[7]=8;
    for(i=8;i<16;i=i+1) dut.dmem[i]=0;
    #12 reset=0; cycles=0;
    while(!halted && cycles<5000) begin @(posedge clk); #1; cycles=cycles+1; end
    $write("cycles=%0d data:",cycles);
    for(i=0;i<8;i=i+1) $write(" %0d",dut.dmem[i]);
    $display("");
    for(i=0;i<8;i=i+1) if(dut.dmem[i] !== i+1) begin
      $display("FAIL at address %0d",i); $finish;
    end
    if(!halted) begin $display("FAIL: timeout"); $finish; end
    $display("PASS: multicycle bubble sort completed"); $finish;
  end
endmodule
