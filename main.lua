push = require 'push'

-- obtém as dimensões da tela
WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

-- define a largura e altura da tela virtual
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- define a velocidade do paddle
PADDLE_SPEED = 200

-- define uma velocidade constante para a bola
BALL_SPEED_X = 150 -- velocidade horizontal da bola
BALL_SPEED_Y = 75  -- velocidade vertical da bola

function love.load()
    -- define o filtro gráfico para imagens
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- inicializa a semente do gerador de números aleatórios
    math.randomseed(os.time())

    -- carrega fontes para o texto
    smallFont = love.graphics.newFont('font.ttf', 8)
    scoreFont = love.graphics.newFont('font.ttf', 8) 

    -- define a fonte padrão
    love.graphics.setFont(smallFont)

    -- configura a tela
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = true,
        resizable = false,
        vsync = true
    })

    -- define a posição inicial dos jogadores
    player1Y = 30
    player2Y = VIRTUAL_HEIGHT - 50

    -- define a posição inicial da bola
    ballX = VIRTUAL_WIDTH / 2 - 2
    ballY = VIRTUAL_HEIGHT / 2 - 2

    -- define a direção da bola aleatoriamente
    ballDX = math.random(2) == 1 and BALL_SPEED_X or -BALL_SPEED_X
    ballDY = math.random(-BALL_SPEED_Y, BALL_SPEED_Y)

    -- inicializa os placares dos jogadores
    player1Score = 0
    player2Score = 0

    -- define o estado inicial do jogo
    gameState = 'start'
end

function love.update(dt)
    -- movimento do jogador 1
    if love.keyboard.isDown('w') then
        player1Y = math.max(0, player1Y + -PADDLE_SPEED * dt) -- move para cima
    elseif love.keyboard.isDown('s') then
        player1Y = math.min(VIRTUAL_HEIGHT - 20, player1Y + PADDLE_SPEED * dt) -- move para baixo
    end

    -- movimento do jogador 2
    if love.keyboard.isDown('up') then
        player2Y = math.max(0, player2Y + -PADDLE_SPEED * dt) -- move para cima
    elseif love.keyboard.isDown('down') then
        player2Y = math.min(VIRTUAL_HEIGHT - 20, player2Y + PADDLE_SPEED * dt) -- move para baixo
    end

    -- movimento da bola
    if gameState == 'play' then
        ballX = ballX + ballDX * dt -- atualiza a posição x da bola
        ballY = ballY + ballDY * dt -- atualiza a posição y da bola

        -- colisão da bola com os paddles
        if ballX <= 15 and ballY + 4 >= player1Y and ballY <= player1Y + 20 then
            ballDX = -ballDX * 1.03 -- inverte a direção da bola
            ballX = 15 -- ajusta a posição da bola
        end

        if ballX >= VIRTUAL_WIDTH - 15 and ballY + 4 >= player2Y and ballY <= player2Y + 20 then
            ballDX = -ballDX * 1.03 -- inverte a direção da bola
            ballX = VIRTUAL_WIDTH - 15 -- ajusta a posição da bola
        end

        -- colisão da bola com as bordas da tela
        if ballY <= 0 then
            ballY = 0 -- ajusta a posição da bola
            ballDY = -ballDY -- inverte a direção da bola
        end

        if ballY >= VIRTUAL_HEIGHT - 4 then
            ballY = VIRTUAL_HEIGHT - 4 -- ajusta a posição da bola
            ballDY = -ballDY -- inverte a direção da bola
        end

        -- marcação de pontos
        if ballX < 0 then
            player2Score = player2Score + 1 -- aumenta o placar do jogador 2
            gameState = 'start' -- reinicia o jogo
            resetBall() -- reseta a bola
        end

        if ballX > VIRTUAL_WIDTH then
            player1Score = player1Score + 1 -- aumenta o placar do jogador 1
            gameState = 'start' -- reinicia o jogo
            resetBall() -- reseta a bola
        end
    end
end

-- reseta a bola para o centro da tela com uma nova direção aleatória
function resetBall()
    ballX = VIRTUAL_WIDTH / 2 - 2 -- reseta a posição x da bola
    ballY = VIRTUAL_HEIGHT / 2 - 2 -- reseta a posição y da bola
    ballDX = (math.random(2) == 1 and BALL_SPEED_X or -BALL_SPEED_X) -- mantém a velocidade constante
    ballDY = math.random(-BALL_SPEED_Y, BALL_SPEED_Y) -- pode ser ajustado conforme necessário
end

function love.keypressed(key)
    -- ação quando uma tecla é pressionada
    if key == 'escape' then
        love.event.quit() -- fecha o jogo
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play' -- inicia o jogo
        else
            gameState = 'start' -- reinicia o jogo
            resetBall() -- reseta a bola
        end
    end
end

function love.draw()
    push:apply('start') -- aplica as configurações da tela

    love.graphics.clear(40/255, 25/255, 52/255, 255/255) -- limpa a tela com uma cor

    love.graphics.setFont(smallFont) -- define a fonte pequena

    if gameState == 'start' then
        love.graphics.printf('pressione enter para começar', 0, 20, VIRTUAL_WIDTH, 'center') -- exibe a mensagem inicial
    else
        -- desenha a linha vertical no centro apenas durante o estado de jogo
        love.graphics.setColor(1, 1, 1) -- define a cor da linha como branca
        love.graphics.line(VIRTUAL_WIDTH / 2, 0, VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT) -- linha vertical

        -- desenha os placares apenas durante o estado de jogo
        love.graphics.setFont(scoreFont) -- define a fonte do placar
        love.graphics.printf(tostring(player1Score), VIRTUAL_WIDTH / 4 - 50, 20, 100, 'center') -- placar do jogador 1
        love.graphics.printf(tostring(player2Score), VIRTUAL_WIDTH * 3/4 - 50, 20, 100, 'center') -- placar do jogador 2
    end

    -- desenha os paddles
    love.graphics.rectangle('fill', 10, player1Y, 5, 20) -- paddle do jogador 1
    love.graphics.rectangle('fill', VIRTUAL_WIDTH - 15, player2Y, 5, 20) -- paddle do jogador 2

    -- desenha a bola
    love.graphics.rectangle('fill', ballX, ballY, 4, 4) -- bola

    push:apply('end') -- aplica as configurações de volta
end
