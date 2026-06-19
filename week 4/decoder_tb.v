module tb_decoder_4_16;
    reg [3:0] in;
    reg enable;
    wire [15:0] out;
    
    top_module uut (
        .en(enable),
        .w3(in[3]),
        .w2(in[2]),
        .w1(in[1]),
        .w0(in[0]),
        .y0(out[0]),   .y1(out[1]),   .y2(out[2]),   .y3(out[3]),
        .y4(out[4]),   .y5(out[5]),   .y6(out[6]),   .y7(out[7]),
        .y8(out[8]),   .y9(out[9]),   .y10(out[10]), .y11(out[11]),
        .y12(out[12]), .y13(out[13]), .y14(out[14]), .y15(out[15])
    );
    
    integer i;
    integer fail_count;
    
    initial begin
        in = 4'b0000;
        enable = 0;
        fail_count = 0;
        #10;
        
        // TEST 1: Enable = 0 (all outputs must be 0)
        enable = 0;
        for (i = 0; i < 16; i = i + 1) begin
            in = i;
            #10;
            if (out !== 16'b0)
                fail_count = fail_count + 1;
        end
        
        // TEST 2: Enable = 1 (one-hot output)
        enable = 1;
        for (i = 0; i < 16; i = i + 1) begin
            in = i;
            #10;
            if (out !== (16'b1 << i))
                fail_count = fail_count + 1;
        end
        
        // Final verdict
        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL");
        
        $finish;
    end
    
endmodule
