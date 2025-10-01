# Digital Zoom: Image Resizing with FPGA in Verilog (DE1-SoC)

## Descrição do Projeto

Este projeto tem como objetivo o desenvolvimento de um coprocessador gráfico para redimensionamento de imagens utilizando a placa DE1-SoC, com implementação em Verilog. O sistema é capaz de aplicar zoom in (ampliação) e zoom out (redução) em imagens em escala de cinza, simulando técnicas básicas de interpolação visual.

O controle do sistema é feito por meio de chaves e botões da placa, possibilitando ao usuário selecionar entre diferentes algoritmos de redimensionamento, tanto para ampliação quanto para redução da imagem. Além disso, o projeto foi desenvolvido com foco na compatibilidade futura com o HPS (Hard Processor System) da DE1-SoC, o que permitirá a expansão para arquiteturas híbridas de hardware-software nas próximas etapas.

Este repositório reúne os códigos-fonte, scripts e documentação completa do trabalho, incluindo instruções de instalação, configuração do ambiente, testes realizados e análise dos resultados obtidos.

## Objetivos

- Desenvolver um **coprocessador gráfico** capaz de redimensionar imagens diretamente na FPGA, sem auxílio de processadores externos.
- Implementar os algoritmos de **zoom in** (ampliação) e **zoom out** (redução) em Verilog:
  - Vizinho Mais Próximo (Nearest Neighbor)
  - Replicação de Pixel (Pixel Replication)
  - Decimação (Downsampling)
  - Média de Blocos (Block Averaging)
- Utilizar apenas os recursos disponíveis na placa **DE1-SoC**, explorando saída VGA, chaves e botões para controle.
- Garantir a **compatibilidade futura com o HPS (Hard Processor System)** da DE1-SoC.
- Documentar todo o processo de desenvolvimento, incluindo requisitos, ambiente de teste, instalação e análise de resultados.

## Funcionalidades

- Redimensionamento de imagens em escala de cinza (8 bits por pixel).  
- Suporte a **zoom in (2x e 4x)** com dois algoritmos:  
  - Vizinho Mais Próximo (Nearest Neighbor)  
  - Replicação de Pixel (Pixel Replication)  
- Suporte a **zoom out (1/2x e 1/4x)** com dois algoritmos:  
  - Decimação (Downsampling)  
  - Média de Blocos (Block Averaging)  
- Controle do modo de operação via **chaves e botões da placa DE1-SoC**.  
- Saída de vídeo pela porta **VGA** da placa.  
- Compatibilidade futura com o **HPS (ARM Hard Processor System)** para integração com software.  


## Sumário

* [Arquitetura Geral do Projeto](#arquitetura-geral-do-projeto)
* [ULA dos Algoritmos](#ula-dos-algoritmos)
* [Algoritmos de Interpolação](#algoritmos-de-interpolação)
  * [Replicação de Pixel](#replicação-de-pixel)
  * [Média de Blocos](#média-de-blocos)
  * [Vizinho Mais Próximo](#vizinho-mais-próximo)
* [Testes](#testes)
* [Referências](#referências)

## Arquitetura Geral do Projeto
... conteúdo aqui ...

## ULA dos Algoritmos
  ?


## Algoritmos de Interpolação

###  Replicação de Pixel

O algoritmo de **Replicação de Pixel** é uma técnica de ampliação de imagem (zoom in) onde cada pixel da imagem original é copiado para formar um bloco de pixels na imagem de destino. É um dos métodos mais simples e rápidos de implementar em hardware, pois não exige cálculos complexos como interpolação.

Neste projeto, o algoritmo suporta três modos:
* **1x (Cópia Direta):** A imagem é copiada para o centro da tela, sem alteração de tamanho.
* **2x (Ampliação):** Cada pixel da imagem original é replicado para um bloco de 2x2 pixels na imagem de saída.
* **4x (Ampliação):** Cada pixel da imagem original é replicado para um bloco de 4x4 pixels na imagem de saída.

O funcionamento é controlado por uma Máquina de Estados Finitos (FSM) que gerencia o fluxo de leitura da imagem original (armazenada em ROM) e escrita na memória de vídeo (RAM), que será exibida no monitor VGA.

#### Diagrama Conceitual (Zoom 2x)

A lógica para um zoom de 2x pode ser visualizada da seguinte forma: um único pixel `P(x, y)` da imagem original é usado para preencher quatro posições na imagem ampliada.

---

![Lógica de replicação de pixels](src/replicacao.drawio.png)  
*Figura 1 — Diagrama da Lógica de replicação de pixels.*

---

#### Detalhamento da Máquina de Estados (FSM)

A FSM implementada em Verilog segue um fluxo lógico para garantir que a imagem seja processada corretamente, desde a inicialização até a conclusão.

1.  **Estado de Inicialização (`S_IDLE`)**
    * **Função:** Prepara o sistema para o processamento. Zera os contadores de pixels (`pixel_counter`), o endereço da RAM (`ram_counter`) e a variável de controle `zoom_phase`.
    * **Fluxo:** O estado verifica qual o modo de zoom selecionado (`zoom_enable`).
        * Se for **1x** (`3'b000`), a FSM transita para `S_CLEAR_BORDERS`, pois apenas as bordas da tela precisam ser limpas.
        * Se for **2x** ou **4x**, a imagem de saída será maior que a original, ocupando uma área diferente. Para evitar "lixo" visual de processamentos anteriores, a FSM transita para `S_CLEAR_ALL` para limpar toda a tela.

2.  **Estados de Limpeza de Tela (`S_CLEAR_ALL` e `S_CLEAR_BORDERS`)**
    * **`S_CLEAR_ALL` (Modos 2x e 4x):** Este estado varre toda a RAM de vídeo, escrevendo o valor `8'h00` (preto) em cada posição. Isso garante que a tela esteja completamente preta antes de desenhar a imagem ampliada. Ao final, avança para `S_SET_ADDR`.
    * **`S_CLEAR_BORDERS` (Modo 1x):** Em vez de limpar toda a tela, este estado percorre a RAM e escreve preto apenas nas áreas que não serão ocupadas pela imagem original. A imagem é centralizada usando offsets (`NO_ZOOM_OFFSET_X`, `NO_ZOOM_OFFSET_Y`), e qualquer pixel fora dessa janela central é apagado. Isso é uma otimização para evitar a reescrita desnecessária da área da imagem. Ao final, avança para `S_SET_ADDR`.

3.  **Ciclo de Leitura e Escrita**
    * **`S_SET_ADDR`:** Define o endereço do pixel da imagem original que será lido da ROM, usando o `pixel_counter`.
    * **`S_READ_ROM`:** Lê o dado de 8 bits (nível de cinza) do endereço fornecido e o armazena em um registrador temporário (`rom_data_reg`).
    * **`S_WRITE_RAM`:** Este é o coração do algoritmo de replicação. A lógica de escrita na RAM de vídeo depende do modo de zoom:
        * **Modo 1x:** O pixel lido é escrito em uma única posição na RAM, calculada com base nas suas coordenadas originais mais um offset de centralização. A FSM então avança para ler o próximo pixel (`pixel_counter` é incrementado).
        * **Modo 2x (`zoom_enable == 3'b001`):** Para cada pixel lido da ROM, a FSM permanece no estado `S_WRITE_RAM` por **4 ciclos de clock**. A cada ciclo, a variável `zoom_phase` (de 0 a 3) é usada para calcular o endereço de um dos quatro pixels do bloco 2x2 de destino. O *mesmo valor* do pixel original (`rom_data_reg`) é escrito em todas as quatro posições. Após a quarta escrita, `pixel_counter` é incrementado e o ciclo recomeça para o próximo pixel da ROM.
        * **Modo 4x (`zoom_enable == 3'b010`):** A lógica é similar ao modo 2x, mas expandida. A FSM permanece no estado `S_WRITE_RAM` por **16 ciclos de clock**. A variável `zoom_phase` (de 0 a 15) ajuda a calcular o endereço de cada um dos 16 pixels do bloco 4x4 de destino. Após as 16 escritas do mesmo pixel, o sistema avança para o próximo pixel da imagem original.

4.  **Estado de Conclusão (`S_DONE`)**
    * **Função:** Após todos os pixels da ROM terem sido processados (`pixel_counter` atingiu o valor máximo), a FSM entra neste estado.
    * **Ação:** Sinaliza que o processo de redimensionamento foi concluído ativando a flag `done`. O sistema permanece neste estado até que um novo comando de redimensionamento seja iniciado.

### Diagrama de Transição de Estados

---

![Diagrama de estados do algoritmo de replicação](src/diagrama_estados_replicacao.drawio.png)  
*Figura x — Diagrama de estados do algoritmo de replicação de pixels.*

---

### Resultados
O algoritmo foi funcional em todos os modos propostos (1x, 2x e 4x), com o controle de seleção via chaves da placa respondendo em tempo real.

#### Análise Visual

![Funcionamento do algoritmo média de replicação — saída VGA.](src/replicacao_gif.gif)

O coprocessador executou a replicação em **tempo real**. A arquitetura da máquina de estados, operando em sincronia com o clock do sistema(25 MHz), garantiu que a imagem fosse processada e escrita na memória de vídeo de forma determinística e com latência mínima. Não houve qualquer tipo de atraso ou "tearing" visível no monitor, validando a eficiência da implementação em hardware.

 **Consumo de Recursos de Hardware:** Uma das principais vantagens deste algoritmo é sua simplicidade, que se traduziu diretamente em um baixo consumo de recursos da FPGA. Mais importante, o design **não necessitou de multiplicadores ou divisores de hardware**, que são componentes caros em termos de área no chip. Isso confirma que a Replicação de Pixel é uma solução extremamente econômica para ampliação de imagens quando a qualidade visual não é o fator crítico.
 
Em suma, os resultados validam que a implementação em hardware do algoritmo de Replicação de Pixel na DE1-SoC foi um sucesso, operando com alta performance e baixo custo de recursos, ao mesmo tempo que demonstrou as conhecidas limitações de qualidade visual inerentes a este método de ampliação



### MÉDIA DE BLOCOS

O algoritmo de **Média de Blocos** é utilizado no modo **zoom out**, reduzindo a resolução da imagem por meio da substituição de grupos de pixels pela média aritmética de suas intensidades.  
Essa abordagem gera uma redução mais suave em comparação com a decimação simples, preservando melhor a informação luminosa da região.

---

#### Conceito Teórico

O método consiste em calcular a média dos pixels de um bloco da imagem original e atribuir esse valor a um único pixel da imagem reduzida.

- **Para blocos 2×2 (redução de 0.5x):**

P' = (p00 + p01 + p10 + p11) / 4


- **Para blocos 4×4 (redução de 0.25x):**

P' = ( Σ(i=0→3) Σ(j=0→3) p_ij ) / 16


Onde \(p_{ij}\) representa os valores de intensidade (8 bits) dos pixels originais.

---

#### Implementação em Verilog

A **Média de Blocos** foi implementada por meio de uma **FSM (Máquina de Estados)**, responsável por coordenar a leitura da ROM, o cálculo da média e a escrita no framebuffer da RAM.  
Cada estado possui uma função clara, garantindo que o processo seja realizado de forma sequencial e controlada.

---

#### Fluxo da FSM

- **S_IDLE** → Estado inicial. Reseta os registradores e prepara o sistema.  
- **S_CLEAR_FRAME** → Limpa o framebuffer (preto `8'h00`) para exibir apenas a imagem processada.  
- **S_PROCESS_PIXEL** → Define o modo de operação (1x, 0.5x ou 0.25x) e aciona a sequência de leitura:  
  - **1x (normal):** copia o pixel da ROM.  
  - **0.5x (2×2):** ativa a leitura de 4 pixels.  
  - **0.25x (4×4):** ativa a leitura de 16 pixels.  

##### Modo 1x
- **S_FETCH_PIXEL_READ** → Calcula o endereço na ROM e copia o valor direto para a RAM.  

##### Modo 0.5x (Blocos 2×2)
Sequência de 4 leituras:  
- **S_FETCH_BLOCK_00** → pixel superior esquerdo \((x,y)\).  
- **S_FETCH_BLOCK_01** → pixel superior direito \((x+1,y)\).  
- **S_FETCH_BLOCK_10** → pixel inferior esquerdo \((x,y+1)\).  
- **S_FETCH_BLOCK_11** → pixel inferior direito \((x+1,y+1)\).  
- **S_CALC_AVERAGE_4** → calcula a média dos quatro pixels.  

##### Modo 0.25x (Blocos 4×4)
Sequência de 16 leituras:  
- **S_FETCH_16_INIT** → zera acumuladores e contadores de bloco.  
- **S_FETCH_16_SET_ADDR** → calcula o endereço do próximo pixel.  
- **S_FETCH_16_READ_ADD** → lê o pixel e acumula em `sum_pixels`.  
- **S_WRITE_RAM_AVG** → escreve na RAM a média dos 16 pixels.  

##### Estado Final
- **S_DONE** → sinaliza a conclusão do processamento.

---

#### Diagrama da FSM

![Diagrama da FSM da Média de Blocos](src/diagrama_bloco.jpg)  
*Figura 1 — Diagrama da FSM para Média de Blocos. Estados e transições principais.*

---

#### Cálculo de Endereços

O acesso à ROM é feito convertendo coordenadas 2D em índice linear:

rom_addr_out = y * ROM_IMG_W + x

- **x** → coordenada horizontal (coluna)
- **y** → coordenada vertical (linha)
- **ROM_IMG_W** → largura da imagem em pixels
- 
Esse cálculo garante que o pixel correto seja acessado em cada ciclo, tanto no modo normal quanto nos blocos 2×2 e 4×4.


---

#### Offsets e Centralização

A imagem da ROM (160×120) é menor que a resolução VGA (640×480).  
Foi necessário centralizar a imagem com deslocamentos fixos:

- `NORMAL_OFFSET_X, NORMAL_OFFSET_Y` → imagem normal.  
- `ZOOM_OUT_OFFSET_X, ZOOM_OUT_OFFSET_Y` → centralização no zoom out 0.5x.  
- `ZOOM_OUT_025_OFFSET_X, ZOOM_OUT_025_OFFSET_Y` → centralização no zoom out 0.25x.  

---

#### Resultados

O algoritmo de **Média de Blocos** gera imagens reduzidas mais suaves em comparação com a decimação simples, pois considera todos os pixels da região.

Foram realizados testes nos três modos principais, exibidos na saída VGA:

- **Normal (1x)**  
- **Zoom Out 0.5x (2×2)**  
- **Zoom Out 0.25x (4×4)**  

![Funcionamento do algoritmo média de blocos — saída VGA.](src/media.gif)




## Vizinho Mais Próximo

O algoritmo de redimensionamento de imagens Vizinho Mais Próximo realiza operações de **zoom in** (aumentar) e **zoom out** (diminuir) em tempo real, lendo uma imagem da memória ROM e escrevendo o resultado em um framebuffer (RAM) para mostrar em um monitor VGA.

## Visão Geral

O algoritmo Vizinho Mais Próximo é uma técnica simples e rápida para redimensionar imagens, ideal para hardware como FPGAs porque não precisa de cálculos complicados. A ideia básica é: para cada ponto na nova imagem, encontrar o pixel mais próximo na imagem original e copiar sua cor.

O projeto usa **Máquinas de Estados Finitos (FSM)** para controlar o fluxo de dados entre a ROM (imagem original) e a RAM (imagem de saída).

## Características Principais

- **Rápido e Simples**: Não faz cálculos complexos
- **Controle por FSM**: Gerencia leitura, processamento e escrita dos pixels
- **Zoom In e Zoom Out**: Suporta aumentar (2x, 4x) e diminuir (0.5x, 0.25x)
- **Centralizado**: Imagem sempre no centro da tela VGA (640x480)

## Como Funciona

O algoritmo mapeia cada pixel da imagem final `(x_out, y_out)` para sua posição correspondente `(x_in, y_in)` na imagem original:

### Versão 1 – Zoom In

Esta versão foca exclusivamente na ampliação da imagem. Sua lógica é: ela lê um pixel da imagem original (ROM) e o replica múltiplas vezes em um bloco na imagem de destino (RAM).

#### Diagrama da FSM (Versão 1)

O fluxo de controle desta versão é representado pelo seguinte diagrama:

*Figura 1 — Diagrama da FSM para ampliação (Zoom In) por replicação de pixels.*

#### Fluxo da FSM (Versão 1)

1. **S_IDLE**: Estado inicial que reseta contadores e flags.
2. **S_CLEAR_ALL / S_CLEAR_BORDERS**: Limpa o framebuffer (toda a tela para zoom, ou apenas as bordas para o modo 1x).
3. **S_SET_ADDR**: Aponta para o endereço do próximo pixel a ser lido na ROM.
4. **S_READ_ROM**: Lê o dado do pixel e o armazena em um registrador.
5. **S_WRITE_RAM**: Escreve o pixel lido na RAM. Este é o estado principal do zoom, onde a FSM pode permanecer por vários ciclos (controlado por `zoom_phase`) para escrever o mesmo pixel em diferentes posições do bloco de destino.
6. **S_DONE**: Sinaliza o fim do processamento.

#### Modos de Operação:

- **Normal (1x)**: Cópia 1:1 da ROM para a RAM.
- **Zoom 2x**: Cada pixel da ROM é replicado em um bloco 2x2 na RAM.
- **Zoom 4x**: Cada pixel da ROM é replicado em um bloco 4x4 na RAM.

# Versão 2: Zoom Out

Diferente da versão anterior, aqui a máquina de estados percorre cada pixel do framebuffer de destino na RAM e "puxa" o pixel correspondente da memória ROM usando um cálculo de mapeamento reverso.

## Diagrama da FSM (Versão 2)

*Figura 2 — Diagrama da máquina de estados para modo Normal e Zoom Out.*

## Fluxo de Operação da FSM (Versão 2)

1. **VZ05_IDLE**: Estado inicial que prepara o contador da RAM para começar a leitura do framebuffer.

2. **VZ05_CLEAR_FRAME**: Realiza a limpeza completa do framebuffer, preenchendo toda a área com a cor preta para remover qualquer resíduo de imagens anteriores.

3. **VZ05_PROCESS_PIXEL**: Etapa principal do algoritmo. Examina cada pixel da RAM sequencialmente:
   - Confirma se o pixel atual está dentro da região ativa da imagem
   - Se estiver fora dos limites: simplesmente avança para o próximo pixel
   - Se estiver dentro: calcula as coordenadas correspondentes na imagem original e busca o pixel

4. **VZ05_SET_ROM_ADDR**: Transforma as coordenadas bidimensionais (`src_x`, `src_y`) em um endereço unidimensional para acessar a ROM.

5. **VZ05_READ_ROM**: Realiza a leitura do valor do pixel no endereço calculado da memória ROM.

6. **VZ05_WRITE_RAM**: Grava o pixel obtido da ROM na posição atual do framebuffer de destino.

7. **VZ05_DONE**: Estado final que indica a conclusão do processamento depois que todos os pixels foram analisados.

## Modos de Funcionamento Suportados

- **Modo Normal (1x)**: Realiza uma cópia direta pixel a pixel da imagem original, aplicando apenas os ajustes de posicionamento para centralização na tela.

- **Zoom Out 0.5x e 0.25x**: A redução de tamanho acontece de forma natural através do processo de subamostragem. Durante o cálculo das coordenadas, múltiplos pixels da imagem original são ignorados, resultando em uma versão menor da imagem.

> **Observação Importante**: As operações de Zoom In (aumento) são gerenciadas apenas pela Versão 1 deste projeto, que utiliza uma técnica diferente mais adequada para esse tipo de operação.


## Resultados Gerais da Implementação do Projeto
  - falar do erro da  borda
  - falar do erro ao mudar algoritmos rapido
  - falar dos resto
