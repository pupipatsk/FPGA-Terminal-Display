`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/31/2021 09:31:37 PM
// Design Name:
// Module Name: system
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


module system (
    input wire [11:0] sw,
    input btnC,
    btnU,
    btnL,
    output wire Hsync,
    Vsync,
    output wire [3:0] vgaRed,
    vgaGreen,
    vgaBlue,
    output wire RsTx,
    input wire RsRx,
    input clk
);

    wire [7:0] char;
    wire clkDiv;
    wire en;
    ClockDiv cd (
        clkDiv,
        clk
    );

    vga vga (
        clk,
        char,
        en,
        Hsync,
        Vsync,
        {vgaRed, vgaGreen, vgaBlue}
    );
    uart uart (
        clk,
        RsRx,
        RsTx,
        char,
        en
    );
endmodule
