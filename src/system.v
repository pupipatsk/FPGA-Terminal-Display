`timescale 1ns / 1ps

module system (
    input  wire clk,    // System clock
    output wire [0:0] JA,     // UART TX (Transmit)
    input  wire [0:0] JB,     // UART RX (Receive)
    input  wire [7:0] sw,     // Switches for transmitting data
    input  wire btnC,   // Button to trigger transmission
    output wire [6:0] seg,    // Seven-segment display segments
    output wire dp,     // Decimal point
    output wire [3:0] an,     // Seven-segment display anodes
    output wire Hsync, Vsync,  // VGA synchronization signals
    output wire [3:0] vgaRed, vgaGreen, vgaBlue
);

    // Internal Signals
    wire [7:0] data_receive;  // Data received via UART
    wire valid;  // Signal for valid received data
    wire [7:0] data_transmit;  // Data to transmit (from switches)
    assign data_transmit = sw;  // Map switches to transmit data

    // VGA module for displaying characters
    vga vga_inst (
        .clk(clk),
        .char(data_receive),
        .en(valid),
        .hsync(Hsync),
        .vsync(Vsync),
        .rgb({vgaRed, vgaGreen, vgaBlue})
    );

    // UART Module
    // Sent button: btnC
    Debouncer debounce_btnC (.signal_out(btnC_debounced), .async_sinal_in(btnC), .clk(clk));
    uart uart_inst (
        .clk          (clk),
        .RsRx         (JB[0]),             // JB as RX
        .RsTx         (JA[0]),             // JA as TX
        .char         (data_receive),     // Received character
        .en           (valid),             // Valid received data signal
        .data_transmit(data_transmit),  // Data to transmit
        .btnC         (btnC_debounced)               // Transmit trigger
    );

    // Seven-Segment
    // Clock Divider
    wire clkDiv;
    ClockDiv clock_divider (.clkDiv(clkDiv), .clk(clk));
    // Display
    QuadSevenSegmentDisplay seven_segment_display (
        .seg(seg),
        .dp(dp),
        .an(an),
        .num3(data_receive[7:4]),  // High nibble of received data
        .num2(data_receive[3:0]),  // Low nibble of received data
        .num1(data_transmit[7:4]),  // High nibble of transmitted data
        .num0(data_transmit[3:0]),  // Low nibble of transmitted data
        .clk(clkDiv)
    );

endmodule
