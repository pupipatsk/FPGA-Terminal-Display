`timescale 1ns / 1ps


module vga(
    input wire clk,
    input wire [7:0] char,
    input wire en,
    output wire hsync, vsync,
    output wire [11:0] rgb
);

    parameter WIDTH = 640;
    parameter HEIGHT = 480;
    parameter CHAR_WIDTH = 8;    // Width of a character in pixels
    parameter CHAR_HEIGHT = 16;  // Height of a character in pixels
    parameter NUM_CHARS_X = WIDTH / CHAR_WIDTH; // Number of characters horizontally
    parameter NUM_CHARS_Y = HEIGHT / CHAR_HEIGHT; // Number of characters vertically

    // register for Basys 2 8-bit RGB DAC
    reg [11:0] rgb_reg;
    reg reset = 0;
    wire [9:0] x, y;

    // video status output from vga_sync to tell when to route out rgb signal to DAC
    wire video_on;
    wire p_tick;

    // instantiate vga_sync
    vga_sync vga_sync_unit (
        .clk(clk), .reset(reset),
        .hsync(hsync), .vsync(vsync), .video_on(video_on), .p_tick(p_tick),
        .x(x), .y(y)
    );

    // font ROM (for 8x16 character, 256 characters)
    reg [7:0] font_rom [0:4095];  // 256 characters, each with 16 rows, 8 bits per row (8x16)

    // Load the font ROM from a file
    initial begin
        $readmemb("font.data", font_rom);  // Import the font from file (hex format)
    end

    // State for scrolling text or static text
    reg [7:0] text [0:NUM_CHARS_X*NUM_CHARS_Y-1]; // Array to hold characters for the screen
    integer i;

    reg [12:0] char_n;
    // Initialize the screen with some text, this can be modified at runtime
    initial begin
        for (i = 0; i < NUM_CHARS_X*NUM_CHARS_Y; i = i + 1) begin
          text[i] = "";
        end
        char_n = 13'b0000000000000;
    end

    reg last_rec;
    always @(posedge clk) begin
        if (~last_rec & en) begin
            if (char == "\r" || char == "\n") begin // Handle new line
                char_n <= (char_n / NUM_CHARS_X) * NUM_CHARS_X + NUM_CHARS_X;
            end else begin
                if (char >= 32 && char <= 126) begin
                    text[char_n] <= char;  // Add valid character
                end else begin
                    text[char_n] <= "-";   // Replace unsupported characters with '-'
                end
                char_n <= char_n + 1;      // Move to next character position
            end
        end
        if (char_n >= NUM_CHARS_X * NUM_CHARS_Y) begin // Clear screen when full
            char_n <= 0;
            for (i = 0; i < NUM_CHARS_X * NUM_CHARS_Y; i = i + 1) begin
                text[i] = ""; // Clear all characters
            end
        end
        last_rec <= en; // Update last_rec for edge detection
    end


    // Compute the character based on current (x, y)
    wire [7:0] character;
    wire [6:0] char_x, char_y;

    assign char_x = x / CHAR_WIDTH; // Find the column of the character
    assign char_y = y / CHAR_HEIGHT; // Find the row of the character
    assign character = text[char_y * NUM_CHARS_X + char_x]; // Determine which character to display

    // Determine the pixel location within the character
    wire char_pixel;
    assign char_pixel = font_rom[CHAR_HEIGHT * character + (y % CHAR_HEIGHT)][CHAR_WIDTH - 1 - (x % CHAR_WIDTH)]; // Access the correct row of the character

    // Determine color of the pixel
    always @(posedge p_tick) begin
        if (video_on && char_pixel) begin
            rgb_reg = 12'b111111111111;  // Display the color from switch if pixel part of character
        end
        else begin
            rgb_reg = 12'b0; // Black for empty pixels
        end
    end

    // output
    assign rgb = (video_on) ? rgb_reg : 12'b0;

endmodule
