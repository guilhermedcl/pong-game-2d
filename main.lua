push = require 'lib/push'

-- Obtém as dimensões da tela do computador
WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

-- Define a largura e altura da tela virtual (resolução do jogo)
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- Define a velocidade de movimento dos paddles (raquetes)
PADDLE_SPEED = 250

-- Multiplicador de aumento de velocidade da bola
SPEED_MULTIPLIER = 1.05 -- Aumenta 5% a cada colisão com as raquetes
TIME_SPEED_MULTIPLIER = 0.005 -- Aumenta 0,5% conforme o tempo passa

-- Define uma velocidade constante inicial para a bola
BALL_SPEED_X = 150 -- Velocidade horizontal da bola
BALL_SPEED_Y = 75  -- Velocidade vertical da bola

-- Altura dos paddles
PADDLE_HEIGHT = 20

-- Variável que guarda o jogador que tomou o último ponto (1 ou 2)
lastScoredPlayer = 1

-- Variável para controlar o tema (tema claro ou escuro)
changeTheme = false -- O jogo começa com o tema claro

-- Timer para reiniciar automaticamente após um ponto ser marcado
resetTimer = 0 -- Temporizador para o reinício

-- Contagem regressiva do temporizador
countdown = 3 -- Contagem regressiva de 3 segundos para reiniciar após um ponto

-- Pontuação máxima para vencer o jogo
MAX_SCORE = 7

-- Inicializa as vitórias de cada jogador
player1Wins = 0
player2Wins = 0

-- Variável para controlar se o jogo terminou
gameOver = false -- Determina se a partida acabou

-- Variável para controlar a visibilidade do texto piscante
blinkTimer = 0 -- Controla o tempo de piscar do texto
textVisible = true -- O texto começa visível

-- Variável para controlar se o jogo está na tela de confirmação de saída
confirmExit = false -- Tela de confirmação de saída

-- Variável para o vídeo de introdução
local introVideo

-- Sons do jogo
local backgroundSound -- Som de fundo
local paddleHitSound -- Som de colisão com o paddle
local pointSound -- Som de ponto
local wallHitSound -- Som de colisão com a parede
local victorySound -- Som de vitória
local startSound -- Som de início de partida
local pauseSound -- Som de pausa
local unpauseSound -- Som de unpause

-- Controle do som de fundo (mute/unmute)
local isMuted = false -- Define se o som está mudo
local muteText = "Mute(M)" -- Texto exibido para indicar o estado do som
local muteCooldown = false -- Impede múltiplas execuções rápidas da tecla "M"

-- Variável para a sigla G R R V no canto inferior esquerdo
local showGRRV = true

function love.load()
    -- Carrega o vídeo de introdução
    introVideo = love.graphics.newVideo("assets/videos/IntroGame.ogv")
    introVideo:play() -- Inicia o vídeo automaticamente

    -- Carrega os sons
    backgroundSound = love.audio.newSource("assets/sounds/NCSMusic.mp3", "stream") -- Carrega o som de fundo
    backgroundSound:setLooping(true) -- Define som de fundo para tocar continuamente
    backgroundSound:setVolume(0.2) -- Define o volume mais baixo para o som de fundo

    -- Carrega os efeitos sonoros para as colisões e eventos
    paddleHitSound = love.audio.newSource("assets/sounds/Paddle.mp3", "static") -- Carrega o som de colisão com o paddle
    wallHitSound = love.audio.newSource("assets/sounds/WallHit.mp3", "static") -- Carrega o som de colisão com a parede
    victorySound = love.audio.newSource("assets/sounds/Victory.mp3", "static") -- Carrega o som de vitória
    startSound = love.audio.newSource("assets/sounds/Start.mp3", "static") -- Carrega o som de início de partida
    pauseSound = love.audio.newSource("assets/sounds/Pause.mp3", "static") -- Carrega o som de pausa
    unpauseSound = love.audio.newSource("assets/sounds/Unpause.mp3", "static") -- Carrega o som de unpause
    pointSound = love.audio.newSource("assets/sounds/Point.mp3", "static") -- Carrega o som de ponto
    pointSound:setVolume(0.5) -- Ajusta o volume do som de pontuação

    -- Configuração gráfica para visual mais nítido
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Define a semente para variações aleatórias no jogo
    math.randomseed(os.time())

    -- Carrega as fontes usadas no jogo
    smallFont = love.graphics.newFont('assets/fonts/font.ttf', 8) -- Fonte pequena
    scoreFont = love.graphics.newFont('assets/fonts/font.ttf', 16) -- Fonte maior para placares

    -- Define a fonte padrão como a pequena
    love.graphics.setFont(smallFont)

    -- Configura a tela com a biblioteca push (resolução virtual)
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    -- Centraliza os paddles verticalmente no início do jogo
    player1Y = (VIRTUAL_HEIGHT / 2) - (PADDLE_HEIGHT / 2)
    player2Y = (VIRTUAL_HEIGHT / 2) - (PADDLE_HEIGHT / 2)

    -- Posição inicial da bola no centro da tela
    ballX = VIRTUAL_WIDTH / 2 - 2
    ballY = VIRTUAL_HEIGHT / 2 - 2

    -- Define a direção inicial da bola (aleatória)
    ballDX = math.random(2) == 1 and BALL_SPEED_X or -BALL_SPEED_X
    ballDY = math.random(-BALL_SPEED_Y, BALL_SPEED_Y)

    -- Inicializa os placares
    player1Score = 0
    player2Score = 0

    -- Define o estado inicial do jogo como 'start'
    gameState = 'start'
end

function love.update(dt)
    -- Aguarda até que o vídeo de introdução termine antes de iniciar o jogo
    if introVideo and introVideo:isPlaying() then
        return -- Não faz mais nada enquanto o vídeo estiver tocando
    end

    -- Verifica se o vídeo terminou e inicia o som de fundo
    if introVideo and not introVideo:isPlaying() then
        introVideo = nil -- Remove o vídeo da memória
        gameState = 'start'
        backgroundSound:play() -- Inicia o som de fundo após o vídeo
    end

    -- Alterna entre mute e unmute com a tecla 'M', com cooldown
    if love.keyboard.isDown('m') and not muteCooldown then
        muteCooldown = true -- Previne múltiplos toques rápidos na tecla
        if not isMuted then  -- Se o som não estiver mudo
            backgroundSound:pause()
            muteText = "Unmute(M)"
            isMuted = true
        else -- Se o som estiver mudo
            backgroundSound:play()
            muteText = "Mute(M)"
            isMuted = false
        end
    elseif not love.keyboard.isDown('m') then
        muteCooldown = false -- Libera o uso da tecla "M" novamente
    end

    -- Alterna a visibilidade do texto piscante (por exemplo, "Pressione Enter")
    blinkTimer = blinkTimer + dt
    if blinkTimer >= 0.5 then -- A cada 0,5 segundos
        textVisible = not textVisible -- Alterna visibilidade
        blinkTimer = 0 -- Reseta o temporizador
    end

    -- Interrompe a execução se o jogador estiver na tela de confirmação de saída
    if confirmExit then
        return
    end

    -- Se o jogo terminou (estado "gameOver"), pausa as atualizações até um novo jogo começar
    if gameOver then
        return
    end

    -- Verifica se o jogo está no estado de contagem regressiva antes de começar
    if gameState == 'countdown' then
        resetTimer = resetTimer + dt -- Incrementa o temporizador
        countdown = 3 - math.floor(resetTimer) -- Atualiza a contagem regressiva

        if resetTimer >= 3 then -- Após 3 segundos, inicia o jogo
            love.audio.play(startSound:clone()) -- Som de início de partida
            resetBall() -- Reseta a bola
            gameState = 'play' -- Muda para o estado "play"
            resetTimer = 0 -- Reseta o temporizador para a próxima vez
            countdown = 3 -- Reseta a contagem regressiva
        end
        return -- Interrompe a execução enquanto o temporizador está ativo
    end

    -- Pausa o jogo se o estado for "paused"
    if gameState == 'paused' then
        return
    end

    -- Movimentação dos paddles (raquetes) se o jogo estiver no estado "play"
    if gameState == 'play' then
        -- Movimentação do jogador 1
        if love.keyboard.isDown('w') then
            player1Y = math.max(0, player1Y + -PADDLE_SPEED * dt) -- Para cima
        elseif love.keyboard.isDown('s') then
            player1Y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, player1Y + PADDLE_SPEED * dt) -- Para baixo
        end

        -- Movimentação do jogador 2
        if love.keyboard.isDown('up') then
            player2Y = math.max(0, player2Y + -PADDLE_SPEED * dt) -- Para cima
        elseif love.keyboard.isDown('down') then
            player2Y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, player2Y + PADDLE_SPEED * dt) -- Para baixo
        end

        -- Atualiza a posição da bola
        ballX = ballX + ballDX * dt -- Atualiza horizontalmente
        ballY = ballY + ballDY * dt -- Atualiza verticalmente

        -- Aumenta a velocidade da bola com o tempo
        ballDX = ballDX + (ballDX * TIME_SPEED_MULTIPLIER * dt)
        ballDY = ballDY + (ballDY * TIME_SPEED_MULTIPLIER * dt)

        -- Colisões da bola com o paddle do jogador 1
        if ballX <= 15 and ballY + 4 >= player1Y and ballY <= player1Y + PADDLE_HEIGHT then
            love.audio.play(paddleHitSound:clone()) -- Som de colisão com o paddle
            local relativeIntersectY = (player1Y + (PADDLE_HEIGHT / 2)) - (ballY + 2)
            local normalizedRelativeIntersectionY = relativeIntersectY / (PADDLE_HEIGHT / 2)
            local bounceAngle = normalizedRelativeIntersectionY * math.pi / 4 -- Máximo de 45 graus

            ballDX = math.abs(ballDX) * SPEED_MULTIPLIER -- Garante que a bola vá para a direita
            ballDY = math.tan(bounceAngle) * math.abs(ballDX) -- Ajusta a direção vertical
            ballX = 15 -- Ajusta a posição da bola após a colisão
        end

        -- Colisões da bola com o paddle do jogador 2
        if ballX >= VIRTUAL_WIDTH - 15 and ballY + 4 >= player2Y and ballY <= player2Y + PADDLE_HEIGHT then
            love.audio.play(paddleHitSound:clone()) -- Som de colisão com o paddle
            local relativeIntersectY = (player2Y + (PADDLE_HEIGHT / 2)) - (ballY + 2)
            local normalizedRelativeIntersectionY = relativeIntersectY / (PADDLE_HEIGHT / 2)
            local bounceAngle = normalizedRelativeIntersectionY * math.pi / 4 -- Máximo de 45 graus

            ballDX = -math.abs(ballDX) * SPEED_MULTIPLIER -- Garante que a bola vá para a esquerda
            ballDY = math.tan(bounceAngle) * math.abs(ballDX) -- Ajusta a direção vertical
            ballX = VIRTUAL_WIDTH - 15 -- Ajusta a posição da bola após a colisão
        end

        -- Colisão da bola com a borda superior e inferior
        if ballY <= 0 then
            ballY = 0 -- Mantém a bola dentro dos limites
            ballDY = -ballDY -- Inverte a direção vertical
            love.audio.play(wallHitSound:clone()) -- Toca o som de colisão com a parede
        end

        if ballY >= VIRTUAL_HEIGHT - 4 then
            ballY = VIRTUAL_HEIGHT - 4 -- Mantém a bola dentro dos limites
            ballDY = -ballDY -- Inverte a direção vertical
            love.audio.play(wallHitSound:clone()) -- Toca o som de colisão com a parede
        end

        -- Colisão da bola com a borda esquerda (ponto para o jogador 2)
        if ballX < 0 then
            player2Score = player2Score + 1 -- Incrementa o placar do jogador 2
            lastScoredPlayer = 2 -- Registra o último jogador a pontuar
            love.audio.play(pointSound:clone()) -- Toca o som de ponto
            if player2Score >= MAX_SCORE then
                gameOver = true
                winner = 2 -- Jogador 2 venceu
                player2Wins = player2Wins + 1 -- Incrementa as vitórias do jogador 2
                love.audio.play(victorySound) -- Toca o som de vitória
            else
                resetBall() -- Reinicia a bola automaticamente
            end
        end

        -- Colisão da bola com a borda direita (ponto para o jogador 1)
        if ballX > VIRTUAL_WIDTH then
            player1Score = player1Score + 1 -- Incrementa o placar do jogador 1
            lastScoredPlayer = 1 -- Registra o último jogador a pontuar
            love.audio.play(pointSound:clone()) -- Toca o som de ponto
            if player1Score >= MAX_SCORE then
                gameOver = true
                winner = 1 -- Jogador 1 venceu
                player1Wins = player1Wins + 1 -- Incrementa as vitórias do jogador 1
                love.audio.play(victorySound) -- Toca o som de vitória
            else
                resetBall() -- Reinicia a bola automaticamente
            end
        end
    end
end

-- Função para resetar a posição da bola e centralizar os paddles
function resetBall()
    ballX = VIRTUAL_WIDTH / 2 - 2
    ballY = VIRTUAL_HEIGHT / 2 - 2
    if gameOver then
        ballDX = winner == 1 and BALL_SPEED_X or -BALL_SPEED_X
    else
        ballDX = (lastScoredPlayer == 1) and BALL_SPEED_X or -BALL_SPEED_X
    end
    ballDY = math.random(-BALL_SPEED_Y, BALL_SPEED_Y)

    -- Centraliza os paddles após cada reinício
    player1Y = (VIRTUAL_HEIGHT / 2) - (PADDLE_HEIGHT / 2)
    player2Y = (VIRTUAL_HEIGHT / 2) - (PADDLE_HEIGHT / 2)
end

-- Função para capturar teclas pressionadas
function love.keypressed(key)
    if confirmExit then
        if key == 'return' then
            love.event.quit() -- Fecha o jogo
        elseif key == 'space' then
            confirmExit = false -- Cancela a saída
        elseif key == 'l' then
            changeTheme = not changeTheme -- Troca entre temas
        end
        return
    end

    if key == 'escape' then
        confirmExit = true -- Entra na tela de confirmação de saída
    elseif key == 'enter' or key == 'return' then
        if gameOver then
            -- Reinicia o jogo após o game over
            player1Score = 0
            player2Score = 0
            gameOver = false
            resetBall()
            gameState = 'countdown'
        elseif gameState == 'start' then
            gameState = 'countdown'
        elseif gameState == 'play' then
            gameState = 'paused'
            love.audio.play(pauseSound:clone()) -- Som de pausa
        elseif gameState == 'paused' then
            gameState = 'play'
            love.audio.play(unpauseSound:clone()) -- Som de unpause
        end
    elseif key == 'space' or key == 'p' then
        -- Impede o som de pause/unpause no estado de gameOver
        if not gameOver then
            if gameState == 'play' then
                gameState = 'paused'
                love.audio.play(pauseSound:clone())
            elseif gameState == 'paused' then
                gameState = 'play'
                love.audio.play(unpauseSound:clone())
            end
        end
    elseif key == 'l' then
        changeTheme = not changeTheme
    end
end

-- Função para desenhar a tela do jogo
function love.draw()
    push:apply('start') -- Inicia a tela virtual

    -- Se o vídeo de introdução ainda estiver sendo reproduzido
    if introVideo then
        love.graphics.draw(introVideo, 0, 0, 0, VIRTUAL_WIDTH / introVideo:getWidth(), VIRTUAL_HEIGHT / introVideo:getHeight())
    else
        -- Define a cor de fundo de acordo com o tema
        if changeTheme then
            love.graphics.clear(0, 0, 0, 1) -- Preto para o tema escuro
        else
            love.graphics.clear(0/255, 120/255, 255/255, 1) -- Azul claro para o tema claro
        end
        
        love.graphics.setFont(smallFont)

        if confirmExit then
            -- Tela de confirmação de saída
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf('Você quer realmente sair do jogo?', 0, 50, VIRTUAL_WIDTH, 'center')
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf('Aperte a\n\nBarra de Espaço\n\npara voltar ao jogo', -75, 150, 400, 'center')
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf('Aperte Enter\n\npara sair', 125, 150, 400, 'center')

        elseif gameState == 'start' then
            -- Tela de início
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf('O jogador que conseguir\n\n7 pontos primeiro será o vencedor', 0, 50, VIRTUAL_WIDTH, 'center')

            if textVisible then
                love.graphics.printf('Pressione Enter para começar a partida', 0, 180, VIRTUAL_WIDTH, 'center')
            end

            love.graphics.printf(changeTheme and 'Light Theme\nPress (L)' or 'Night Theme\nPress (L)', 3.5, 3, 400, 'left')
            love.graphics.printf('Para sair\nPress ESC', VIRTUAL_WIDTH - 100, 3, 97, 'right')

            love.graphics.printf(muteText, VIRTUAL_WIDTH - 100, VIRTUAL_HEIGHT - 10, 99, 'right')

            if showGRRV then
                love.graphics.printf('GRRV', 3.5, VIRTUAL_HEIGHT - 10, 100, 'left')
            end

            -- Desenha os paddles
            love.graphics.rectangle('fill', 10, player1Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', VIRTUAL_WIDTH - 15, player2Y, 5, PADDLE_HEIGHT)

        elseif gameState == 'countdown' then
            -- Tela de contagem regressiva
            love.graphics.printf('A partida começará em ' .. countdown, 0, 50, VIRTUAL_WIDTH, 'center')
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf('Player 1\n\n(W/S)', -130, 140, 400, 'center') -- Instrução para o jogador 1
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf('Player 2\n\n(Up/Down)', 165, 140, 400, 'center') -- Instrução para o jogador 2
            love.graphics.rectangle('fill', 10, player1Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', VIRTUAL_WIDTH - 15, player2Y, 5, PADDLE_HEIGHT)

        elseif gameOver then
            -- Tela de fim de jogo
            love.graphics.printf('Fim de Jogo\n\nO jogador ' .. winner .. ' venceu o jogo!', 0, 50, VIRTUAL_WIDTH, 'center')

            if textVisible then
                love.graphics.printf('Pressione Enter para começar uma nova partida', 0, 180, VIRTUAL_WIDTH, 'center')
            end

            love.graphics.printf(changeTheme and 'Light Theme\nPress (L)' or 'Night Theme\nPress (L)', 3.5, 3, 400, 'left')
            love.graphics.printf('Para sair\nPress ESC', VIRTUAL_WIDTH - 100, 3, 97, 'right')

            love.graphics.printf(muteText, VIRTUAL_WIDTH - 100, VIRTUAL_HEIGHT - 10, 99, 'right')

            if showGRRV then
                love.graphics.printf('GRRV', 3.5, VIRTUAL_HEIGHT - 10, 100, 'left')
            end

        elseif gameState == 'paused' then
            -- Tela de pausa
            love.graphics.printf('P A U S E', 0, VIRTUAL_HEIGHT / 2 - 6, VIRTUAL_WIDTH, 'center')

            love.graphics.rectangle('fill', 10, player1Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', VIRTUAL_WIDTH - 15, player2Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', ballX, ballY, 4, 4)

        else
            -- Desenha a linha central e os placares durante o jogo
            love.graphics.setColor(1, 1, 1)
            love.graphics.line(VIRTUAL_WIDTH / 2, 0, VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT)

            love.graphics.setFont(scoreFont)
            love.graphics.printf(tostring(player1Score), VIRTUAL_WIDTH / 4 - 50, 20, 100, 'center')
            love.graphics.printf(tostring(player2Score), VIRTUAL_WIDTH * 3/4 - 50, 20, 100, 'center')

            love.graphics.setFont(smallFont)
            love.graphics.printf("Vitórias: " .. tostring(player1Wins), VIRTUAL_WIDTH / 4 - 50, 5, 100, 'center')
            love.graphics.printf("Vitórias: " .. tostring(player2Wins), VIRTUAL_WIDTH * 3/4 - 50, 5, 100, 'center')

            -- Desenha os paddles e a bola
            love.graphics.rectangle('fill', 10, player1Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', VIRTUAL_WIDTH - 15, player2Y, 5, PADDLE_HEIGHT)
            love.graphics.rectangle('fill', ballX, ballY, 4, 4)
        end
    end

    push:apply('end') -- Finaliza o uso da tela virtual
end
