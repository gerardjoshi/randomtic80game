-- title:   Defend the Dept (Balanced Final)
-- author:  You
-- desc:    PvZ style lane shooter (balanced + polished)
-- script:  lua

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
    msg_timer = 120 -- 2 seconds for "Defend the Dept! GO!"

    -- VISUAL STATES
    damage_flash = 0
    intro_hint_timer = 180
    msg_timer = 120
    game_over_timer = 0
end

initGame()

-- =====================
-- SOUND
-- =====================
function sfxShoot() sfx(1,"E-4",5,0,5) end
function sfxHit() sfx(2,"C-3",10,0,5) end
function sfxDeath() sfx(3,"C-2",30,0,15) end

-- =====================
-- SPAWN
-- =====================
function spawnEnemy()
    local ey = 20 + (math.random(0,3) * 20)
    local typ = math.random(1,4)
    local e = {x=240, y=ey, hp=2, speed=math.random(3,8)/10, shoot_timer=0}

    if typ == 4 then
    local type = math.random(1,4)

    local e = {
        x=240,
        y=ey,
        hp=2,
        speed=(math.random(3,8)/10) + difficulty*0.15,
        shoot_timer=0
    }

    if type == 4 then
        e.is_shooter = true
        e.spr = 5
    else
        e.is_shooter = false
        e.spr = 4
    end

    table.insert(enemies, e)
end

-- =====================
-- COLLISION
-- =====================
function collide(a, b, size)
    return a.x < b.x+size and a.x+size > b.x and a.y < b.y+size and a.y+size > b.y
end

function loseLife(n)
    n = n or 1
    lives = lives - n
    if lives < 0 then lives = 0 end
    damage_flash = 12
end

function textWidth(txt, scale)
    scale = scale or 1
    return #txt * 6 * scale
end

function printCenter(txt, y, col, scale, fixed)
    scale = scale or 1
    local x = math.floor((240 - textWidth(txt, scale)) / 2)
    print(txt, x, y, col, fixed or false, scale)
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

function drawHeart(x, y, active, pulse)
    local fill = active and 6 or 5
    local glow = active and 15 or 13

    if lives == 1 and active then
        fill = (math.sin(t * 0.30) > 0) and 6 or 14
    end

    circ(x+3, y+3, 3, fill)
    circ(x+8, y+3, 3, fill)
    tri(x, y+4, x+11, y+4, x+5, y+11, fill)

    if active then
        pix(x+5, y+5, glow)
    end

    if pulse and pulse > 0 and active then
        circb(x+5, y+6, 8 + pulse, glow)
    end
end

function drawLivesUI()
    local beatPulse = 0
    if lives == 1 then
        beatPulse = math.floor((math.sin(t * 0.30) + 1) * 1.5)
    end

    for i=1,3 do
        local active = i <= lives
        local hx = 182 + (i-1) * 18
        local hy = 2
        local pulse = (lives == 1 and i == 1) and beatPulse or 0
        drawHeart(hx, hy, active, pulse)
    end
end

function drawHeartbeatAlert()
    if lives == 1 then
        local c = (math.sin(t * 0.30) > 0) and 15 or 6

        local x = 120
        local y = 9
        line(x, y, x+8, y, c)
        line(x+8, y, x+11, y-4, c)
        line(x+11, y-4, x+14, y+4, c)
        line(x+14, y+4, x+18, y, c)
        line(x+18, y, x+28, y, c)

        if (t // 20) % 2 == 0 then
            print("LAST LIFE!", 112, 16, c)
        end
    end
end

function drawTitleControls()
    rect(28, 88, 184, 36, 0)
    rectb(28, 88, 184, 36, 12)

    print("CONTROLS", 95, 92, 12)

    drawArrowIcon(38, 104, "UP", 12)
    drawArrowIcon(52, 104, "DOWN", 12)
    print("MOVE", 69, 107, 15)

    drawArrowIcon(102, 104, "LEFT", 12)
    drawArrowIcon(116, 104, "RIGHT", 12)
    print("SELECT", 133, 107, 15)

    rect(170, 104, 18, 12, 6)
    rectb(170, 104, 18, 12, 15)
    print("Z", 176, 107, 15)
    print("START / SHOOT", 120, 120, 14)
end

function drawInGameHint()
    if intro_hint_timer > 0 then
        rect(46, 102, 148, 18, 0)
        rectb(46, 102, 148, 18, 12)

        drawArrowIcon(52, 105, "UP", 12)
        drawArrowIcon(66, 105, "DOWN", 12)
        print("MOVE", 84, 108, 15)

        rect(132, 105, 18, 12, 6)
        rectb(132, 105, 18, 12, 15)
        print("Z", 138, 108, 15)
        print("SHOOT", 156, 108, 15)
    end
end

function drawGameField()
    local bg = 13
    local field = 11
    local stripe = 12
    local edge = 14

    if damage_flash > 0 then
        bg = 6
    end

    if lives == 1 then
        local beat = (math.sin(t * 0.30) + 1) / 2
        bg = (beat > 0.55) and 2 or 1
        field = (beat > 0.55) and 3 or 2
        stripe = (beat > 0.55) and 12 or 6
        edge = 15
    end

    cls(bg)

    -- Gameplay field
    rect(0, 16, 240, 112, field)

    -- Lane bands
    for i=0,3 do
        local y = 18 + i * 28
        rect(0, y, 240, 24, (i % 2 == 0) and field or (field + 1))
        line(0, y-2, 239, y-2, stripe)
    end

    -- Centered background title
    printCenter("DEFEND THE DEPT", 54, 0, 2, true)
    printCenter("DEFEND THE DEPT", 52, 13, 2, true)

    -- Border pulse for final life
    if lives == 1 then
        local pad = math.floor(((math.sin(t * 0.30) + 1) / 2) * 3)
        rectb(1+pad, 17+pad, 238-pad*2, 110-pad*2, edge)
    else
        rectb(0, 16, 239, 111, edge)
    end
end

function updateGame()
    if damage_flash > 0 then damage_flash = damage_flash - 1 end
    if intro_hint_timer > 0 then intro_hint_timer = intro_hint_timer - 1 end

    -- Player Movement (Up/Down)
    if btn(0) and player.y > 10 then player.y = player.y - player.speed end
    if btn(1) and player.y < 120 then player.y = player.y + player.speed end

    -- Player Shooting (Z key / A button)
-- =====================
-- UPDATE GAME
-- =====================
function updateGame()

    -- smoother difficulty
    difficulty = 1 + (t / 3000)

    -- movement
    local dy = 0
    if btn(0) then dy = dy - 1 end
    if btn(1) then dy = dy + 1 end

    player.y = player.y + dy * player.speed
    if player.y < 10 then player.y = 10 end
    if player.y > 120 then player.y = 120 end

    -- shooting (controlled)
    if player.cooldown > 0 then player.cooldown = player.cooldown - 1 end

    if btn(4) and player.cooldown <= 0 then
        if #bullets < 5 then -- limit bullets
            table.insert(bullets, {
                x=player.x+8,
                y=player.y+2,
                speed=2,   -- slower
                col=11
            })
            sfxShoot()
        end
        player.cooldown = math.max(10, 18 - difficulty)
    end

    -- bullets
    for i=#bullets,1,-1 do
        local b = bullets[i]
        b.x = b.x + b.speed
        if b.x > 240 then table.remove(bullets, i) end
    end

    -- Update Enemy Bullets
    -- enemy bullets
    for i=#ebullets,1,-1 do
        local b = ebullets[i]
        b.x = b.x - 2

        if collide(b, player, 8) then
            loseLife(1)
            lives = lives - 1
            shake = 10
            sfxHit()
            table.remove(ebullets, i)
        elseif b.x < 0 then
            table.remove(ebullets, i)
        end
    end

    -- Update Enemies & Collisions
    if t % 60 == 0 then spawnEnemy() end -- Spawn every 1 sec

    -- balanced spawn system
    spawn_timer = spawn_timer - 1
    if spawn_timer <= 0 then
        spawnEnemy()
        spawn_timer = math.max(35, math.floor(70 - difficulty*5 + math.random(-5,5)))
    end

    -- enemies
    for i=#enemies,1,-1 do
        local e = enemies[i]
        e.x = e.x - e.speed

        -- Enemy shooting logic
        if e.is_shooter then
            e.shoot_timer = e.shoot_timer + 1
            if e.shoot_timer > 100 then
                table.insert(ebullets, {x=e.x, y=e.y+2})
                e.shoot_timer = 0
            end
        end

        if e.x <= player.x then
            loseLife(1)
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

    -- death
    if lives <= 0 and state ~= "DYING" then
        state = "DYING"
        game_over_timer = 120
        sfxDeath()
    end
end

-- =====================
-- UI
-- =====================
function drawUI()
    rect(0, 0, 240, 14, 0)
    print("SCORE: "..score, 5, 4, 12)
    drawLivesUI()
    drawHeartbeatAlert()
    print("SCORE: "..score, 5, 5, 12)
    print("LVL: "..math.floor(difficulty), 150, 5, 11)
    for i=1,lives do spr(6, 200+(i*10), 4, 0) end
end

-- =====================
-- LEADERBOARD
-- =====================
function addScore()
    table.insert(leaderboard, {name="P"..session_id, s=score})
    table.sort(leaderboard, function(a,b) return a.s > b.s end)
    session_id = session_id + 1
end

function drawLeaderboard()
    print("TOP SCORES", 90, 55, 12)
    for i=1,math.min(5,#leaderboard) do
        local e = leaderboard[i]
        print(i..". "..e.name.."  "..e.s, 80, 60+i*10, 15)
    end
end

-- =====================
-- STATES
-- =====================
function doTitle()
    cls(13)
    printCenter("DEFEND THE DEPT", 28, 0, 2, true)
    printCenter("DEFEND THE DEPT", 26, 11, 2, true)
    printCenter("Lane Shooter", 54, 12, 1, true)

    if (t // 30) % 2 == 0 then
        printCenter("PRESS Z TO START", 74, 15, 1, true)
    end

    drawTitleControls()

    if btnp(4) then state = "SELECT" end
end

function doSelect()
    cls(13)
    printCenter("CHOOSE CHARACTER", 20, 12, 1, true)

    -- Draw 3 options
    spr(1, 60, 60, 0, 2)
    spr(2, 110, 60, 0, 2)
    spr(3, 160, 60, 0, 2)

    -- Selection cursor
    if btnp(2) and player.char > 1 then player.char = player.char - 1 end
    if btnp(3) and player.char < 3 then player.char = player.char + 1 end

    print("^", 64 + ((player.char-1)*50), 85, 9)
    printCenter("LEFT / RIGHT TO CHOOSE", 100, 15, 1, true)
    printCenter("PRESS Z TO SELECT", 112, 15, 1, true)

    if btnp(4) then
        msg_timer = 120
        state = "MSG"
    end
end

function doMsg()
    cls(13)
    printCenter("DEFEND THE DEPT! GO!", 56, 9, 2, true)
    print("DEFEND THE DEPT", 70, 40, 11, true, 2)
    print("Press Z to Start", 80, 80, 15)

    if btnp(4) then state="SELECT" end
end

function doSelect()
    print("CHOOSE CHARACTER", 80, 20, 12)

    spr(1,60,60,0,2)
    spr(2,110,60,0,2)
    spr(3,160,60,0,2)

    if btnp(2) and player.char>1 then player.char=player.char-1 end
    if btnp(3) and player.char<3 then player.char=player.char+1 end

    print("^",64+((player.char-1)*50),85,9)

    if btnp(4) then state="MSG" end
end

function doMsg()
    print("DEFEND THE DEPT!", 60, 60, 9, true, 2)
    msg_timer = msg_timer - 1
    if msg_timer <= 0 then state="GAME" end
end

function doGame()
    updateGame()

    -- Draw Player & Gun
    spr(player.char, player.x, player.y, 0)
    spr(16+player.char, player.x+8, player.y, 0)

    -- Draw Entities
    for _,b in pairs(bullets) do spr(b.spr, b.x, b.y, 0) end
    for _,b in pairs(ebullets) do spr(b.spr, b.x, b.y, 0) end
    for _,e in pairs(enemies) do spr(e.spr, e.x, e.y, 0) end

    drawUI()
    drawInGameHint()

    if btnp(7) then state = "PAUSE" end -- Start button pauses
end

function doPause()
    rect(60, 20, 120, 90, 0)
    rectb(60, 20, 120, 90, 12)
    print("PAUSED", 100, 30, 12)
    print("Score: "..score, 70, 50, 15)
    print("Lives: "..lives, 70, 60, 15)
    print("Press Z: Resume", 70, 80, 15)
    print("Press X: Title", 70, 90, 15)

    if btnp(4) then
        state = "GAME"
    end
    if btnp(5) then
        initGame()
        state = "TITLE"
    local sx = shake>0 and math.random(-2,2) or 0
    local sy = shake>0 and math.random(-2,2) or 0
    if shake>0 then shake=shake-1 end

    spr(player.char, player.x+sx, player.y+sy, 0)

    for _,b in pairs(bullets) do rect(b.x,b.y,3,2,b.col) end
    for _,b in pairs(ebullets) do rect(b.x,b.y,2,2,8) end
    for _,e in pairs(enemies) do spr(e.spr,e.x+sx,e.y+sy,0) end

    drawUI()

    if btnp(7) then state="PAUSE" end
end

function doPause()
    rect(60,20,120,90,0)
    rectb(60,20,120,90,12)
    print("PAUSED",100,30,12)
    print("Press Z: Resume",70,70,15)

    if btnp(4) then state="GAME" end
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
    cls(13)
    printCenter("GAME OVER", 20, 6, 2, true)
    printCenter("Final Score: "..score, 44, 15, 1, true)
    printCenter("--- LEADERBOARD ---", 60, 12, 1, true)

    -- Display up to 5 recent scores
    local y = 75
    for i = math.max(1, #leaderboard-4), #leaderboard do
        print(leaderboard[i].name..": "..leaderboard[i].s, 72, y, 15)
        y = y + 10
    end

    printCenter("PRESS Z TO RESTART", 120, 9, 1, true)

    if btnp(4) then
        initGame()
        state = "TITLE"
    end
    print("GAME OVER", 90, 20, 6)
    print("Final Score: "..score, 80, 40, 15)

    drawLeaderboard()

    print("Press Z to Restart", 75, 120, 9)

    if btnp(4) then initGame() state="TITLE" end
end

-- =====================
-- MAIN LOOP
-- =====================
function TIC()
    if state == "GAME" then
        drawGameField()
    else
        cls(13)
    end

    if state == "TITLE" then
        doTitle()
    elseif state == "SELECT" then
        doSelect()
    elseif state == "MSG" then
        doMsg()
    elseif state == "GAME" then
        doGame()
    elseif state == "PAUSE" then
        doPause()
    elseif state == "GAMEOVER" then
        doGameOver()
    cls(13)

    if state=="TITLE" then doTitle()
    elseif state=="SELECT" then doSelect()
    elseif state=="MSG" then doMsg()
    elseif state=="GAME" then doGame()
    elseif state=="PAUSE" then doPause()
    elseif state=="DYING" then doDying()
    elseif state=="GAMEOVER" then doGameOver()
    end

    t = t + 1
end
