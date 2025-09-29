module vizinho_mais_prox (
    input  wire        clk,
    input  wire        reset,
    input  wire        zoom_enable,

    // Interface com a ROM (síncrona)
    input  wire [7:0]  rom_data_in,
    output reg  [14:0] rom_addr_out,

    // Interface com a RAM (framebuffer 640x480)
    output reg  [7:0]  ram_data_out,
    output reg  [18:0] ram_addr_out,
    output reg         ram_wren_out,

    // Status
    output reg         done
);
    // Parâmetros da imagem original
    localparam ROM_IMG_W = 160;
    localparam ROM_IMG_H = 120;
    localparam ROM_SIZE = ROM_IMG_W * ROM_IMG_H;

    // Parâmetros da RAM
    localparam RAM_WIDTH = 640;
    localparam RAM_HEIGHT = 480;
    localparam RAM_SIZE = RAM_WIDTH * RAM_HEIGHT;

    // Zoomed params
    localparam ZOOM_OFFSET_X = 160; // (640 - 320)/2
    localparam ZOOM_OFFSET_Y = 120; // (480 - 240)/2

    // No-zoom offsets
    localparam NO_ZOOM_OFFSET_X = 240; // (640 - 160)/2
    localparam NO_ZOOM_OFFSET_Y = 180; // (480 - 120)/2

    // Registros
    reg [14:0] pixel_counter;
    reg [18:0] ram_counter;
    reg [1:0] zoom_phase;
    reg [7:0] rom_x;
    reg [6:0] rom_y;
    reg [7:0] rom_data_reg;
    
    // Registros para coordenadas atuais
    reg [9:0] current_x;
    reg [8:0] current_y;
    
    // FSM states
    localparam S_IDLE            = 3'd0;
    localparam S_CLEAR_BORDERS   = 3'd1;
    localparam S_SET_ADDR        = 3'd2;
    localparam S_READ_ROM        = 3'd3;
    localparam S_WRITE_RAM       = 3'd4;
    localparam S_DONE            = 3'd5;
    reg [2:0] state;

    // Calcula coordenadas X/Y a partir do contador
    always @(*) begin
        rom_x = pixel_counter % ROM_IMG_W;
        rom_y = pixel_counter / ROM_IMG_W;
    end

    // Calcula coordenadas atuais da RAM
    always @(*) begin
        current_x = ram_counter % RAM_WIDTH;
        current_y = ram_counter / RAM_WIDTH;
    end

    // Máquina de estados principal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            pixel_counter <= 0;
            ram_counter <= 0;
            zoom_phase <= 0;
            done <= 1'b0;
            rom_data_reg <= 8'd0;
            ram_wren_out <= 1'b0;
            rom_addr_out <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    pixel_counter <= 0;
                    ram_counter <= 0;
                    zoom_phase <= 0;
                    done <= 1'b0;
                    ram_wren_out <= 1'b0;
                    
                    if (!zoom_enable) begin
                        // Modo sem zoom: primeiro limpa as bordas
                        state <= S_CLEAR_BORDERS;
                    end else begin
                        // Modo zoom: vai direto para copiar a imagem
                        state <= S_SET_ADDR;
                    end
                end

                S_CLEAR_BORDERS: begin
                    // Verifica se está fora da área da imagem
                    if (current_y < NO_ZOOM_OFFSET_Y || 
                        current_y >= NO_ZOOM_OFFSET_Y + ROM_IMG_H ||
                        current_x < NO_ZOOM_OFFSET_X || 
                        current_x >= NO_ZOOM_OFFSET_X + ROM_IMG_W) begin
                        
                        // Escreve preto nas bordas
                        ram_wren_out <= 1'b1;
                        ram_data_out <= 8'h00; // Preto
                        ram_addr_out <= ram_counter;
                    end else begin
                        // Dentro da área da imagem, desabilita escrita
                        ram_wren_out <= 1'b0;
                    end
                    
                    if (ram_counter < RAM_SIZE - 1) begin
                        ram_counter <= ram_counter + 1;
                        state <= S_CLEAR_BORDERS;
                    end else begin
                        // Terminou de limpar bordas, agora copia a imagem
                        ram_counter <= 0;
                        state <= S_SET_ADDR;
                    end
                end

                S_SET_ADDR: begin
                    // Configura endereço da ROM
                    rom_addr_out <= pixel_counter;
                    state <= S_READ_ROM;
                end

                S_READ_ROM: begin
                    // Espera 1 ciclo pela ROM (dado disponível agora)
                    rom_data_reg <= rom_data_in;
                    state <= S_WRITE_RAM;
                end

                S_WRITE_RAM: begin
                    ram_wren_out <= 1'b1;
                    ram_data_out <= rom_data_reg;
                    
                    if (zoom_enable) begin
                        // Modo ZOOM - Escreve 4 pixels
                        case(zoom_phase)
                            2'b00: ram_addr_out <= ((rom_y * 2) + 0 + ZOOM_OFFSET_Y) * RAM_WIDTH + 
                                                  ((rom_x * 2) + 0 + ZOOM_OFFSET_X);
                            2'b01: ram_addr_out <= ((rom_y * 2) + 0 + ZOOM_OFFSET_Y) * RAM_WIDTH + 
                                                  ((rom_x * 2) + 1 + ZOOM_OFFSET_X);
                            2'b10: ram_addr_out <= ((rom_y * 2) + 1 + ZOOM_OFFSET_Y) * RAM_WIDTH + 
                                                  ((rom_x * 2) + 0 + ZOOM_OFFSET_X);
                            2'b11: ram_addr_out <= ((rom_y * 2) + 1 + ZOOM_OFFSET_Y) * RAM_WIDTH + 
                                                  ((rom_x * 2) + 1 + ZOOM_OFFSET_X);
                        endcase
                        
                        if (zoom_phase == 2'b11) begin
                            // Terminou todas as 4 fases deste pixel
                            zoom_phase <= 2'b00;
                            if (pixel_counter < ROM_SIZE - 1) begin
                                pixel_counter <= pixel_counter + 1;
                                state <= S_SET_ADDR;
                            end else begin
                                state <= S_DONE;
                            end
                        end else begin
                            // Continua mesma fase
                            zoom_phase <= zoom_phase + 1;
                            state <= S_WRITE_RAM; // Permanece no mesmo estado
                        end
                    end else begin
                        // Modo SEM ZOOM - Escreve 1 pixel
                        ram_addr_out <= (rom_y + NO_ZOOM_OFFSET_Y) * RAM_WIDTH + 
                                       (rom_x + NO_ZOOM_OFFSET_X);
                        
                        if (pixel_counter < ROM_SIZE - 1) begin
                            pixel_counter <= pixel_counter + 1;
                            state <= S_SET_ADDR;
                        end else begin
                            state <= S_DONE;
                        end
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    ram_wren_out <= 1'b0;
                    // Permanece em DONE até próximo reset
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule