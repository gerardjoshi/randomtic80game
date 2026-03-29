-- title:  Defend the Dept (The Ultimate Master)
-- author: You, Rithik, Pasanth, Varun & Joshi
-- desc:   PvZ lane shooter (Balanced + UI + Powerups + Custom Art)
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
    player = {
        x=10, y=68, char=1, speed=2, cooldown=0,
        fire_rate_boost_timer=0, shield=0
    }
    bullets = {}
    enemies = {}
    ebullets = {}
    powerups = {}
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
-- CUSTOM ART & POWERUPS (Varun)
--------------------------------------------------
function drawCampusEnvironment()
    -- Animated Rotating Sun (Yellow)
    local sx, sy = 25, 25
    for i=0, 7 do
        local angle = (t / 30) + (i * math.pi / 4)
        line(sx, sy, sx + math.cos(angle)*14, sy + math.sin(angle)*14, 4) -- Yellow spokes
    end
    circ(sx, sy, 8, 3) -- Orange inner
    circ(sx, sy, 5, 4) -- Yellow core
    
    -- Moving Clouds (Dark Gray / Black)
    local cx1 = (t * 0.2) % 300 - 40
    circ(cx1, 20, 8, 15) circ(cx1+10, 18, 12, 15) circ(cx1+20, 22, 7, 15)
    local cx2 = (t * 0.15 + 150) % 300 - 40
    circ(cx2, 45, 10, 15) circ(cx2+14, 42, 15, 15) circ(cx2+28, 46, 9, 15)

    -- Sidewalk
    rect(0, 115, 240, 21, 13) 
    -- Road
    rect(0, 125, 240, 11, 1) 
    
    -- Proper Picket Fence
    rect(0, 110, 240, 2, 14) -- Top rail
    rect(0, 118, 240, 2, 14) -- Bottom rail
    for i=0, 24 do
        local px = i * 10
        rect(px, 107, 3, 14, 14) -- Picket
        tri(px, 107, px+1.5, 104, px+3, 107, 14) -- Pointy top
    end
end

function drawEEEBuilding()
    rect(140, 30, 80, 100, 0) 
    rectb(140, 30, 80, 100, 12)
    
    for i=0, 3 do
        line(140, 50+(i*20), 220, 50+(i*20), 13)
    end

    local glow = (t % 60 < 30) and 11 or 9
    for i=0, 2 do
        local ox = 152 + (i*22)
        rect(ox, 35, 4, 12, glow)
        rect(ox, 35, 12, 3, glow)
        rect(ox, 41, 9, 3, glow)
        rect(ox, 47, 12, 2, glow)
    end
    
    for wy=75, 110, 15 do
        for wx=150, 200, 20 do
            rect(wx, wy, 8, 8, 14)
            pix(wx+2, wy+2, 15)
        end
    end
end

function drawCharacter1(x, y, scale)
    scale = scale or 1
    local function R(px, py, w, h, c) rect(x + px*scale, y + py*scale, w*scale, h*scale, c) end
    local function P(px, py, c) rect(x + px*scale, y + py*scale, scale, scale, c) end

    local HAIR, SKIN, SHADOW, SHIRT, SHIRT_DARK, EYE, MOUTH = 0, 2, 1, 12, 13, 0, 1

    R(1,0,6,2,HAIR)
    R(0,1,8,1,HAIR)
    R(1,2,6,4,SKIN)
    P(0,3,SKIN)
    P(7,3,SKIN)
    P(0,2,HAIR)
    P(7,2,HAIR)
    P(0,4,HAIR)
    P(7,4,HAIR)
    P(2,3,EYE)
    P(5,3,EYE)
    P(2,2,HAIR)
    P(5,2,HAIR)
    P(4,4,SHADOW)
    P(3,5,MOUTH)
    P(4,5,MOUTH)
    P(3,6,SKIN)
    P(4,6,SKIN)
    R(1,7,6,3,SHIRT)
    P(2,7,SHIRT_DARK)
    P(5,7,SHIRT_DARK)
    P(3,8,SHIRT_DARK)
    P(4,8,SHIRT_DARK)
end

function drawWeapon1(x, y, scale)
    scale = scale or 1
    local function R(px, py, w, h, c) rect(x + px*scale, y + py*scale, w*scale, h*scale, c) end
    local function P(px, py, c) rect(x + px*scale, y + py*scale, scale, scale, c) end

    local ARM, ARM_DARK, GUN, GUN_LIGHT = 12, 13, 0, 5
    R(0,2,3,3,ARM)
    P(1,1,ARM_DARK)
    R(3,2,4,2,GUN)
    P(7,2,GUN_LIGHT)
    P(5,4,GUN)
    P(4,5,GUN)
end

function drawCharacter2(x, y, scale)
    scale = scale or 1

    local function R(px, py, w, h, c)
        rect(x + px*scale, y + py*scale, w*scale, h*scale, c)
    end

    local function P(px, py, c)
        rect(x + px*scale, y + py*scale, scale, scale, c)
    end

    -- Better readable palette
    local HAIR = 13       -- grey
    local HAIR_LIGHT = 12 -- lighter grey highlight
    local SKIN = 2
    local SKIN_SHADOW = 3
    local GLASS = 14
    local BEARD = 1
    local SHIRT = 4
    local SHIRT_DARK = 3
    local EYE = 0

    -- =========================
    -- HAIR (proper hairline)
    -- =========================
    R(1,0,6,1,HAIR)
    R(0,1,8,1,HAIR)
    P(1,0,HAIR_LIGHT)
    P(2,0,HAIR_LIGHT)
    P(5,0,HAIR_LIGHT)
    P(6,0,HAIR_LIGHT)
    P(0,2,HAIR)
    P(7,2,HAIR)

    -- =========================
    -- FACE
    -- =========================
    R(1,2,6,4,SKIN)
    P(0,3,SKIN)
    P(7,3,SKIN)
    P(1,6,SKIN)
    P(6,6,SKIN)

    -- =========================
    -- GLASSES (smaller, cleaner)
    -- =========================
    P(1,3,GLASS)
    P(2,3,GLASS)
    P(5,3,GLASS)
    P(6,3,GLASS)
    P(3,3,SKIN_SHADOW)
    P(4,3,SKIN_SHADOW)

    -- eyes
    P(2,3,EYE)
    P(5,3,EYE)

    -- =========================
    -- NOSE
    -- =========================
    P(4,4,SKIN_SHADOW)

    -- =========================
    -- MOUSTACHE + BEARD
    -- =========================
    P(3,5,BEARD)
    P(4,5,BEARD)
    P(2,6,BEARD)
    P(3,6,BEARD)
    P(4,6,BEARD)
    P(5,6,BEARD)

    -- =========================
    -- NECK
    -- =========================
    P(3,7,SKIN)
    P(4,7,SKIN)

    -- =========================
    -- SHIRT
    -- =========================
    R(1,8,6,3,SHIRT)
    P(2,8,SHIRT_DARK)
    P(5,8,SHIRT_DARK)
    P(3,9,SHIRT_DARK)
    P(4,9,SHIRT_DARK)
end

function drawWeapon2(x, y, scale)
    scale = scale or 1
    local function R(px, py, w, h, c) rect(x + px*scale, y + py*scale, w*scale, h*scale, c) end
    local function P(px, py, c) rect(x + px*scale, y + py*scale, scale, scale, c) end

    local ARM, ARM_DARK, GUN, GUN_LIGHT = 4, 3, 0, 5
    R(0,2,3,3,ARM)
    P(1,1,ARM_DARK)
    R(3,2,4,2,GUN)
    P(7,2,GUN_LIGHT)
    P(5,4,GUN)
    P(4,5,GUN)
end

function drawCharacter3(x, y, scale)
    scale = scale or 1
    local function R(px, py, w, h, c) rect(x + px*scale, y + py*scale, w*scale, h*scale, c) end
    local function P(px, py, c) rect(x + px*scale, y + py*scale, scale, scale, c) end

    local HAIR, SKIN, SHIRT, EYE = 0, 2, 12, 0
    R(1,0,6,2,HAIR)
    R(0,1,8,1,HAIR)
    P(0,2,HAIR) 
    P(7,2,HAIR)
    R(1,2,6,4,SKIN)
    P(0,3,SKIN)
    P(7,3,SKIN)
    P(2,3,EYE)
    P(5,3,EYE)
    R(1,7,6,3,SHIRT)
    P(3,7,15) 
    P(4,7,15)
end

function drawWeapon3(x, y, scale)
    scale = scale or 1
    local function R(px, py, w, h, c) rect(x + px*scale, y + py*scale, w*scale, h*scale, c) end
    local function P(px, py, c) rect(x + px*scale, y + py*scale, scale, scale, c) end

    local ARM, GUN, MUZZLE = 2, 0, 15
    R(0,2,3,2,ARM)
    R(3,2,4,2,GUN)
    P(6,2,MUZZLE)
    P(4,4,GUN)
end

--------------------------------------------------
-- NEW PROJECTILE & ENEMY SPRITES
--------------------------------------------------
function drawRocket(x, y)
    rect(x+2, y+3, 4, 2, 14) -- Rocket body
    pix(x+6, y+3, 2) pix(x+6, y+4, 2) pix(x+7, y+3.5, 2) -- Red nose cone
    
    local f = (t % 10 < 5) and 1 or 2 -- Animated fire switch
    rect(x, y+3, 2, 2, 9) -- Base orange fire
    if f == 1 then
        pix(x-1, y+3, 10) pix(x-1, y+4, 9) -- Yellow tip flicker
    else
        pix(x-1, y+4, 10) pix(x-1, y+3, 9)
    end
end

function drawGreenZombie(x, y)
    local SKIN, CLOTHES = 5, 13
    rect(x+2, y+0, 5, 4, SKIN) -- Head
    pix(x+3, y+1, 0) -- Empty eye
    pix(x+2, y+3, 0) -- Jaw
    rect(x+3, y+4, 4, 4, CLOTHES) -- Torn Body
    rect(x+0, y+3, 4, 2, SKIN) -- Arms reaching left
    rect(x+3, y+8, 4, 1, SKIN) -- Legs
end

function drawBlackZombie(x, y)
    local SKIN, CLOTHES = 1, 0 
    rect(x+2, y+0, 5, 4, SKIN) -- Dark Grey Head
    pix(x+3, y+1, 6) -- Glowing Green eye!
    pix(x+2, y+3, 0) -- Jaw
    rect(x+3, y+4, 4, 4, CLOTHES) -- Black Body
    rect(x+0, y+3, 4, 2, SKIN) -- Arms reaching left
    rect(x+3, y+8, 4, 1, SKIN) -- Legs
end

function drawGreenOoze(x, y)
    local wobble = math.sin(t / 5) * 1
    circ(x+3, y+3 + wobble, 2, 5) -- Base ooze ball
    circ(x+3, y+3 + wobble, 1, 6) -- Bright center
    pix(x+5, y+3 + wobble, 5) -- Droplet coming off
end

--------------------------------------------------
-- POWERUPS
--------------------------------------------------
function spawnPowerup(x, y, ptype)
    table.insert(powerups, {
        x = x,
        y = y,
        base_y = y,
        spr = 48,
        speed = 0.6,
        anim = math.random(0,20),
        type = ptype or "rapid"
    })
end

function drawPowerup(p)
    local x, y, blink = p.x, p.y, (t % 20 < 10)

    if p.type == "shield" then
        circ(x+4, y+4, 5, 10)
        circ(x+4, y+4, 4, 15)
        circb(x+4, y+4, 5, 10)

        line(x+1, y+2, x+4, y+2, 6)
        line(x+4, y+2, x+2, y+5, 6)

        line(x+5, y+2, x+7, y+2, 6)
        line(x+5, y+2, x+5, y+3, 6)
        line(x+5, y+4, x+7, y+4, 6)
        line(x+7, y+4, x+7, y+5, 6)
        line(x+5, y+6, x+7, y+6, 6)

        if blink then
            pix(x+0, y+1, 15)
            pix(x+7, y+1, 15)
            pix(x+1, y+7, 15)
        end
    elseif p.type == "heart" then
        circ(x+4, y+4, 5, 10)
        circ(x+4, y+4, 4, 2) -- Red circle
        -- Draw white heart
        pix(x+3, y+2, 15) pix(x+5, y+2, 15)
        line(x+2, y+3, x+6, y+3, 15)
        line(x+3, y+4, x+5, y+4, 15)
        pix(x+4, y+5, 15)
        
        if blink then
            pix(x+2, y+2, 15)
            pix(x+6, y+2, 15)
        end
    else
        circ(x+4, y+4, 5, 10)
        circ(x+4, y+4, 3, 15)

        tri(x+4, y+0, x+2, y+4, x+5, y+4, 10)
        tri(x+5, y+4, x+3, y+7, x+6, y+5, 15)

        line(x+4, y+0, x+2, y+4, 15)
        line(x+5, y+4, x+3, y+7, 10)

        if blink then
            pix(x+1, y+1, 15)
            pix(x+7, y+3, 15)
            pix(x+1, y+7, 15)
        end
    end
end

--------------------------------------------------
-- GAMEPLAY FUNCTIONS
--------------------------------------------------
function spawnEnemy()
    local ey = 20 + (math.random(0,3) * 20)
    local typ = math.random(1,4)
    local e = {x=240, y=ey, hp=2, speed=(math.random(3,8)/10) + difficulty*0.15, shoot_timer=0}

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
    if intro_hint_timer > 0 then intro_hint_timer = intro_hint_timer - 1 end
    difficulty = 1 + (t / 3000)

    -- Player Movement
    if btn(0) and player.y > 10 then player.y = player.y - player.speed end
    if btn(1) and player.y < 120 then player.y = player.y + player.speed end

    -- Powerup Timers
    if player.fire_rate_boost_timer > 0 then
        player.fire_rate_boost_timer = player.fire_rate_boost_timer - 1
    end

    -- Player Shooting
    if player.cooldown > 0 then player.cooldown = player.cooldown - 1 end
    if btn(4) and player.cooldown <= 0 then
        if #bullets < 15 then
            table.insert(bullets, {x=player.x+8, y=player.y+2, speed=5, spr=32+player.char})
            sfxShoot()
        end

        if player.fire_rate_boost_timer > 0 then
            player.cooldown = 3
        else
            player.cooldown = math.max(6, 12 - difficulty)
        end
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
            if player.shield > 0 then
                player.shield = player.shield - 1
            else
                lives = lives - 1
                shake = 10
            end
            sfxHit()
            table.remove(ebullets, i)
        elseif b.x < 0 then
            table.remove(ebullets, i)
        end
    end

    -- Update Powerups
    for i=#powerups,1,-1 do
        local p = powerups[i]
        p.x = p.x - p.speed
        p.anim = p.anim + 1
        p.y = p.base_y + math.sin(p.anim / 12) * 1

        if collide(p, player, 8) then
            if p.type == "shield" then
                player.shield = 1
            elseif p.type == "heart" then
                if lives < 3 then lives = lives + 1 end
            else
                player.fire_rate_boost_timer = 300
            end
            table.remove(powerups, i)
        elseif p.x < 0 then
            table.remove(powerups, i)
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
            if player.shield > 0 then
                player.shield = player.shield - 1
            else
                lives = lives - 1
                shake = 10
            end
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

                        local dropChance = e.is_shooter and 3 or 6
                        if math.random(1, dropChance) == 1 then
                            local r = math.random(1, 3)
                            local ptype = "rapid"
                            if r == 1 then ptype = "shield"
                            elseif r == 2 then ptype = "heart" end
                            spawnPowerup(e.x, e.y, ptype)
                        end

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
    for i=1, lives do spr(6, 200 + (i*10), 4, 0) end

    if player.fire_rate_boost_timer > 0 then printCenter("HIGH VOLTAGE!", 15, 10, 1) end
    if player.shield > 0 then printCenter("ATTENDANCE REQUIREMENT: 75%", 25, 11, 1, true) end
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
    local SKIN, HAIR, BLK = 15, 0, 1
    
    -- Face L (EEE)
    circ(60, 45, 18, 11) circ(60, 45, 16, SKIN) -- Base
    circ(55, 42, 3, 11) circ(55, 42, 2, BLK) -- Eye
    rect(52, 32, 16, 4, HAIR) -- Stylized Hair
    print("EEE", 53, 40, 10, false, 1) -- On face (Yellow text, Color 4)
    
    -- Face R (ECE)
    circ(180, 45, 18, 9) circ(180, 45, 16, SKIN) -- Base
    circ(185, 42, 3, 9) circ(185, 42, 2, BLK) -- Eye
    rect(172, 32, 16, 4, 13) -- Grey Stylized Hair
    print("ECE", 173, 40, 10, false, 1) -- On face (Yellow text, Color 4)
    
    -- The Fists (Bro-grabs)
    -- Fist L (leaning blue)
    rect(90, 40, 25, 15, 11) -- Arm L
    circ(112, 47, 8, 11) circb(112, 47, 8, BLK)
    for i=0, 2 do line(112, 41+i*3, 118, 41+i*3, BLK) end -- Knuckles L
    
    -- Fist R (leaning orange)
    rect(125, 40, 25, 15, 9) -- Arm R
    circ(127, 47, 8, 9) circb(127, 47, 8, BLK)
    for i=0, 2 do line(127, 41+i*3, 121, 41+i*3, BLK) end -- Knuckles R
    
    -- Preservation of existing UI logic (Modified title placement/color per request)
    printCenter("DEFEND THE DEPT", 12, 2, 2, true)
    printCenter("Lane Shooter", 64, 12, 1, true)
    printCenter("PRESS Z TO START", 78, 15, 1, true)
    drawTitleControls()
    if btnp(4) then state = "SELECT" end
end

function doSelect()
    printCenter("CHOOSE CHARACTER", 15, 12, 1, true)

    drawCharacter1(60, 50, 2)
    drawWeapon1(76, 50, 2)

    drawCharacter2(110, 50, 2)
    drawWeapon2(128, 58, 2)

    drawCharacter3(160, 50, 2)
    drawWeapon3(178, 54, 2)

    print("DR. RAKESH", 42, 90, 15)
    print("PANDA", 58, 98, 15)
    print("DR. P. RAJA", 104, 90, 15)
    print("JOSHI", 156, 90, 15)

    print("^", 64 + ((player.char-1)*50), 108, 9)
    printCenter("LEFT / RIGHT TO CHOOSE", 118, 15, 1, true)
    printCenter("PRESS Z TO SELECT", 128, 15, 1, true)

    if btnp(2) and player.char > 1 then player.char = player.char - 1 end
    if btnp(3) and player.char < 3 then player.char = player.char + 1 end
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
    
    drawCampusEnvironment()
    drawEEEBuilding()

    local sx = shake>0 and math.random(-2,2) or 0
    local sy = shake>0 and math.random(-2,2) or 0
    if shake>0 then shake=shake-1 end

    if player.char == 1 then
        drawCharacter1(player.x+sx, player.y+sy, 1)
        drawWeapon1(player.x+8+sx, player.y+sy, 1)
    elseif player.char == 2 then
        drawCharacter2(player.x+sx, player.y+sy, 1)
        drawWeapon2(player.x+8+sx, player.y+sy, 1)
    elseif player.char == 3 then
        drawCharacter3(player.x+sx, player.y+sy, 1)
        drawWeapon3(player.x+8+sx, player.y+sy, 1)
    else
        spr(player.char, player.x+sx, player.y+sy, 0)
        spr(16+player.char, player.x+8+sx, player.y+sy, 0)
    end

    if player.shield > 0 then circ(player.x+4+sx, player.y+4+sy, 6, 11) end

    for _,b in pairs(bullets) do drawRocket(b.x, b.y) end
    for _,b in pairs(ebullets) do drawGreenOoze(b.x, b.y) end
    for _,p in pairs(powerups) do drawPowerup(p) end
    
    for _,e in pairs(enemies) do
        if e.is_shooter then 
            drawBlackZombie(e.x+sx, e.y+sy)
        else 
            drawGreenZombie(e.x+sx, e.y+sy) 
        end
    end

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
    printCenter("NOT ENOUGH VOLTAGE BROCHACHO", 64, 15, 1, true)
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
    if btnp(4) then initGame() state = "TITLE" end
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
function TIC()
    cls(13)
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
