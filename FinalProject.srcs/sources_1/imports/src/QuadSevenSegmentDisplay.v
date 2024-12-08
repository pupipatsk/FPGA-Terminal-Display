`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: QuadSevenSegmentDisplay
// Description: Common Anode
//////////////////////////////////////////////////////////////////////////////////


module QuadSevenSegmentDisplay(
    output [6:0] seg, // data to display
    output dp, // dot point
    output [3:0] an, // active display
    input [3:0] num3, // most significant digit
    input [3:0] num2,
    input [3:0] num1,
    input [3:0] num0, // least significant digit
    input clk
    );
    
    // State transition for rotate active display and number to display
    reg [1:0] state; // present state 2-bits
    always @(posedge clk) begin
        state <= state + 1;
    end
    
    reg [3:0] activeAnodes; // active display
    reg [3:0] hex;
    always @(state) begin
        case(state)
            2'b00 : begin // least sig.
                activeAnodes = 4'b0001;
                hex = num0; end
            2'b01 : begin
                activeAnodes = 4'b0010;
                hex = num1; end
            2'b10 : begin
                activeAnodes = 4'b0100;
                hex = num2; end
            2'b11 : begin // most sig.
                activeAnodes = 4'b1000;
                hex = num3; end
        endcase
    end
    
    // Display to Hardware
    HexTo7SegmentDecoder decoder(seg, hex);
    assign dp = 0; // No dot point
    assign an = ~activeAnodes; // Active low
    
endmodule
