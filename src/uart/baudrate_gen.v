`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: baudrate_gen
// Description: Generates a baud rate clock from the system clock.
// Parameters:
//  - CLK_FREQ: Frequency of the input clock in Hz.
//  - BAUD_RATE: Desired baud rate.
// The output `baud` toggles at half the baud rate frequency.
//////////////////////////////////////////////////////////////////////////////////


module baudrate_gen #(
    parameter CLK_FREQ = 100_000_000, // System clock frequency in Hz (default: 100 MHz)
    parameter BAUD_RATE = 9600       // Desired baud rate
)(
    input wire clk,                  // System clock input
    output reg baud                  // Baud rate clock output
);

    // Calculate the number of clock cycles per half baud period
    localparam integer COUNT_MAX = (CLK_FREQ / (BAUD_RATE * 16 * 2));

    reg [31:0] counter = 0;          // Counter for clock division

    always @(posedge clk) begin
        if (counter == COUNT_MAX - 1) begin
            counter <= 0;            // Reset counter
            baud <= ~baud;           // Toggle baud output
        end else begin
            counter <= counter + 1;  // Increment counter
        end
    end

endmodule
