-- title:  Defend the Dept (Merged Final)
-- author: You & Rithik
-- desc:   PvZ style lane shooter (Balanced + Sprites)
-- script: lua

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

    -- shooting (controlled limit with custom sprites)
    if player.cooldown > 0 then player.cooldown = player.cooldown - 1 end

    if btn(4) and player.cooldown <= 0 then
        if #bullets < 5 then
            table.insert(bullets, {
                x=player.x+8,
                y=player.y+2,
                speed=4, 
                spr=32+player.char -- Restored original bullet sprites
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

    -- enemy bullets
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

        if e.is_shooter then
            e.shoot_timer = e.shoot_timer + 1
            if e.shoot_timer > 100 then
                -- Restored zombie bullet sprite
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

    -- death
    if lives <= 0 and state ~= "DYING" then
        state = "DYING"
        game_over_timer = 120
        sfxDeath()
    end
end

-- =====================
-- UI & LEADERBOARD
-- =====================
function drawUI()
    print("SCORE: "..score, 5, 5, 12)
    print("LVL: "..math.floor(difficulty), 150, 5, 11)
    for i=1,lives do spr(6, 200+(i*10), 4, 0) end
end

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
    print("Press Z to Select", 75, 110, 15)

    if btnp(4) then state="MSG" end
end

function doMsg()
    print("DEFEND THE DEPT! GO!", 60, 60, 9, true, 2)
    msg_timer = msg_timer - 1
    if msg_timer <= 0 then state="GAME" end
end

function doGame()
    updateGame()

    local sx = shake>0 and math.random(-2,2) or 0
    local sy = shake>0 and math.random(-2,2) or 0
    if shake>0 then shake=shake-1 end

    -- Restored: Drawing Player AND their specific gun
    spr(player.char, player.x+sx, player.y+sy, 0)
    spr(16+player.char, player.x+8+sx, player.y+sy, 0)

    -- Restored: Entities drawn as sprites
    for _,b in pairs(bullets) do spr(b.spr, b.x, b.y, 0) end
    for _,b in pairs(ebullets) do spr(b.spr, b.x, b.y, 0) end
    for _,e in pairs(enemies) do spr(e.spr, e.x+sx, e.y+sy, 0) end

    drawUI()

    if btnp(7) then state="PAUSE" end
end

function doPause()
    rect(60,20,120,90,0)
    rectb(60,20,120,90,12)
    print("PAUSED",100,30,12)
    print("Press Z: Resume",70,60,15)
    print("Press X: Title",70,75,15) -- Restored Quit Option

    if btnp(4) then state="GAME" end
    if btnp(5) then initGame() state="TITLE" end
end

function doDying()
    cls(2) -- Flashes screen red on death
    game_over_timer = game_over_timer - 1

    if game_over_timer <= 0 then
        addScore()
        state = "GAMEOVER"
    end
end

function doGameOver()
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
