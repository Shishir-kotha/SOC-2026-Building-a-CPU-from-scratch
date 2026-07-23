`timescale 1ns/1ps

// Instruction: [15:12]=opcode, [11:10]=RX, [9:8]=RY, [7:0]=value/address/PC offset.
module i281_cpu #(
    parameter IMEM_FILE = "bubble_sort.mem"
) (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] switches,
    output wire [5:0]  pc_out,
    output wire [15:0] instruction_out,
    output wire [7:0]  reg_a_out,
    output wire [7:0]  reg_b_out,
    output wire [7:0]  reg_c_out,
    output wire [7:0]  reg_d_out,
    output wire [3:0]  flags_out,
    output wire        halted
);
    localparam [1:0] RA=2'b00, RB=2'b01, RC=2'b10, RD=2'b11;

    reg [5:0] pc;
    reg [15:0] imem [0:63];
    reg [7:0] dmem [0:15];
    reg [7:0] regs [0:3];
    // flags = {OF,NF,ZF,CF}; comparisons use signed overflow-corrected relations.
    reg OF, NF, ZF, CF;

    wire [15:0] insn = imem[pc];
    wire [3:0] op = insn[15:12];
    wire [1:0] rx = insn[11:10];
    wire [1:0] ry = insn[9:8];
    wire [7:0] imm = insn[7:0];
    wire signed [6:0] pc_offset = {{1{imm[5]}},imm[5:0]};

    reg [7:0] result;
    reg [8:0] wide;
    reg next_OF, next_NF, next_ZF, next_CF;
    reg [5:0] next_pc;
    reg reg_we, flag_we, dmem_we, imem_we;
    reg [1:0] reg_waddr;
    reg [7:0] dmem_wdata;
    reg [3:0] dmem_addr;
    reg [5:0] imem_addr;
    reg [15:0] imem_wdata;
    reg halt_r;

    integer i;
    initial begin
        for (i=0;i<64;i=i+1) imem[i]=16'h0000;
        if (IMEM_FILE != "") $readmemh(IMEM_FILE, imem);
    end

    // Complete combinational datapath and control. Normal instructions advance PC by one.
    always @* begin
        result=8'h00; wide=9'h000;
        next_OF=OF; next_NF=NF; next_ZF=ZF; next_CF=CF;
        next_pc=pc+6'd1;
        reg_we=1'b0; flag_we=1'b0; dmem_we=1'b0; imem_we=1'b0;
        reg_waddr=rx; dmem_wdata=8'h00; dmem_addr=imm[3:0];
        imem_addr=imm[5:0]; imem_wdata=switches;
        halt_r=1'b0;

        case (op)
          4'h0: begin // NOOP. 0000 at address 63 is also a convenient terminal loop.
              if (pc==6'h3f) begin next_pc=pc; halt_r=1'b1; end
          end
          4'h1: begin // INPUT group: 00 C, 01 CF, 10 D, 11 DF
              case (ry)
                2'b00: begin imem_we=1'b1; imem_addr=imm[5:0]; end
                2'b01: begin imem_we=1'b1; imem_addr=regs[rx][5:0]+imm[5:0]; end
                2'b10: begin dmem_we=1'b1; dmem_addr=imm[3:0]; dmem_wdata=switches[7:0]; end
                2'b11: begin dmem_we=1'b1; dmem_addr=regs[rx][3:0]+imm[3:0]; dmem_wdata=switches[7:0]; end
              endcase
          end
          4'h2: begin result=regs[ry]; reg_we=1'b1; end                    // MOVE RX,RY
          4'h3: begin result=imm; reg_we=1'b1; end                         // LOADI/LOADP RX,imm
          4'h4: begin                                                       // ADD RX,RY
              wide={1'b0,regs[rx]}+{1'b0,regs[ry]}; result=wide[7:0]; reg_we=1'b1; flag_we=1'b1;
              next_CF=wide[8]; next_ZF=(result==0); next_NF=result[7];
              next_OF=(~(regs[rx][7]^regs[ry][7])) & (result[7]^regs[rx][7]);
          end
          4'h5: begin                                                       // ADDI RX,imm
              wide={1'b0,regs[rx]}+{1'b0,imm}; result=wide[7:0]; reg_we=1'b1; flag_we=1'b1;
              next_CF=wide[8]; next_ZF=(result==0); next_NF=result[7];
              next_OF=(~(regs[rx][7]^imm[7])) & (result[7]^regs[rx][7]);
          end
          4'h6: begin                                                       // SUB RX,RY
              wide={1'b0,regs[rx]}-{1'b0,regs[ry]}; result=wide[7:0]; reg_we=1'b1; flag_we=1'b1;
              next_CF=~wide[8]; next_ZF=(result==0); next_NF=result[7];
              next_OF=(regs[rx][7]^regs[ry][7]) & (result[7]^regs[rx][7]);
          end
          4'h7: begin                                                       // SUBI RX,imm
              wide={1'b0,regs[rx]}-{1'b0,imm}; result=wide[7:0]; reg_we=1'b1; flag_we=1'b1;
              next_CF=~wide[8]; next_ZF=(result==0); next_NF=result[7];
              next_OF=(regs[rx][7]^imm[7]) & (result[7]^regs[rx][7]);
          end
          4'h8: begin result=dmem[imm[3:0]]; reg_we=1'b1; end               // LOAD RX,[addr]
          4'h9: begin result=dmem[regs[ry][3:0]+imm[3:0]]; reg_we=1'b1; end // LOADF RX,[RY+off]
          4'hA: begin dmem_we=1'b1; dmem_addr=imm[3:0]; dmem_wdata=regs[rx]; end // STORE RX,[addr]
          4'hB: begin dmem_we=1'b1; dmem_addr=regs[ry][3:0]+imm[3:0]; dmem_wdata=regs[rx]; end // STOREF RX,[RY+off]
          4'hC: begin                                                       // SHIFT: I8=0 left, I8=1 right
              if (!insn[8]) begin result=regs[rx]<<1; next_CF=regs[rx][7]; end
              else begin result=regs[rx]>>1; next_CF=regs[rx][0]; end
              reg_we=1'b1; flag_we=1'b1; next_ZF=(result==0); next_NF=result[7]; next_OF=1'b0;
          end
          4'hD: begin                                                       // CMP RX,RY = RX-RY, flags only
              wide={1'b0,regs[rx]}-{1'b0,regs[ry]}; result=wide[7:0]; flag_we=1'b1;
              next_CF=~wide[8]; next_ZF=(result==0); next_NF=result[7];
              next_OF=(regs[rx][7]^regs[ry][7]) & (result[7]^regs[rx][7]);
          end
          4'hE: next_pc=pc+pc_offset;                                       // JUMP signed 6-bit PC-relative
          4'hF: begin                                                       // conditional signed 6-bit PC-relative
              case (ry)
                2'b00: if (ZF) next_pc=pc+pc_offset;                        // BRE/BRZ
                2'b01: if (!ZF) next_pc=pc+pc_offset;                       // BRNE/BRNZ
                2'b10: if (!ZF && !(NF^OF)) next_pc=pc+pc_offset;           // BRG
                2'b11: if (!(NF^OF)) next_pc=pc+pc_offset;                  // BRGE
              endcase
          end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            pc<=6'd32; regs[0]<=0; regs[1]<=0; regs[2]<=0; regs[3]<=0;
            OF<=0; NF<=0; ZF<=0; CF<=0;
        end else begin
            pc<=next_pc;
            if (reg_we) regs[reg_waddr]<=result;
            if (flag_we) begin OF<=next_OF; NF<=next_NF; ZF<=next_ZF; CF<=next_CF; end
            if (dmem_we) dmem[dmem_addr]<=dmem_wdata;
            if (imem_we && imem_addr>=6'd32) imem[imem_addr]<=imem_wdata;
        end
    end

    assign pc_out=pc; assign instruction_out=insn;
    assign reg_a_out=regs[RA]; assign reg_b_out=regs[RB];
    assign reg_c_out=regs[RC]; assign reg_d_out=regs[RD];
    assign flags_out={OF,NF,ZF,CF}; assign halted=halt_r;
endmodule
