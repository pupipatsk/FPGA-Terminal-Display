`timescale 1ns / 1ps


module uart(
    input clk,                   // System clock
    input RsRx,                  // UART RX input
    output RsTx,                 // UART TX output
    output reg [7:0] char,       // Received UART character
    output reg en,               // Enable signal for received character
    input [7:0] data_transmit,   // Data to be transmitted
    input btnC                   // Transmit enable signal (button press)
);

    // Internal Signals
    reg last_rec;                // Edge detection for received data
    reg [7:0] data_in;           // Temporary storage for received data
    wire [7:0] data_out;         // Received data from uart_rx
    wire received;               // Signal indicating data received
    wire sent;                   // Signal indicating data transmitted
    wire baud;                   // Baud rate clock

    // Instantiate the baud rate generator
    baudrate_gen baud_generator(
        .clk(clk),
        .baud(baud)
    );

    // Instantiate UART receiver
    uart_rx receiver(
        .clk(baud),
        .bit_in(RsRx),
        .received(received),
        .data_out(data_out)
    );

    // Instantiate UART transmitter
    uart_tx transmitter(
        .clk(baud),
        .data_transmit(data_transmit),
        .ena(btnC),
        .sent(sent),
        .bit_out(RsTx)
    );

    // Receive Logic
    always @(posedge clk) begin
        if (en) en <= 0; // Reset enable after 1 cycle

        if (~last_rec & received) begin // Edge detect for received data
            data_in <= data_out;       // Store received data
            if ((data_out >= 32 && data_out <= 126) || data_out == 13) begin
                char <= data_out;      // Valid ASCII character
                en <= 1;              // Set enable for valid character
            end
        end
        last_rec <= received;          // Update last_rec for edge detection
    end

endmodule
