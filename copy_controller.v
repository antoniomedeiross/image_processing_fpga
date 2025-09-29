module copy_controller (
    input wire clk,
    input wire reset,
    // ROM interface
    output reg [14:0] rom_addr,   // 160*120 = 19200 pixels
    input wire [7:0] rom_data,
    // RAM interface
    output reg [18:0] ram_addr,   // 640*480 = 307200 pixels
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    // Parâmetros da imagem
    localparam IMG_W = 160;
    localparam IMG_H = 120;
    localparam OFFSET_X = 240;  // centralizado
    localparam OFFSET_Y = 180;

    reg [7:0] x;
    reg [6:0] y;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rom_addr <= 15'd0;
            ram_addr <= 19'd0;
            ram_data <= 8'd0;
            ram_wren <= 1'b0;
            done     <= 1'b0;
            x <= 8'd0;
            y <= 7'd0;
        end else if (!done) begin
            // Escreve o pixel da ROM na RAM centralizada
            rom_addr <= y * IMG_W + x;
            ram_addr <= (y + OFFSET_Y) * 640 + (x + OFFSET_X);
            ram_data <= rom_data;
            ram_wren <= 1'b1;

            // Avança posição
            if (x == IMG_W-1) begin
                x <= 0;
                if (y == IMG_H-1) begin
                    done <= 1'b1;   // terminou a cópia
                    ram_wren <= 1'b0;
                end else begin
                    y <= y + 1;
                end
            end else begin
                x <= x + 1;
            end
        end else begin
            ram_wren <= 1'b0; // desliga escrita depois da cópia
        end
    end
endmodule
