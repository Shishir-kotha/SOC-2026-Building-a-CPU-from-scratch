module decoder_module(input w1,
                      input w2,
                      input en,
                      output y1,
                      output y2,
                      output y3,
                      output y4); // 2-4 decoder module
  assign y1 = (en==1)? ~w1&~w2 : 0;
  assign y2 = (en==1)? w1&~w2 : 0;
  assign y3 = (en==1)? ~w1&w2 : 0;
  assign y4 = (en==1)? w1&w2 : 0;
  
endmodule


module top_module(input en,
                  input w0,
                  input w1,
                  input w2,
                  input w3, 
                  output y0,
                  output y1,
                  output y2,
                  output y3,
                  output y4,
                  output y5,
                  output y6,
                  output y7,
                  output y8,
                  output y9,
                  output y10,
                  output y11,
                  output y12,
                  output y13,
                  output y14,
                  output y15); // 4-16 decoder module using a 2-4 decoder module
  wire en0,en1,en2,en3;
  decoder_module inst ( w2, w3, en, en0, en1, en2, en3);
  decoder_module dec0 ( w0, w1,  en0,  y0, y1,  y2,  y3); 
  decoder_module dec1 ( w0, w1,  en1,  y4, y5,  y6,  y7);
  decoder_module dec2 ( w0, w1,  en2,  y8, y9,  y10,  y11); 
  decoder_module dec3 ( w0, w1,  en3,  y12, y13,  y14,  y15); 
    
endmodule
                 
