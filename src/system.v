`timescale 1ns / 1ps


module system (
    input wire [7:0] sw, // Switch inputs
    output wire [0:0] JA,        // UART TX (Transmit) on JA
    input wire [0:0] JB,         // UART RX (Receive) on JB
    input btnC
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire RsTx,
    input wire RsRx,
    output wire [6:0] seg,
    output wire dp,
    output wire [3:0] an,
    input clk
);

    // Internal Signals
    wire baud;                   // Baud rate clock
    wire [7:0] received_data;    // Data received via UART
    wire valid;                  // Signal for valid received data
    wire sent;                   // Signal for transmitted data
    wire [7:0] data_to_transmit; // Data to transmit (from switches)
    assign data_to_transmit = sw; // Map switches to transmit data

    // Clock divider for VGA
    ClockDiv cd(
        .clkDiv(),
        .clock(clk)
    );

    // Debouncer for btnC
    wire btnC_debounced;
    Debouncer btnC_debounced(.signal_out(btnC_debounced), .async_sinal_in(btnC), .clk(clk));

    // VGA module for displaying characters
    vga vga_inst(
        .clk(clk),
        .char(char),
        .en(en),
        .hsync(Hsync),
        .vsync(Vsync),
        .rgb({vgaRed, vgaGreen, vgaBlue})
    );

    // UART Module
    uart uart_inst (
        .clk(clk),
        .RsRx(JB[0]),              // RX connected to JB[0]
        .RsTx(JA[0]),              // TX connected to JA[0]
        .char(received_data),      // Received character
        .en(valid),                // Valid received data signal
        .data_transmit(data_to_transmit), // Data to transmit
        .btnC(btnC)                // Transmit trigger
    );

    // Split received and transmitted data into nibbles for display
    wire [3:0] recv_high = char[7:4];
    wire [3:0] recv_low = char[3:0];
    wire [3:0] send_high = data_transmit[7:4];
    wire [3:0] send_low = data_transmit[3:0];

    // 7-Segment display module
    QuadSevenSegmentDisplay seven_seg_display(
        .seg(seg),
        .dp(dp),
        .an(an),
        .num3(recv_high),    // Received high nibble
        .num2(recv_low),     // Received low nibble
        .num1(send_high),    // Transmitted high nibble
        .num0(send_low),     // Transmitted low nibble
        .clk(clk)
    );

endmodule
