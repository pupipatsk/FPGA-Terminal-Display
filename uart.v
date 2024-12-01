`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2021 09:59:35 PM
// Design Name: 
// Module Name: uart
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

module uart(
    input clk,
    input RsRx,
    output RsTx,
    output reg [7:0] char,
    output reg en
    );
    
    reg last_rec;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire sent, received, baud;
    
    baudrate_gen baudrate_gen(clk, baud);
    uart_rx receiver(baud, RsRx, received, data_out);
    //uart_tx transmitter(baud, data_in, en, sent, RsTx);
    
    always @(posedge clk) begin
        if (en) en = 0;
        if (~last_rec & received) begin
            data_in = data_out;
            if((data_out >= 32 && data_out <= 126) || data_out == 13) begin
                char = data_out;
                en = 1;
            end
        end
        last_rec = received;
    end
    
endmodule
