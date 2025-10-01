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

   * [Arquitetura Geral do Projeto](#arquiterura_geral)
   * [ULA dos Algoritmos](#ula)
   * [Máquina de Estados dos Algoritmos](#maquina_estados_algoritmos)
      * [REPLICAÇÃO](#fetch)
      * [MÉDIA DE BLOCOS](#decode)
      * [DECIMAÇÃO](#execute)
      * [VIZINHO MAIS PROXIMO](#memory)
   * [Testes](#testes) 
   * [Referências](#referencias)

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

<figure style="text-align:center">
  <img src="src/media.gif" alt="GIF - Zoom Out 0.5x" width="600"/>
  <figcaption><strong>Figura 2:</strong> Funcionamento do algoritmo média de blocos — saída VGA.</figcaption>
</figure>
