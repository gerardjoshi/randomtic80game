-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- licen-- title:  Defend the Dept
-- author: You
-- desc:   PvZ style lane shooter
-- script: lua

-- GLOBAL VARIABLES (Persist across game restarts)
leaderboard = {}
session_id = 1
state = "TITLE" -- TITLE, SELECT, MSG, GAME, PAUSE, GAMEOVER
t = 0

function initGame()
    score = 0
    lives = 3
    player = {x=10, y=68, char=1, speed=2, cooldown=0}
    bullets = {}
    enemies = {}
    ebullets = {}
    msg_timer = 120 -- 2 seconds for "Defend the Dept! GO!"
end

initGame()

-- GAMEPLAY FUNCTIONS
function spawnEnemy()
    -- Random lane (roughly 4 rows)
    local ey = 20 + (math.random(0,3) * 20)
    local type = math.random(1,4)
    local e = {x=240, y=ey, hp=2, speed=math.random(3,8)/10, shoot_timer=0}
    
    if type == 4 then
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
    -- Player Movement (Up/Down)
    if btn(0) and player.y > 10 then player.y = player.y - player.speed end
    if btn(1) and player.y < 120 then player.y = player.y + player.speed end
    
    -- Player Shooting (Z key / A button)
    if player.cooldown > 0 then player.cooldown = player.cooldown - 1 end
    if btn(4) and player.cooldown == 0 then
        table.insert(bullets, {x=player.x+8, y=player.y+2, spr=32+player.char})
        player.cooldown = 15
    end

    -- Update Bullets
    for i=#bullets,1,-1 do
        local b = bullets[i]
        b.x = b.x + 4
        if b.x > 240 then table.remove(bullets, i) end
    end
    
    -- Update Enemy Bullets
    for i=#ebullets,1,-1 do
        local b = ebullets[i]
        b.x = b.x - 2
        if collide(b, player, 8) then
            lives = lives - 1
            table.remove(ebullets, i)
        elseif b.x < 0 then
            table.remove(ebullets, i)
        end
    end

    -- Update Enemies & Collisions
    if t % 60 == 0 then spawnEnemy() end -- Spawn every 1 sec
    
    for i=#enemies,1,-1 do
        local e = enemies[i]
        e.x = e.x - e.speed
        
        -- Enemy shooting logic
        if e.is_shooter then
            e.shoot_timer = e.shoot_timer + 1
            if e.shoot_timer > 90 then
                table.insert(ebullets, {x=e.x, y=e.y+2, spr=36})
                e.shoot_timer = 0
            end
        end

        -- Reached Player Line
        if e.x <= player.x then
            lives = lives - 1
            table.remove(enemies, i)
        else
            -- Check bullet hits
            for j=#bullets,1,-1 do
                if collide(bullets[j], e, 8) then
                    e.hp = e.hp - 1
                    table.remove(bullets, j)
                    if e.hp <= 0 then
                        score = score + 10
                        table.remove(enemies, i)
                        break
                    end
                end
            end
        end
    end

    -- Check Death
    if lives <= 0 then
        table.insert(leaderboard, {name="Player "..session_id, s=score})
        session_id = session_id + 1
        state = "GAMEOVER"
    end
end

-- DRAWING FUNCTIONS
function drawUI()
    print("SCORE: "..score, 5, 5, 12)
    for i=1, lives do spr(6, 200 + (i*10), 4, 0) end
end

-- STATE MANAGERS
function doTitle()
    print("DEFEND THE DEPT", 75, 40, 11, true, 2)
    print("Press Z to Start", 80, 80, 15)
    if btnp(4) then state = "SELECT" end
end

function doSelect()
    print("CHOOSE CHARACTER", 80, 20, 12)
    -- Draw 3 options
    spr(1, 60, 60, 0, 2)
    spr(2, 110, 60, 0, 2)
    spr(3, 160, 60, 0, 2)
    
    -- Selection cursor
    if btnp(2) and player.char > 1 then player.char = player.char - 1 end
    if btnp(3) and player.char < 3 then player.char = player.char + 1 end
    
    print("^", 64 + ((player.char-1)*50), 85, 9)
    print("Press Z to Select", 75, 110, 15)
    
    if btnp(4) then state = "MSG" end
end

function doMsg()
    print("DEFEND THE DEPT! GO!", 60, 60, 9, true, 2)
    msg_timer = msg_timer - 1
    if msg_timer <= 0 then state = "GAME" end
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
    
    if btnp(4) then state = "GAME" end
    if btnp(5) then initGame() state = "TITLE" end
end

function doGameOver()
    print("GAME OVER", 95, 20, 6)
    print("Final Score: "..score, 80, 40, 15)
    print("--- LEADERBOARD ---", 70, 60, 12)
    
    -- Display up to 5 recent scores
    local y = 75
    for i = math.max(1, #leaderboard-4), #leaderboard do
        print(leaderboard[i].name..": "..leaderboard[i].s, 80, y, 15)
        y = y + 10
    end
    
    print("Press Z to Restart", 75, 120, 9)
    if btnp(4) then initGame() state = "TITLE" end
end

-- MAIN LOOP
function TIC()
    cls(13) -- Clear screen with background color
    
    if state == "TITLE" then doTitle()
    elseif state == "SELECT" then doSelect()
    elseif state == "MSG" then doMsg()
    elseif state == "GAME" then doGame()
    elseif state == "PAUSE" then doPause()
    elseif state == "GAMEOVER" then doGameOver()
    end
    
    t = t + 1
end
