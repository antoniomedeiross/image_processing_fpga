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
