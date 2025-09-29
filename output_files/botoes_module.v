module botoes_module (
    input clk,                // Clock signal
    input rst,                // Reset signal (ativo em alto)
    input [2:0] escolha_alg,  // Algorithm choice
    input but_zoom_in,        // Zoom in button
    input but_zoom_out,       // Zoom out button
    
    // Saida da escala escolhida
    output reg [2:0] escolhido // Chosen scale
);

    // Registrador para o estado da máquina
    reg [2:0] estado_atual;
    reg [2:0] proximo_estado;

    // --- Definição dos Estados (Parâmetros) ---
    // A largura [2:0] agora corresponde ao registrador de estado
    localparam [2:0] ESTADO_1X   = 3'b000;
    localparam [2:0] ESTADO_2X   = 3'b001;
    localparam [2:0] ESTADO_4X   = 3'b010;
    localparam [2:0] ESTADO_05X  = 3'b011;
    localparam [2:0] ESTADO_025X = 3'b100;

    // --- Lógica de Detecção de Borda (Pulso) ---
    // Registradores para guardar o estado anterior dos botões e da seleção
    reg but_zoom_in_prev;
    reg but_zoom_out_prev;
    reg [2:0] escolha_alg_prev;

    // Wires para indicar um pulso (clique) ou mudança
    wire zoom_in_pulse;
    wire zoom_out_pulse;
    wire escolha_alg_changed;

    // Gera um pulso de 1 ciclo de clock quando o botão é pressionado (borda de subida)
    // Assumindo botões ativos em alto. Se forem ativos em baixo, use:
    // assign zoom_in_pulse = !but_zoom_in && but_zoom_in_prev;
		assign zoom_in_pulse = !but_zoom_in && but_zoom_in_prev;
		assign zoom_out_pulse = !but_zoom_out && but_zoom_out_prev;
		assign escolha_alg_changed = (escolha_alg != escolha_alg_prev);

    // --- Bloco Sequencial (Registradores) ---
    // Este bloco atualiza o estado atual e os registradores de detecção de borda
    always @(posedge clk or posedge !rst) begin
        if (!rst) begin
            // Estado inicial quando o reset é ativado
            estado_atual       <= ESTADO_1X;
            escolhido          <= ESTADO_1X;
            but_zoom_in_prev   <= 1'b0;
            but_zoom_out_prev  <= 1'b0;
            escolha_alg_prev   <= 3'b0;
        end else begin
            // Em cada ciclo de clock, atualiza os valores
            estado_atual       <= proximo_estado;
            escolhido          <= proximo_estado; // A saída reflete o novo estado
            but_zoom_in_prev   <= but_zoom_in;
            but_zoom_out_prev  <= but_zoom_out;
            escolha_alg_prev   <= escolha_alg;
        end
    end

    // --- Bloco Combinacional (Lógica de Próximo Estado) ---
    // Este bloco decide qual será o próximo estado com base no estado atual e nas entradas
    always @(*) begin
        // Por padrão, o próximo estado é o estado atual
        proximo_estado = estado_atual; 
        
        // A mudança de algoritmo tem a maior prioridade e reseta o zoom
        if (escolha_alg_changed) begin
            proximo_estado = ESTADO_1X;
        end 
        // Se houve um clique em zoom_in, avança o estado
        else if (zoom_in_pulse) begin
            case (estado_atual)
                ESTADO_1X:   proximo_estado = ESTADO_2X;
                ESTADO_2X:   proximo_estado = ESTADO_4X;
                ESTADO_4X:   proximo_estado = ESTADO_4X; // Já está no máximo
                ESTADO_05X:  proximo_estado = ESTADO_1X;
                ESTADO_025X: proximo_estado = ESTADO_05X;
                default:     proximo_estado = ESTADO_1X;
            endcase
        end
        // Se houve um clique em zoom_out, retrocede o estado
        else if (zoom_out_pulse) begin
            case (estado_atual)
                ESTADO_1X:   proximo_estado = ESTADO_05X;
                ESTADO_2X:   proximo_estado = ESTADO_1X;
                ESTADO_4X:   proximo_estado = ESTADO_2X;
                ESTADO_05X:  proximo_estado = ESTADO_025X;
                ESTADO_025X: proximo_estado = ESTADO_025X; // Já está no mínimo
                default:     proximo_estado = ESTADO_1X;
            endcase
        end
    end

endmodule