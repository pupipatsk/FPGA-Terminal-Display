`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 08/27/2024 10:23:29 AM
// Design Name:
// Module Name: ClockDiv
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


module ClockDiv (
    output reg  clkDiv,
    input  wire clock
);
    reg [22:0] counter;

    initial begin
        counter <= 0;
    end

    always @(posedge clock) begin
        if (counter == 100000) begin
            counter <= 0;
            clkDiv  <= ~clkDiv;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
