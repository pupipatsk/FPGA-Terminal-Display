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

    // Rectangle parameters
    parameter RECT_X_START = 100;  // X-coordinate start position
    parameter RECT_Y_START = 100;  // Y-coordinate start position
    parameter RECT_WIDTH = 200;    // Width of the rectangle
    parameter RECT_HEIGHT = 150;   // Height of the rectangle

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
            if (char == "\r" || char == "\n") begin // New line
                char_n <= (char_n / NUM_CHARS_X) * NUM_CHARS_X + NUM_CHARS_X;
            end else begin
                if (char >= 32 && char <= 126) begin // Supported ASCII range
                    text[char_n] <= char;
                    char_n <= char_n + 1;
                end else begin
                    text[char_n] <= 8'd45; // ASCII code for '-'
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

    // Determine color of the pixel, including rectangle drawing
    always @(posedge p_tick) begin
        if (video_on) begin
            if ((x >= RECT_X_START) && (x < RECT_X_START + RECT_WIDTH) &&
                (y >= RECT_Y_START) && (y < RECT_Y_START + RECT_HEIGHT)) begin
                rgb_reg = 12'b1111_0000_0000;  // Red color for the rectangle
            end
            else if (char_pixel) begin
                rgb_reg = 12'b1111_1111_1111;  // White color for text
            end
            else begin
                rgb_reg = 12'b0; // Black background
            end
        end
        else begin
            rgb_reg = 12'b0; // Black outside the visible area
        end
    end

    // output
    assign rgb = rgb_reg;

endmodule
