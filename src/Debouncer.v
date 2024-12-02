`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2024 10:18:56 PM
// Design Name: 
// Module Name: Debouncer
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


module Debouncer(
    output reg signal_out, // Debounced signal output
    input async_sinal_in, // Asynchronous signal input
    input clk
    );
    
    wire Q1, notQ1, Q2, notQ2;
    
    Dflipflop DFF1(Q1, notQ1, async_sinal_in, clk);
    Dflipflop DFF2(Q2, notQ2, Q1, clk);

    always @(posedge clk) begin
        if (Q1 == Q2) signal_out <= Q2;
    end
    
endmodule
