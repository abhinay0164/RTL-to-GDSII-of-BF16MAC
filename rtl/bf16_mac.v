`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2026 02:50:53 PM
// Design Name: 
// Module Name: bf16_mac
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


module bf16_mac (
    input clk, rst, start,
    input [15:0] a,b,
    output reg [15:0] y,
    output reg done
);

    // internal accumulator register
    reg [15:0] acc;

    reg mul_start;
    wire mul_done;
    wire [15:0] prod;

    reg sum_start;
    wire sum_done;
    wire [15:0] sum;
    
    //product register to store output from multiplier
    reg [15:0] prod_reg;

    //multiplier and adder instantiation
    bf16_multiplier mul4 (clk,rst,mul_start,a,b,prod,mul_done);
    bf16_adder add4 (clk,rst,sum_start,acc,prod_reg,sum,sum_done);

    // state parameter
    parameter   ST_IDLE = 3'd0,
                ST_MUL  = 3'd1,
                ST_WAIT_MUL = 3'd2,
                ST_ADD  = 3'd3,
                ST_WAIT_ADD = 3'd4,
                ST_DONE = 3'd5;

    reg [2:0] state, next_state;

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
            ST_IDLE: if (start)   
                        next_state = ST_MUL;
            ST_MUL: next_state = ST_WAIT_MUL;
            ST_WAIT_MUL: if (mul_done) 
                            next_state = ST_ADD;
            ST_ADD: next_state = ST_WAIT_ADD;
            ST_WAIT_ADD: if (sum_done) 
                            next_state = ST_DONE;
            ST_DONE: next_state = ST_IDLE;
            default: next_state = ST_IDLE;
        endcase
    end

    //output registering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
            y <= 15'd0;
            acc <= 15'd0;

            mul_start <= 1'b0;
            sum_start <= 1'b0;
            prod_reg <= 15'd0;
        end 
        else begin
            done <= 1'b0;

            mul_start <= 1'b0;
            sum_start <= 1'b0;

            case (state)
                ST_MUL: begin
                    mul_start <= 1'b1;
                end

                ST_WAIT_MUL: begin
                    //storing the product output from fp32_multipiler
                    if (mul_done) prod_reg <= prod;
                end

                ST_ADD: begin
                    sum_start <= 1'b1;
                end

                ST_WAIT_ADD: begin
                    if (sum_done) begin
                        acc <= sum;   // updating accumulator
                        y <= sum;   // output result is same as accumulator
                    end
                end

                ST_DONE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule
