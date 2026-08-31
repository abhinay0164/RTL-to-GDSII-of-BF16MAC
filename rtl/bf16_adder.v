`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/09/2026 12:21:52 PM
// Design Name: 
// Module Name: bf16_adder
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


module bf16_adder (
    input clk, rst, start,
    input [15:0] a, b,
    output reg [15:0] y,
    output reg done
);

    //state parameters
    parameter   ST_IDLE = 3'd0,
                ST_UNPACK = 3'd1,
                ST_ALIGN = 3'd2,
                ST_ADD = 3'd3,
                ST_NORM = 3'd4,
                ST_PACK = 3'd5,
                ST_DONE = 3'd6;

    reg [2:0] state, next_state;

    // Unpacked fields sign[15], exp[14:7], frac[6:0]
    reg sa, sb, sy;
    reg [7:0] ea, eb, ey; //8 bit exponent
    reg [7:0] ma, mb; // 7+1 bit for mantissa(hidden bit)

    // handling of small and big numbers
    reg s_big;
    reg [7:0] e_big;
    reg [7:0] m_big;
    reg [7:0] m_sml_al; //to handle shifted smaller mantissa

    reg  do_sub;
    reg [8:0] mant; // 8-bit for carry

    // leading zero counter
    reg [3:0] norm_cnt;

    //combinational wires to avoid alignment issues of 1 clk delay
    wire a_ge_b = (ea > eb) || ((ea == eb) && (ma >= mb)); //greater number check

    //big=(a>b)?a:b
    wire comb_s_big = a_ge_b ? sa : sb;
    wire [7:0] comb_e_big = a_ge_b ? ea : eb;
    wire [7:0] comb_m_big = a_ge_b ? ma : mb;
    
    //small=(a>b)?b:a
    wire [7:0] comb_e_sml = a_ge_b ? eb : ea;
    wire [7:0] comb_m_sml = a_ge_b ? mb : ma;

    wire [7:0] exp_diff = comb_e_big - comb_e_sml;

    wire [7:0] comb_m_sml_al =
        (exp_diff >= 4'd8) ? 4'd0 : (comb_m_sml >> exp_diff); // align by right shift

    //state update logic
    always @(posedge clk or posedge rst) begin
        if (rst) 
            state <= ST_IDLE;
        else        
            state <= next_state;
    end

    //state transition logic
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: if (start) next_state = ST_UNPACK;
            ST_UNPACK: next_state = ST_ALIGN;
            ST_ALIGN: next_state = ST_ADD;
            ST_ADD: next_state = ST_NORM;
            ST_NORM: begin
                if (!do_sub) begin
                    // In case of carry while addition
                    if (mant[8]) next_state = ST_NORM;
                    else          next_state = ST_PACK;
                end else begin
                    // In case of leading zeros while subtraction
                    if ((mant != 9'd0) && (mant[7] == 1'b0) && (norm_cnt < 4'd8))
                        next_state = ST_NORM;
                    else
                        next_state = ST_PACK;
                end
            end
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

            // a,b,y signals reset
            sa <= 1'b0; sb <= 1'b0; sy <= 1'b0;
            ea <= 8'd0; eb <= 8'd0; ey <= 8'd0;
            ma <= 8'd0; mb <= 8'd0;

            // big,small num reset
            s_big <= 1'b0; e_big <= 8'd0;
            m_big <= 8'd0; m_sml_al <= 8'd0;

            do_sub <= 1'b0;
            mant <= 9'd0;
            norm_cnt <= 4'd0;
        end 
        else begin
            done <= 1'b0; 

            case (state)
                //ST_IDLE is ignored as nothing to be performed
                ST_UNPACK: begin
                    // unpacking fields
                    sa <= a[15];  ea <= a[14:7];
                    sb <= b[15];  eb <= b[14:7];

                    // adding hidden bit to mantissa
                    ma <= {1'b1, a[6:0]};
                    mb <= {1'b1, b[6:0]};
                end

                ST_ALIGN: begin
                    // subtracting if signs are opposite
                    do_sub <= (sa ^ sb);

                    // latching from combinational wires
                    s_big <= comb_s_big;
                    e_big <= comb_e_big;
                    m_big <= comb_m_big;
                    m_sml_al <= comb_m_sml_al;

                    ey <= comb_e_big;
                end

                ST_ADD: begin
                    // subtraction of mantissa
                    if (do_sub) begin
                        mant <= {1'b0, m_big} - {1'b0, m_sml_al};
                        sy <= s_big;
                    end 
                    // addition of mantissa
                    else begin
                        mant <= {1'b0, m_big} + {1'b0, m_sml_al};
                        sy <= s_big;
                    end
                    norm_cnt <= 4'd0; //counter is set to 0
                end

                ST_NORM: begin
                    if (!do_sub) begin
                        // overflow handling in case of addition
                        if (mant[8]) begin
                            mant <= mant >> 1;
                            ey   <= ey + 1'b1;
                        end
                    end else begin
                        // shift till mant[7]==1 in case of subtraction
                        if ((mant != 9'd0) && (mant[7] == 1'b0) && (norm_cnt < 4'd11)) begin
                            mant <= mant << 1;
                            ey   <= ey - 1'b1;
                            norm_cnt <= norm_cnt + 1'b1;
                        end
                    end
                end

                ST_PACK: begin
                    // packing FP16: sign + exp + frac without hidden bit 
                    y <= {sy, ey[7:0], mant[6:0]};
                end

                ST_DONE: begin
                    done <= 1'b1;
                end

                default: begin
                    // no-op
                end
            endcase
        end
    end
endmodule