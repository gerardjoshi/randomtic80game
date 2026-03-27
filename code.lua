-- title:  Defend the Dept (Ultimate Merge)
-- author: You, Rithik, & Pasanth
-- desc:   PvZ lane shooter (Balanced + UI + Sprites)
-- script: lua

-- GLOBAL VARIABLES
leaderboard = {}
session_id = 1
state = "TITLE"
t = 0

shake = 0
game_over_timer = 0
difficulty = 1
spawn_timer = 60

function initGame()
    score = 0
    lives = 3
    difficulty = 1
    spawn_timer = 60
    player = {x=10, y=68, char=1, speed=2, cooldown=0}
    bullets = {}
    enemies = {}
    ebullets = {}
    msg_timer = 120
    game_over_timer = 0
    intro_hint_timer = 180
end

initGame()

--------------------------------------------------
-- TEXT / UI HELPERS (Pasanth)
--------------------------------------------------
function textWidth(txt, scale)
    scale = scale or 1
    return #txt * 6 * scale
end

function printCenter(txt, y, col, scale, fixed)
    scale = scale or 1
    local x = math.floor((240 - textWidth(txt, scale)) / 2)
    print(txt, x, y, col, fixed or false, scale)
end

function printCenterInRect(txt, rx, ry, rw, col, scale, fixed)
    scale = scale or 1
    local tw = textWidth(txt, scale)
    local x = rx + math.floor((rw - tw) / 2)
    print(txt, x, ry, col, fixed or false, scale)
end

function drawArrowIcon(x, y, dir, col)
    rect(x, y, 12, 12, 0)
    rectb(x, y, 12, 12, 12)

    if dir == "UP" then
        tri(x+6, y+2, x+2, y+7, x+10, y+7, col)
        rect(x+5, y+7, 2, 3, col)
    elseif dir == "DOWN" then
        tri(x+2, y+4, x+10, y+4, x+6, y+9, col)
        rect(x+5, y+2, 2, 3, col)
    elseif dir == "LEFT" then
        tri(x+2, y+6, x+7, y+2, x+7, y+10, col)
        rect(x+7, y+5, 3, 2, col)
    elseif dir == "RIGHT" then
        tri(x+10, y+6, x+5, y+2, x+5, y+10, col)
        rect(x+2, y+5, 3, 2, col)
    end
end

function drawKeyBox(x, y, label)
    rect(x, y, 18, 12, 6)
    rectb(x, y, 18, 12, 15)
    printCenterInRect(label, x, y+3, 18, 15, 1, true)
end

function drawTitleControls()
    local bx, by, bw, bh = 24, 88, 192, 38
    rect(bx, by, bw, bh, 0)
    rectb(bx, by, bw, bh, 12)

    printCenterInRect("CONTROLS", bx, by+4, bw, 12, 1, true)

    drawArrowIcon(36, 102, "UP", 12)
    drawArrowIcon(50, 102, "DOWN", 12)
    print("MOVE", 68, 105, 15)

    drawArrowIcon(100, 102, "LEFT", 12)
    drawArrowIcon(114, 102, "RIGHT", 12)
    print("SELECT", 132, 105, 15)

    drawKeyBox(176, 102, "Z")
    printCenterInRect("START / SHOOT", bx, by+28, bw, 14, 1, true)
end

function drawInGameHint()
    if intro_hint_timer > 0 then
        local bx, by, bw, bh = 42, 102, 156, 18
        rect(bx, by, bw, bh, 0)
        rectb(bx, by, bw, bh, 12)

        drawArrowIcon(48, 105, "UP", 12)
        drawArrowIcon(62, 105, "DOWN", 12)
        print("MOVE", 80, 108, 15)

        drawKeyBox(126, 105, "Z")
        print("SHOOT", 150, 108, 15)
    end
end

--------------------------------------------------
-- SOUND (Rithik)
--------------------------------------------------
function sfxShoot() sfx(1,"E-4",5,0,5) end
function sfxHit() sfx(2,"C-3",10,0,5) end
function sfxDeath() sfx(3,"C-2",30,0,15) end

--------------------------------------------------
-- GAMEPLAY FUNCTIONS
--------------------------------------------------
function spawnEnemy()
    local ey = 20 + (math.random(0,3) * 20)
    local typ = math.random(1,4)
    local e = {
        x=240, 
        y=ey, 
        hp=2, 
        speed=(math.random(3,8)/10) + difficulty*0.15, 
        shoot_timer=0
    }

    if typ == 4 then
        e.is_shooter = true
        e.spr = 5
    else
        e.is_shooter = false
        e.spr = 4
    end
    table.insert(enemies, e)
end

function collide(a, b, size)
    return a.x < b.x+size and a.x+size > b.x and a.y < b.y+size and a.y+size > b.y
end

function updateGame()
    if intro_hint_timer > 0 then
        intro_hint_timer = intro_hint_timer - 1
    end

    difficulty = 1 + (t / 3000)

    -- Player Movement
    if btn(0) and player.y > 10 then player.y = player.y - player.speed end
    if btn(1) and player.y < 120 then player.y = player.y + player.speed end

    -- Player Shooting
    if player.cooldown > 0 then player.cooldown = player.cooldown - 1 end
    if btn(4) and player.cooldown <= 0 then
        if #bullets < 5 then
            table.insert(bullets, {x=player.x+8, y=player.y+2, speed=4, spr=32+player.char})
            sfxShoot()
        end
        player.cooldown = math.max(10, 18 - difficulty)
    end

    -- Update Bullets
    for i=#bullets,1,-1 do
        local b = bullets[i]
        b.x = b.x + b.speed
        if b.x > 240 then table.remove(bullets, i) end
    end

    -- Update Enemy Bullets
    for i=#ebullets,1,-1 do
        local b = ebullets[i]
        b.x = b.x - 2
        if collide(b, player, 8) then
            lives = lives - 1
            shake = 10
            sfxHit()
            table.remove(ebullets, i)
        elseif b.x < 0 then
            table.remove(ebullets, i)
        end
    end

    -- Enemy Spawn Timer
    spawn_timer = spawn_timer - 1
    if spawn_timer <= 0 then
        spawnEnemy()
        spawn_timer = math.max(35, math.floor(70 - difficulty*5 + math.random(-5,5)))
    end

    -- Update Enemies & Collisions
    for i=#enemies,1,-1 do
        local e = enemies[i]
        e.x = e.x - e.speed

        if e.is_shooter then
            e.shoot_timer = e.shoot_timer + 1
            if e.shoot_timer > 100 then
                table.insert(ebullets, {x=e.x, y=e.y+2, spr=36})
                e.shoot_timer = 0
            end
        end

        if e.x <= player.x then
            lives = lives - 1
            shake = 10
            sfxHit()
            table.remove(enemies, i)
        else
            for j=#bullets,1,-1 do
                if collide(bullets[j], e, 8) then
                    e.hp = e.hp - 1
                    table.remove(bullets, j)
                    if e.hp <= 0 then
                        score = score + 10
                        shake = 6
                        table.remove(enemies, i)
                        break
                    end
                end
            end
        end
    end

    -- Check Death
    if lives <= 0 and state ~= "DYING" then
        state = "DYING"
        game_over_timer = 120
        sfxDeath()
    end
end

--------------------------------------------------
-- DRAWING FUNCTIONS & LEADERBOARD
--------------------------------------------------
function drawUI()
    print("SCORE: "..score, 5, 5, 12)
    print("LVL: "..math.floor(difficulty), 150, 5, 11)
    for i=1, lives do
        spr(6, 200 + (i*10), 4, 0)
    end
end

function addScore()
    table.insert(leaderboard, {name="P"..session_id, s=score})
    table.sort(leaderboard, function(a,b) return a.s > b.s end)
    session_id = session_id + 1
end

--------------------------------------------------
-- STATE MANAGERS
--------------------------------------------------
function doTitle()
    printCenter("DEFEND THE DEPT", 38, 11, 2, true)
    printCenter("Lane Shooter", 64, 12, 1, true)
    printCenter("PRESS Z TO START", 78, 15, 1, true)

    drawTitleControls()

    if btnp(4) then state = "SELECT" end
end

function doSelect()
    printCenter("CHOOSE CHARACTER", 20, 12, 1, true)

    spr(1, 60, 60, 0, 2)
    spr(2, 110, 60, 0, 2)
    spr(3, 160, 60, 0, 2)

    if btnp(2) and player.char > 1 then player.char = player.char - 1 end
    if btnp(3) and player.char < 3 then player.char = player.char + 1 end

    print("^", 64 + ((player.char-1)*50), 85, 9)
    printCenter("LEFT / RIGHT TO CHOOSE", 102, 15, 1, true)
    printCenter("PRESS Z TO SELECT", 114, 15, 1, true)

    if btnp(4) then 
        msg_timer = 120
        state = "MSG" 
    end
end

function doMsg()
    printCenter("DEFEND THE DEPT! GO!", 56, 9, 2, true)
    msg_timer = msg_timer - 1
    if msg_timer <= 0 then state = "GAME" end
end

function doGame()
    updateGame()

    local sx = shake>0 and math.random(-2,2) or 0
    local sy = shake>0 and math.random(-2,2) or 0
    if shake>0 then shake=shake-1 end

    spr(player.char, player.x+sx, player.y+sy, 0)
    spr(16+player.char, player.x+8+sx, player.y+sy, 0)

    for _,b in pairs(bullets) do spr(b.spr, b.x, b.y, 0) end
    for _,b in pairs(ebullets) do spr(b.spr, b.x, b.y, 0) end
    for _,e in pairs(enemies) do spr(e.spr, e.x+sx, e.y+sy, 0) end

    drawUI()
    drawInGameHint()

    if btnp(7) then state = "PAUSE" end
end

function doPause()
    rect(60, 20, 120, 90, 0)
    rectb(60, 20, 120, 90, 12)
    printCenterInRect("PAUSED", 60, 30, 120, 12, 1, true)
    print("Score: "..score, 70, 50, 15)
    print("Lives: "..lives, 70, 60, 15)
    print("Press Z: Resume", 70, 75, 15)
    print("Press X: Title", 70, 85, 15)

    if btnp(4) then state = "GAME" end
    if btnp(5) then initGame() state = "TITLE" end
end

function doDying()
    cls(2)
    game_over_timer = game_over_timer - 1

    if game_over_timer <= 0 then
        addScore()
        state = "GAMEOVER"
    end
end

function doGameOver()
    printCenter("GAME OVER", 20, 6, 2, true)
    printCenter("Final Score: "..score, 44, 15, 1, true)
    printCenter("--- LEADERBOARD ---", 60, 12, 1, true)

    local y = 75
    for i = 1, math.min(5, #leaderboard) do
        local e = leaderboard[i]
        printCenter(i..". "..e.name.."  "..e.s, y, 15, 1, true)
        y = y + 10
    end

    printCenter("PRESS Z TO RESTART", 120, 9, 1, true)

    if btnp(4) then
        initGame()
        state = "TITLE"
    end
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
function TIC()
    cls(13) -- Replace with map(0,0,30,17,0,0) if using an imported PNG background

    if state == "TITLE" then doTitle()
    elseif state == "SELECT" then doSelect()
    elseif state == "MSG" then doMsg()
    elseif state == "GAME" then doGame()
    elseif state == "PAUSE" then doPause()
    elseif state == "DYING" then doDying()
    elseif state == "GAMEOVER" then doGameOver()
    end

    t = t + 1
end
