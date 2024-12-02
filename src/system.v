`timescale 1ns / 1ps


module system (
    input wire [11:0] sw, // Switch inputs
    input btnC, btnU, btnL,
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire RsTx,
    input wire RsRx,
    output wire [6:0] seg,
    output wire dp,
    output wire [3:0] an,
    input clk
);

    wire [7:0] char;           // Received UART data
    wire [7:0] data_transmit;  // Data to be transmitted
    assign data_transmit = sw[7:0];
    wire en;                   // Enable signal for valid received data

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

    // UART module for bidirectional communication
    uart uart_inst(
        .clk(clk),
        .RsRx(RsRx),
        .RsTx(RsTx),
        .char(char),
        .en(en),
        .data_transmit(data_transmit),
        .btnC(btnC_debounced)
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
