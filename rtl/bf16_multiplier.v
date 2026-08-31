`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2026 02:36:21 PM
// Design Name: 
// Module Name: bf16_multiplier
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bf16_multiplier(
    input  clk, rst, start,
    input [15:0] a, b,
    output reg [15:0] y,
    output reg done
);

    localparam  ST_IDLE   = 3'd0,
                ST_UNPACK = 3'd1,
                ST_MUL    = 3'd2,
                ST_NORM   = 3'd3,
                ST_PACK   = 3'd4,
                ST_DONE   = 3'd5;

    reg [2:0] state, next_state;

    // Unpacking BF16 fields: sign[15], exp[14:7], frac[6:0]
    reg sa, sb, sy;
    reg [7:0] ea, eb;
    reg [6:0] fa, fb;

    // 8-bit significands with hidden 1 for normalized inputs (1 + 7 frac)
    reg [7:0] ma, mb;

    // exponent math: signed temp (ea + eb - bias(127))
    reg signed [10:0] e_tmp;
    reg [7:0] ey;

    // 16-bit product of 8x8 mantissa/significand
    reg [15:0] prod;

    // normalized significand (keep 8 bits incl hidden 1)
    reg [7:0] my; //mantissa of y

    //state update logic
    always @(posedge clk or posedge rst) begin
        if (rst) state <= ST_IDLE;
        else     state <= next_state;
    end

    //state transition logic
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: if (start) next_state = ST_UNPACK;
            ST_UNPACK: next_state = ST_MUL;
            ST_MUL: next_state = ST_NORM;
            ST_NORM: next_state = ST_PACK;
            ST_PACK: next_state = ST_DONE;
            ST_DONE: next_state = ST_IDLE;
            default: next_state = ST_IDLE;
        endcase
    end

    //output registering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
            y <= 16'd0;

            sa <= 1'b0; sb <= 1'b0; sy <= 1'b0;
            ea <= 8'd0;  eb <= 8'd0;
            fa <= 7'd0;  fb <= 7'd0;
            ma <= 8'd0;  mb <= 8'd0;

            e_tmp <= 11'sd0;
            ey <= 8'd0;

            prod <= 16'd0;
            my <= 8'd0;
        end else begin
            done <= 1'b0;

            case (state)
                ST_UNPACK: begin
                    sa <= a[15]; ea <= a[14:7]; fa <= a[6:0];
                    sb <= b[15]; eb <= b[14:7]; fb <= b[6:0];

                    // hidden 1 for normalized values
                    ma <= {1'b1, a[6:0]};
                    mb <= {1'b1, b[6:0]};

                    // sign XOR to get product sign
                    sy <= a[15] ^ b[15];

                    // exponent add and subtract bias 127
                    e_tmp <= $signed({1'b0, a[14:7]}) + $signed({1'b0, b[14:7]}) - 11'sd127;
                end

                ST_MUL: begin
                    prod <= ma * mb; // 8x8 => 16
                end

                ST_NORM: begin
                    // ma,mb in [1,2) => product in [1,4)
                    // If prod[15]==1 => product in [2,4), shift right and exp++
                    if (prod[15]) begin
                        my <= prod[15:8];   // keep top 8 bits (hidden 1 included)
                        e_tmp <= e_tmp + 11'sd1;
                    end 
                    else begin
                        my <= prod[14:7];      // already in [1,2)
                    end

                    // capture exponent (no overflow/underflow handling)
                    ey <= e_tmp[7:0];
                end

                ST_PACK: begin
                    // pack BF16: sign | exponent | fraction
                    y <= {sy, ey, my[6:0]};
                end

                ST_DONE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule
