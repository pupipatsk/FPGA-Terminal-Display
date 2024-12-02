`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2024 12:24:42 AM
// Design Name: 
// Module Name: vga_text
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


module vga_sync(
    input wire clk, reset,
    output wire hsync, vsync, video_on, p_tick,
    output wire [9:0] x, y
    );
    // constant declarations for VGA sync parameters
    localparam H_DISPLAY       = 640; // horizontal display area
    localparam H_L_BORDER      =  48; // horizontal left border
    localparam H_R_BORDER      =  16; // horizontal right border
    localparam H_RETRACE       =  96; // horizontal retrace
    localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
    localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
    localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;

    localparam V_DISPLAY       = 480; // vertical display area
    localparam V_T_BORDER      =  10; // vertical top border
    localparam V_B_BORDER      =  33; // vertical bottom border
    localparam V_RETRACE       =   2; // vertical retrace
    localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
    localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
    localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;

    // mod-4 counter to generate 25 MHz pixel tick
    reg [1:0] pixel_reg;
    wire [1:0] pixel_next;
    wire pixel_tick;

    always @(posedge clk, posedge reset)
        if(reset) pixel_reg <= 0;
        else pixel_reg <= pixel_next;

    assign pixel_next = pixel_reg + 1; // increment pixel_reg 

    assign pixel_tick = (pixel_reg == 0); // assert tick 1/4 of the time

    // registers to keep track of current pixel location
    reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
    
    // register to keep track of vsync and hsync signal states
    reg vsync_reg, hsync_reg;
    wire vsync_next, hsync_next;

    // infer registers
    always @(posedge clk, posedge reset)
        if(reset) begin
            v_count_reg <= 0;
            h_count_reg <= 0;
            vsync_reg   <= 0;
            hsync_reg   <= 0;
        end
        else begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            vsync_reg   <= vsync_next;
            hsync_reg   <= hsync_next;
        end
        
    // next-state logic of horizontal vertical sync counters
    always @* begin
        h_count_next = pixel_tick ? 
                       h_count_reg == H_MAX ? 0 : h_count_reg + 1
                     : h_count_reg;
        
        v_count_next = pixel_tick && h_count_reg == H_MAX ? 
                       (v_count_reg == V_MAX ? 0 : v_count_reg + 1) 
                     : v_count_reg;
    end
    
    // hsync and vsync are active low signals
    // hsync signal asserted during horizontal retrace
    assign hsync_next = (h_count_reg >= START_H_RETRACE) && (h_count_reg <= END_H_RETRACE);

    // vsync signal asserted during vertical retrace
    assign vsync_next = (v_count_reg >= START_V_RETRACE) && (v_count_reg <= END_V_RETRACE);

    // video only on when pixels are in both horizontal and vertical display region
    assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);

    // output signals
    assign hsync  = hsync_reg;
    assign vsync  = vsync_reg;
    assign x      = h_count_reg;
    assign y      = v_count_reg;
    assign p_tick = pixel_tick;
endmodule


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
            if(char == "\r" || char == "\n") begin // new line
                char_n <= (char_n/NUM_CHARS_X) * NUM_CHARS_X + NUM_CHARS_X;
            end else begin
                if(char >= 32 && char <= 126) begin // add character
                    text[char_n] <= char;
                    char_n <= char_n + 1;
                end
            end
        end
        if(char_n >= NUM_CHARS_X*NUM_CHARS_Y) begin // clear when page full
            char_n <= 0;
            for (i = 0; i < NUM_CHARS_X*NUM_CHARS_Y; i = i + 1) begin
              text[i] = "";
            end
        end
        last_rec = en;
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



