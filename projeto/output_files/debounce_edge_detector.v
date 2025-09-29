module debounce_edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire button_in,
    output reg  tick
);

    // Parâmetro para o tempo de debounce (ajustável)
    // Para um clock de 25MHz, 250000 ciclos ~= 10ms
    parameter DEBOUNCE_LIMIT = 250000;

    // Registradores para o estado do botão e contador
    reg [17:0] debounce_counter = 0;
    reg        button_state = 0;
    reg        prev_button_state = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            debounce_counter  <= 0;
            button_state      <= 0;
            prev_button_state <= 0;
            tick              <= 0;
        end else begin
            // Armazena o estado anterior do botão estável
            prev_button_state <= button_state;
            
            // Sempre reseta o pulso de saída após um ciclo
            tick <= 0; 

            if (button_in != button_state) begin
                // Se o sinal de entrada mudar, reinicia o contador
                debounce_counter <= 0;
            end else if (debounce_counter < DEBOUNCE_LIMIT) begin
                // Se o sinal estiver estável, incrementa o contador
                debounce_counter <= debounce_counter + 1;
            end else begin
                // Se o contador atingiu o limite, o sinal é considerado estável
                // e o estado é atualizado.
                prev_button_state <= button_state;
                button_state <= button_in;
                
                // Detecta a borda de subida (0 -> 1) no botão estável
                if (button_state == 1 && prev_button_state == 0) begin
                    tick <= 1; // Gera o pulso de um ciclo
                end
            end
        end
    end
endmodule