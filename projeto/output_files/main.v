/*
	O00 1X
	001 2X
	010 4X
	011 0.5X
	100 0.25X
*/

module main (
    input  wire clock,         // 50 MHz
    input  wire reset,         // Active high
    input  wire [7:0] switches,    // switches[0] para controlar o zoom
	 input wire but,
    input but_zoom_in,        // Zoom in button
    input but_zoom_out, 
    output wire hsync,         // HSYNC (to VGA connector)
    output wire vsync,         // VSYNC (to VGA connector)
    output wire [7:0] red,     // RED (to VGA connector)
    output wire [7:0] green,   // GREEN (to VGA connector)
    output wire [7:0] blue,    // BLUE (to VGA connector)
    output wire sync,          // SYNC to VGA connector
    output wire clk,           // CLK to VGA connector
    output wire blank,          // BLANK to VGA connector
	 
	 output wire [2:0] prop_zoom
);
	// butao zoom in 
	// butao zoom out
	
	/*
	   zoom in = rom -> alu -> ram -> vga
		zoom none = rom -> vga
		
	*/

	
	
    // Clock 25 MHz para VGA
    wire clk25;
    clk_divider clkdivide(
        .clk_in(clock),
        .clk_out(clk25)
    );

    // --- ROM: imagem original 160x120 ---
    wire [14:0] rom_addr;
    wire [7:0] rom_data;
    ram rom_inst (
        .address(rom_addr),
        .clock(clk25),
        .q(rom_data)
    );

    // --- RAM: framebuffer 640x480 (dual port) ---
    wire [18:0] vga_addr;
    wire [7:0] ram_q;
    wire [18:0] ram_wraddr;
    wire [7:0]  ram_data_to_write;
    wire        ram_wren;
    blocoram ram_inst (
        .clock(clk25),
        .data(ram_data_to_write),
        .rdaddress(vga_addr),
        .wraddress(ram_wraddr),
        .wren(ram_wren),
        .q(ram_q)
    );

    //----------------------------------------------------------------
    // NOVO Controlador: Copia da ROM -> aplica ZOOM -> escreve na RAM
    //----------------------------------------------------------------
    wire copy_done;
    //wire zoom_enable = {switches[1], switches[0]}; // Controla o zoom com a primeira chave
	
	wire [2:0] zoom_escolhido;
	botoes_module butoes(
		.clk(clk25),                // Clock signal
		.rst(but),                // Reset signal (ativo em alto)
		.escolha_alg(switches[6:3]),  // Algorithm choice
		.but_zoom_in(but_zoom_in),        // Zoom in button
		.but_zoom_out(but_zoom_out),       // Zoom out button
		
		 // Saida da escala escolhida
		.escolhido(prop_zoom	) // escala de zoom
	);
		
		
		wire reset_alu = !but_zoom_in | !but_zoom_out | !but;
	
    alu_algoritmos alu (
        .clk(clk25),
        .reset(reset_alu),
        .zoom_enable(prop_zoom),
		  .tipo_alg(switches[6:3]),
        // Interface com a ROM
        .rom_data_in(rom_data),
        .rom_addr_out(rom_addr),

        // Interface com a RAM
        .ram_data_out(ram_data_to_write),
        .ram_addr_out(ram_wraddr),
        .ram_wren_out(ram_wren),

        // Status
        .done(copy_done)
    );

    // --- Driver VGA: lê da RAM e gera sinais (sem alterações) ---
    wire [9:0] next_x, next_y;
    assign vga_addr = (next_y * 10'd640 + next_x);
    
    vga_driver vga_inst (
        .clock(clk25),
        .reset(reset),
        .color_in(ram_q),   // pixel vindo da RAM
        .next_x(next_x),    // coordenada X
        .next_y(next_y),    // coordenada Y
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue),
        .sync(sync),
        .clk(clk),
        .blank(blank)
    );

endmodule