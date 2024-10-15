
# Pong Game utilizando Lua

Este é um jogo simples de Pong desenvolvido em Lua usando a biblioteca LÖVE2D. 

## Requisitos

Certifique-se de que os seguintes itens estejam instalados e configurados no seu sistema para rodar o jogo:

1. **LÖVE2D**: 
   - Baixe e instale a versão mais recente em [love2d.org](https://love2d.org/).
   - Adicione o executável `love` ao `PATH` das variáveis de ambiente do sistema para facilitar a execução pelo terminal.

2. **Lua** (Opcional, apenas se desejar desenvolver ou modificar o código):
   - Baixe a versão mais recente de [Lua](https://luabinaries.sourceforge.net/download.html).
   - Adicione o Lua ao `PATH` das variáveis de ambiente do sistema.

3. **Editor de Código** (Recomendado):
   - Use um editor de código como o Visual Studio Code (VS Code).
   - No VS Code, instale a extensão "LOVE" e "Lua" para melhor integração.

4. **Configuração do Build Task (VS Code)**:
   - Para rodar o jogo usando `Ctrl+Shift+B`, configure uma task no VS Code:
     - Crie um arquivo `tasks.json` na pasta `.vscode` do projeto com o seguinte conteúdo:
     ```json
     {
       "version": "2.0.0",
       "tasks": [
         {
           "label": "Run LÖVE",
           "type": "shell",
           "command": "love .",
           "group": {
             "kind": "build",
             "isDefault": true
           },
           "problemMatcher": []
         }
       ]
     }
     ```

## Como Rodar a Aplicação

1. Clone este repositório ou faça o download dos arquivos do projeto.
2. Abra a pasta do projeto no Visual Studio Code.
3. Pressione `Ctrl+Shift+B` para compilar e executar o jogo usando a configuração de build criada.

## Controles

- **Jogador 1**:
  - `W` - Mover para cima
  - `S` - Mover para baixo
- **Jogador 2**:
  - `Seta para cima` - Mover para cima
  - `Seta para baixo` - Mover para baixo
- `Esc` - Sair do jogo
