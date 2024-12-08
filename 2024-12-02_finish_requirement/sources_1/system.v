`timescale 1ns / 1ps

module system (
    input wire clk,              // System clock
    output wire [0:0] JA,           // UART TX (Transmit)
    input wire [0:0] JB,            // UART RX (Receive)
    input wire [7:0] sw,         // Switches for transmitting data
    input btnC,                  // Button to trigger transmission
    output wire [6:0] seg,       // Seven-segment display segments
    output wire dp,              // Decimal point
    output wire [3:0] an,         // Seven-segment display anodes
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue
);

    // Internal Signals
    wire [7:0] received_data;    // Data received via UART
    wire valid;                  // Signal for valid received data
    wire [7:0] data_to_transmit; // Data to transmit (from switches)
    assign data_to_transmit = sw; // Map switches to transmit data
    
    wire clkDiv;
    ClockDiv cd(clkDiv, clk);
    
    // VGA module for displaying characters
    vga vga_inst(
        .clk(clk),
        .char(received_data),
        .en(valid),
        .hsync(Hsync),
        .vsync(Vsync),
        .rgb({vgaRed, vgaGreen, vgaBlue})
    );

    // UART Module
    uart uart_inst (
        .clk(clk),
        .RsRx(JB[0]),              // RX connected to JA[1]
        .RsTx(JA[0]),              // TX connected to JA[0]
        .char(received_data),      // Received character
        .en(valid),                // Valid received data signal
        .data_transmit(data_to_transmit), // Data to transmit
        .btnC(btnC)                // Transmit trigger
    );
    
    // Seven-Segment Display
    QuadSevenSegmentDisplay display (
        .seg(seg),
        .dp(dp),
        .an(an),
        .num3(received_data[7:4]), // High nibble of received data
        .num2(received_data[3:0]), // Low nibble of received data
        .num1(data_to_transmit[7:4]), // High nibble of transmitted data
        .num0(data_to_transmit[3:0]), // Low nibble of transmitted data
        .clk(clkDiv)
    );

endmodule