// lemmings 1
module top_module(
    input clk,
    input areset,    // Freshly brainwashed Lemmings walk left.
    input bump_left,
    input bump_right,
    output walk_left,
    output walk_right); //  

    parameter left=0, right=1;
    reg[1:0] state, next_state;

    always @(*) begin
        // State transition logic
        if(bump_left == 1&& bump_right == 0 && state[left] == 1) begin
            next_state[left] = 0;
            next_state[right] = 1;
        end
        else if(bump_left == 0 && bump_right == 1 && state[right] == 1) begin
            next_state[left] = 1;
            next_state[right] = 0;
        end
        else if(bump_left == 1&& bump_right == 1) begin
            next_state[left] = ~state[left];
            next_state[right] = ~state[right];
        end
        else 
            next_state = state;
    end

    always @(posedge clk, posedge areset) begin
        // State flip-flops with asynchronous reset
        if(areset == 1) begin
            state[left] <= 1;
            state[right] <= 0;
        end
        else 
            state <=  next_state;
    end

    // Output logic
    // assign walk_left = (state == ...);
    assign walk_left = state[left];
    assign walk_right = state[right];
    // assign walk_right = (state == ...);

endmodule



// lemmings 2

module top_module(
    input clk,
    input areset,    // Freshly brainwashed Lemmings walk left.
    input bump_left,
    input bump_right,
    input ground,
    output walk_left,
    output walk_right,
    output aaah ); 


    parameter left=0, right=1, fall_left = 2, fall_right = 3;
    reg[3:0] state, next_state;

    always @(*) begin
        // State transition logic
        next_state = 4'b0000;
        if(ground == 1) begin 
            if(state[left] == 1) begin
                if(bump_left == 1)begin
                    next_state[right] = 1; 
                end
                else 
                    next_state = state;
            end
            else  if(state[right] == 1) begin
                if(bump_right == 1)begin
                     next_state[left] = 1;
                end
                else 
                    next_state = state;
            end
            else if(state[fall_left] == 1) begin
                next_state = 4'b0001;
            end
            else if(state[fall_right] == 1) begin
               next_state = 4'b0010;
            end
     end
        else begin
             if(state[left] == 1)
                 next_state = 4'b0100;
            else if(state[right] == 1)
                 next_state = 4'b1000;
        else
            next_state = state;
        end
    end
    
    always @(posedge clk, posedge areset) begin
        // State flip-flops with asynchronous reset
        if(areset == 1) begin
            state = 4'b0001;
        end
        else 
            state <=  next_state;
       
    end
    // Output logic
    // assign walk_left = (state == ...);
    assign walk_left = state[left];
    assign walk_right = state[right];
    assign aaah = (state[fall_left] == 1 || state[fall_right] == 1)? 1:0;
     
    // assign walk_right = (state == ...);
endmodule

// lemmings 3

module top_module(
    input clk,
    input areset,    // Freshly brainwashed Lemmings walk left.
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output walk_left,
    output walk_right,
    output aaah,
    output digging ); 
    reg [5:0] state, next_state;
    parameter left =0, right = 1, fall_left = 2, fall_right = 3,dig_left = 4,dig_right = 5; 
    always@(*) begin
        next_state = 6'b00000;
        if(ground == 1) begin
                if(state[left]) begin
                    if(bump_left == 1 && dig == 0)
                    next_state[right] = 1;
                    else if((dig == 1 && bump_left == 1) || (dig == 1 && bump_left == 0))
                        next_state[dig_left] = 1;
                else
                    next_state = state;
            end
            else if(state[right]) begin
                if(bump_right == 1 && dig == 0)
                    next_state[left] = 1;
                else if((dig == 1 && bump_right == 1) || (dig == 1 && bump_right == 0))
                    next_state[dig_right] = 1;
                else
                    next_state = state;
            end
            else if(state[fall_left]) begin   
               next_state = 6'b000001;
            end
            else if(state[fall_right]) begin   
               next_state = 6'b000010;
            end
                else if(state[dig_left])begin
                    next_state = 6'b010000;
                end
                else if(state[dig_right]) begin
                    next_state = 6'b100000;
                end
            end
           
        else begin
            if(state[left] || state[fall_left] || state[dig_left])
                next_state[fall_left] = 1;
            else if (state[right] || state[fall_right] || state[dig_right])
                next_state[fall_right] = 1;
        end
    end
    always@(posedge clk, posedge areset) begin
        if(areset)
            state <= 6'b000001;
        else 
            state <= next_state;
    end
    assign walk_left = state[left] ;
    assign walk_right = state[right];
    assign aaah = (state[fall_left] || state[fall_right]);
    assign digging = (state[dig_left] || state[dig_right]);
                

endmodule


// lemmings 4

module top_module(
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output walk_left,
    output walk_right,
    output aaah,
    output digging );

    parameter LEFT=0, RIGHT=1, FALL_LEFT=2, FALL_RIGHT=3,
              DIG_LEFT=4, DIG_RIGHT=5, SPLATTER=6;

    reg [6:0] state, next_state;
    reg [4:0] fall_counter;

    always @(posedge clk or posedge areset) begin
        if (areset)
            fall_counter <= 0;
        else if (state[FALL_LEFT] || state[FALL_RIGHT])
            fall_counter <= (fall_counter < 31) ? fall_counter + 1 : fall_counter;
        else
            fall_counter <= 0;
    end

    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= 7'b0000001;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = 7'b0;
        case (1'b1)
            state[LEFT]: begin
                if (!ground)
                    next_state[FALL_LEFT] = 1'b1;
                else if (dig)
                    next_state[DIG_LEFT] = 1'b1;
                else if (bump_left)
                    next_state[RIGHT] = 1'b1;
                else
                    next_state[LEFT] = 1'b1;
            end
            state[RIGHT]: begin
                if (!ground)
                    next_state[FALL_RIGHT] = 1'b1;
                else if (dig)
                    next_state[DIG_RIGHT] = 1'b1;
                else if (bump_right)
                    next_state[LEFT] = 1'b1;
                else
                    next_state[RIGHT] = 1'b1;
            end
            state[FALL_LEFT]: begin
                if (ground) begin
                    if (fall_counter >= 20)
                        next_state[SPLATTER] = 1'b1;
                    else
                        next_state[LEFT] = 1'b1;
                end else
                    next_state[FALL_LEFT] = 1'b1;
            end
            state[FALL_RIGHT]: begin
                if (ground) begin
                    if (fall_counter >= 20)
                        next_state[SPLATTER] = 1'b1;
                    else
                        next_state[RIGHT] = 1'b1;
                end else
                    next_state[FALL_RIGHT] = 1'b1;
            end
            state[DIG_LEFT]: begin
                if (!ground)
                    next_state[FALL_LEFT] = 1'b1;
                else
                    next_state[DIG_LEFT] = 1'b1;
            end
            state[DIG_RIGHT]: begin
                if (!ground)
                    next_state[FALL_RIGHT] = 1'b1;
                else
                    next_state[DIG_RIGHT] = 1'b1;
            end
            state[SPLATTER]: begin
                next_state[SPLATTER] = 1'b1;
            end
            default: next_state[LEFT] = 1'b1;
        endcase
    end

    assign walk_left  = state[LEFT];
    assign walk_right = state[RIGHT];
    assign aaah       = state[FALL_LEFT] | state[FALL_RIGHT];
    assign digging    = state[DIG_LEFT]  | state[DIG_RIGHT];

endmodule


