`timescale 1ns/1ps
// Simplified multicycle i281-style CPU.
// One instruction is completed through FETCH, DECODE and one or more EXECUTE states.
// Instruction: [15:12]=opcode, [11:10]=RX, [9:8]=RY, [7:0]=immediate/address/offset.
module i281_multicycle_cpu #(
    parameter IMEM_FILE = "bubble_sort.mem"
)(
    input  wire        clk,
    input  wire        reset,
    output wire [5:0]  pc_out,
    output wire [15:0] ir_out,
    output wire [3:0]  state_out,
    output wire [7:0]  reg_a_out,
    output wire [7:0]  reg_b_out,
    output wire [7:0]  reg_c_out,
    output wire [7:0]  reg_d_out,
    output wire [3:0]  flags_out,
    output wire        halted
);
    localparam [3:0]
      S_FETCH=0, S_DECODE=1, S_EXEC_ALU=2, S_EXEC_CMP=3,
      S_MEM_ADDR=4, S_MEM_READ=5, S_MEM_WB=6, S_MEM_WRITE=7,
      S_BRANCH=8, S_JUMP=9, S_HALT=10;

    reg [3:0] state;
    reg [5:0] pc;
    reg [15:0] ir;
    reg [7:0] regs [0:3];
    reg [15:0] imem [0:63];
    reg [7:0] dmem [0:15];

    // Multicycle temporary registers.
    reg [7:0] op_a, op_b, alu_out, mdr;
    reg [3:0] mem_addr;
    reg OF, NF, ZF, CF;
    reg [8:0] wide;
    reg [7:0] calc;
    reg calc_OF, calc_NF, calc_ZF, calc_CF;

    wire [3:0] opcode = ir[15:12];
    wire [1:0] rx = ir[11:10];
    wire [1:0] ry = ir[9:8];
    wire [7:0] imm = ir[7:0];
    wire signed [6:0] rel6 = {{1{ir[5]}},ir[5:0]};

    integer i;
    initial begin
      for (i=0;i<64;i=i+1) imem[i]=16'h0000;
      if (IMEM_FILE != "") $readmemh(IMEM_FILE, imem);
    end

    // Shared ALU calculation. Operands are latched in DECODE.
    always @* begin
      wide=9'h000; calc=8'h00;
      calc_OF=1'b0; calc_NF=1'b0; calc_ZF=1'b0; calc_CF=1'b0;
      case (opcode)
        4'h4: begin // ADD
          wide={1'b0,op_a}+{1'b0,op_b}; calc=wide[7:0]; calc_CF=wide[8];
          calc_OF=(~(op_a[7]^op_b[7]))&(calc[7]^op_a[7]);
        end
        4'h5: begin // ADDI
          wide={1'b0,op_a}+{1'b0,imm}; calc=wide[7:0]; calc_CF=wide[8];
          calc_OF=(~(op_a[7]^imm[7]))&(calc[7]^op_a[7]);
        end
        4'h6,4'hD: begin // SUB or CMP
          wide={1'b0,op_a}-{1'b0,op_b}; calc=wide[7:0]; calc_CF=~wide[8];
          calc_OF=(op_a[7]^op_b[7])&(calc[7]^op_a[7]);
        end
        4'h7: begin // SUBI
          wide={1'b0,op_a}-{1'b0,imm}; calc=wide[7:0]; calc_CF=~wide[8];
          calc_OF=(op_a[7]^imm[7])&(calc[7]^op_a[7]);
        end
        4'hC: begin // SHIFTL/SHIFTR selected by I8
          if (!ir[8]) begin calc=op_a<<1; calc_CF=op_a[7]; end
          else begin calc=op_a>>1; calc_CF=op_a[0]; end
        end
        default: calc=8'h00;
      endcase
      calc_ZF=(calc==0); calc_NF=calc[7];
    end

    always @(posedge clk) begin
      if (reset) begin
        state<=S_FETCH; pc<=6'd32; ir<=16'h0000;
        regs[0]<=0; regs[1]<=0; regs[2]<=0; regs[3]<=0;
        op_a<=0; op_b<=0; alu_out<=0; mdr<=0; mem_addr<=0;
        OF<=0; NF<=0; ZF<=0; CF<=0;
      end else begin
        case (state)
          S_FETCH: begin
            ir<=imem[pc];
            if (pc==6'd63 && imem[pc]==16'h0000) state<=S_HALT;
            else state<=S_DECODE;
          end

          S_DECODE: begin
            // Read register file once and retain operands for later cycles.
            op_a<=regs[rx]; op_b<=regs[ry];
            case (opcode)
              4'h0: begin pc<=pc+1'b1; state<=S_FETCH; end
              4'h2: begin regs[rx]<=regs[ry]; pc<=pc+1'b1; state<=S_FETCH; end
              4'h3: begin regs[rx]<=imm; pc<=pc+1'b1; state<=S_FETCH; end
              4'h4,4'h5,4'h6,4'h7,4'hC: state<=S_EXEC_ALU;
              4'hD: state<=S_EXEC_CMP;
              4'h8,4'h9,4'hA,4'hB: state<=S_MEM_ADDR;
              4'hE: state<=S_JUMP;
              4'hF: state<=S_BRANCH;
              default: begin pc<=pc+1'b1; state<=S_FETCH; end
            endcase
          end

          S_EXEC_ALU: begin
            alu_out<=calc; regs[rx]<=calc;
            OF<=calc_OF; NF<=calc_NF; ZF<=calc_ZF; CF<=calc_CF;
            pc<=pc+1'b1; state<=S_FETCH;
          end

          S_EXEC_CMP: begin
            alu_out<=calc;
            OF<=calc_OF; NF<=calc_NF; ZF<=calc_ZF; CF<=calc_CF;
            pc<=pc+1'b1; state<=S_FETCH;
          end

          S_MEM_ADDR: begin
            if (opcode==4'h8 || opcode==4'hA) mem_addr<=imm[3:0];
            else mem_addr<=op_b[3:0]+imm[3:0];
            if (opcode==4'h8 || opcode==4'h9) state<=S_MEM_READ;
            else state<=S_MEM_WRITE;
          end

          S_MEM_READ: begin mdr<=dmem[mem_addr]; state<=S_MEM_WB; end
          S_MEM_WB: begin regs[rx]<=mdr; pc<=pc+1'b1; state<=S_FETCH; end
          S_MEM_WRITE: begin dmem[mem_addr]<=op_a; pc<=pc+1'b1; state<=S_FETCH; end

          S_JUMP: begin pc<=pc+rel6; state<=S_FETCH; end

          S_BRANCH: begin
            case (ry)
              2'b00: pc<=ZF ? pc+rel6 : pc+1'b1;                    // equal/zero
              2'b01: pc<=!ZF ? pc+rel6 : pc+1'b1;                   // not equal/nonzero
              2'b10: pc<=(!ZF && !(NF^OF)) ? pc+rel6 : pc+1'b1;     // signed greater
              2'b11: pc<=(!(NF^OF)) ? pc+rel6 : pc+1'b1;            // signed greater/equal
            endcase
            state<=S_FETCH;
          end

          S_HALT: state<=S_HALT;
          default: state<=S_FETCH;
        endcase
      end
    end

    assign pc_out=pc; assign ir_out=ir; assign state_out=state;
    assign reg_a_out=regs[0]; assign reg_b_out=regs[1];
    assign reg_c_out=regs[2]; assign reg_d_out=regs[3];
    assign flags_out={OF,NF,ZF,CF}; assign halted=(state==S_HALT);
endmodule
