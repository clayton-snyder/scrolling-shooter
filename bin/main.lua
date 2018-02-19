-- need to-dos:
-- make powerus bigger or adjust spawn
-- rename powerup asset files and adjust 

-- possible to-dos:
-- scaling speed and score (spawn increases rationally with movespeed and score)
-- running time
-- audio

debug = true
local music = nil
local musicTimer
local boostMusic = nil
local backgroundImg = nil
local titleScreenImg = nil

titleScreen = true
gameOver = false

playerHP = 5
basePlayerSpeed = 230

score = 0
multiplier = 1

canShoot = true
shootTimerMax = 0.2
currShootTimer = shootTimerMax


bullets = {}
bulletImg = nil
bulletSpeed = 10

enemies = {}
enemyImg = nil
enemySpawnRate = 1
enemySpawnTimer = enemySpawnRate
enemySpawn = nil
enemySpeed = 5

speedBoosts = {}
speedBoostImg = nil
speedBoostSpawnRate = 5.7
speedBoostSpawnTimer = speedBoostSpawnRate
speedBoostSpawn = nil
speedBoostSpeed = 5

scoreBoosts = {}
scoreBoostImg = nil
scoreBoostSpawnRate = 10
scoreBoostSpawnTimer = scoreBoostSpawnRate
scoreBoostSpawn = nil
scoreBoostSpeed = 5
scoreBonus = false
scoreBonusTimer = 0
scoreBonusLength = 5

playerBoosts = 3
speedBoostLength = 5
speedBoostTimer = nil
speedBoost = nil

comboCounter = 0
comboForBoost = 10

player = { x = 200, y = 600, speed = basePlayerSpeed, img = nil }

-- Collision detection function.  from https://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

-- Simply detects if argued enemy has reached the bottom of the screen + the player.img height
function enemyHitsBottom(enemyY)
  return enemyY >= 600
end

--
function love.load()
  backgroundImg = love.graphics.newImage("assets/Space_Background.png")
  player.img = love.graphics.newImage("assets/plane.png")
  bulletImg = love.graphics.newImage("assets/bullet.png")
  enemyImg = love.graphics.newImage("assets/enemy.png")
  speedBoostImg = love.graphics.newImage("assets/speedBoostImg.png")
  scoreBoostImg = love.graphics.newImage("assets/bonusImg.png")
  titleScreenImg = love.graphics.newImage("assets/titleScreen.png")
  music = love.audio.newSource("music/GRETGAMEMUSIC.wav")
  musicTimer = 68
  boostMusic = love.audio.newSource("music/09 Elephant.mp3")
  love.audio.setVolume(0.05)
  music:setVolume(1)
  boostMusic:setVolume(0)
  math.randomseed(os.time())
end


-- Update loop. "dt" is how long has passed since the last call to update
function love.update(dt)
  
  -- ---------- HOUSEKEEPING ----------
  
  -- Subtract the delta time from the music timer
  musicTimer = musicTimer - dt
  
  -- Restart the music if the track has finished
  if musicTimer <= 0 then
    love.audio.play(music)
  end
  
  if titleScreen then
    do return end
  end
  
  -- If the player runs out of HP, empty all NPC tables and set gameOver flag
  if playerHP <= 0 then
    gameOver = true
    speedBoosts = {}
    enemies = {}
  end
  
  -- Check the current combo and update score multiplier if necessary
  if comboCounter < 10 and not scoreBonus then
    multiplier = 1
  end if comboCounter >= 10 and not scoreBonus then
    multiplier = 2
  end if comboCounter >= 20 and not scoreBonus  then
    multiplier = 3
  end if comboCounter >= 30 and not scoreBonus then
    multiplier = 4
  end if comboCounter >= 40 and not scoreBonus then
    multiplier = 5
  end
  
  -- Logic that should happen when a speed boost is active
  if speedBoost then
    -- Shave the speed boost timer
    speedBoostTimer = speedBoostTimer - dt
    
    -- Remove the boost when the timer is up
    if speedBoostTimer <= 0 then
      speedBoost = false
      player.speed = basePlayerSpeed
    end
  end
  
  -- Logic to control firing speed for player
  currShootTimer = currShootTimer - dt
  if currShootTimer < 0 then
    canShoot = true
  end
  
  -- Logic to control the pace of enemy spawns
  enemySpawnTimer = enemySpawnTimer - dt
  if enemySpawnTimer < 0 then
    enemySpawn = true
  end
  
  -- ---------- ENEMY/BOOST UPDATES ----------
  
  -- Logic to spawn new enemies based on a timer. This timer could get steadily
  -- faster as the player survives to add a soft game length cap
  if enemySpawn then
    -- Create a new enemy at a random horizontal location at the top of the screen.
    newEnemy = { x = math.random(480 - enemyImg:getWidth()), y = 0, img = enemyImg }
    
    -- Insert the new enemy into the enemy table
    table.insert(enemies, newEnemy)
    
    -- Reset the enemy timer and flag
    enemySpawnTimer = enemySpawnRate
    enemySpawn = false
  end
  
  
  -- Move the enemy towards the bottom of the screen paced by enemySpeed
  for i, enemy in ipairs(enemies) do
    enemy.y = enemy.y + enemySpeed

    -- Remove the enemy from the table once it reaches the bottom of the screen
    if enemy.y > love.graphics.getHeight() then
      table.remove(enemy)
    end
  end
  
  -- Spawn speed boosts based on a timer
  speedBoostSpawnTimer = speedBoostSpawnTimer - dt
  if speedBoostSpawnTimer <= 0 then
    speedBoostSpawn = true
    speedBoostSpawnTimer = speedBoostSpawnRate
  end
  
  -- Move the speed boosts down the screen
  for i, speedBoost in ipairs(speedBoosts) do
    speedBoost.y = speedBoost.y + speedBoostSpeed
  end
  
  -- Spawn a new speed boost if the flag is set
  if speedBoostSpawn then
    -- Create a new boost object at a random horizontal location at the top of the screen
    newSpeedBoost = { x = math.random(player.img:getWidth() / 2, 480 - player.img:getWidth()), y = 0, img = speedBoostImg }
    
    -- Insert the boost to the boost table
    table.insert(speedBoosts, newSpeedBoost)
    
    -- Reset the flag
    speedBoostSpawn = false
  end

  -- Spawn multipliers based on a timer
  scoreBoostSpawnTimer = scoreBoostSpawnTimer - dt
  if scoreBoostSpawnTimer <= 0 then
    scoreBoostSpawn = true
    scoreBoostSpawnTimer = scoreBoostSpawnRate
  end
  
  
  if scoreBoostSpawn then -- removed logic: 'and not gameOver'; why was this here?
    
    -- Create a new multiplier object at a random horizontal location at the top of the screen
    newBonus = { x = math.random(player.img:getWidth() / 2, 480 - player.img:getWidth()), y = 0, img = scoreBoostImg }
    
    -- Insert the multiplier object into the multiplier table
    table.insert(scoreBoosts, newBonus)
    
    -- Reset the flag
    scoreBoostSpawn = false
  end
  
  -- Move the multipliers down the screen
  for i, bonus in ipairs(scoreBoosts) do
    bonus.y = bonus.y + scoreBoostSpeed
  end
  
  
  -- speedBoost BULLET COLLISION
  for i, bullet in ipairs(bullets) do
    for j, speedBoost in ipairs(speedBoosts) do
      if CheckCollision(bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight(),
                  speedBoost.x, speedBoost.y, speedBoost.img:getWidth(), speedBoost.img:getHeight()) then
        table.remove(bullets, i)
        table.remove(speedBoosts, j)
        player.speed = basePlayerSpeed
        player.speed = player.speed + (player.speed * 0.5)
        speedBoost = true
        speedBoostTimer = speedBoostLength
        comboCounter = comboCounter + 1
      end
    end
  end
  
  -- bonus COLLISION
  for i, bonus in ipairs(scoreBoosts) do
    for j, bullet in ipairs(bullets) do
      if CheckCollision(bonus.x, bonus.y, bonus.img:getWidth(), bonus.img:getHeight(),
                  bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight())then
        table.remove(bullets, j)
        table.remove(scoreBoosts, i)
        comboCounter = comboCounter + 1
        scoreBonus = true
        scoreBonusTimer = scoreBonusLength
        oldMultiplier = multiplier
        multiplier = multiplier * 2
      end
    end
  end
  
  if scoreBonus and scoreBonusTimer <= 0 then
    scoreBonus = false
    multiplier = oldMultiplier
    music:setVolume(1)
    boostMusic:setVolume(0)
  end
  
  
  if scoreBonus then
    scoreBonusTimer = scoreBonusTimer - dt
    if not gameOver then
      boostMusic:setVolume(1)
      music:setVolume(0)
    end
  end
  
  -- ENEMY BULLET COLLISION
  for i, bullet in ipairs(bullets) do
    for j, enemy in ipairs(enemies) do
      -- BULLET ENEMY COLLISION
      if CheckCollision(bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight(),
              enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight()) then
        table.remove(enemies, j)
        table.remove(bullets, i)
        score = score + (100 * multiplier)
        comboCounter = comboCounter + 1
      end
    end
  end
  

 
 -- ENEMY PLAYER COLLISION
 for i, enemy in ipairs(enemies) do
   if enemyHitsBottom(enemy.y) then
      table.remove(enemies, i)
      playerHP = playerHP - 1
    end
  end
  
 -- bullet updates
  
  if love.keyboard.isDown('a') and not gameOver then
    if canShoot then
      newBullet = { x = player.x + player.img:getWidth()/2 - 6, y = player.y - 4, img = bulletImg }
      table.insert(bullets, newBullet)
      currShootTimer = shootTimerMax
      canShoot = false
    end
  end
  
  for i, bullet in ipairs(bullets) do
    bullet.y = bullet.y - bulletSpeed
    
    if bullet.y < 0 then
      table.remove(bullets, i)
      comboCounter = 0
    end
  end
  
  
  
  if love.keyboard.isDown('right') and not gameOver then
    if player.x > (love.graphics.getWidth() - player.img:getWidth()) then 
        player.x = love.graphics.getWidth() - player.img:getWidth()
      else player.x = player.x + player.speed * dt
    end
  end
  
  if love.keyboard.isDown('left') and not gameOver then
    if player.x < 0 then
        player.x = 0
      else player.x = player.x - player.speed * dt
    end
  end 

  -- this condition is to keep the cool disco effect going on the end-game score screen
  if gameOver and scoreBonusTimer <= 0 then
    scoreBonus = true
    scoreBonusTimer = scoreBonusLength
  end
  
end

function love.keypressed(key) 
  if key == 'f' and playerBoosts > 0 then
    player.speed = basePlayerSpeed
    player.speed = player.speed + (player.speed * 0.5)
    playerBoosts = playerBoosts - 1
    speedBoost = true
    speedBoostTimer = speedBoostLength
  end
  if key == 'p' then
    os.exit()
  end
  if key == 'space' then
    if titleScreen then
      titleScreen = false
      love.audio.play(music)
      love.audio.play(boostMusic)
    end
    if gameOver then
      boostMusic:setVolume(0)
      music:setVolume(1)
      --boostMusic:stop()
      --music:stop()
      --love.audio.play(music)
      --love.audio.play(boostMusic)
      scoreBoostSpawnTimer = scoreBoostSpawnRate
      scoreBoostSpawn = false
      speedBoostSpawnTimer = speedBoostSpawnRate
      speedBoostSpawn = false
      enemySpawnTimer = enemySpawnRate
      enemySpawn = false
      score = 0
      scoreBonus = false
      comboCounter = 0
      playerBoosts = 3
      gameOver = false
      playerHP = 5
      scoreBoosts = {}
      enemies = {}
      speedBoosts = {}
    end
  end
  
end

function love.draw(dt)
  love.graphics.setColor(255, 255, 255, 150)
  if multiplier == 2 then
    love.graphics.setColor(255, 230, 0, 225)
  end if multiplier == 3 then
    love.graphics.setColor(0, 250, 0, 200)  
  end if multiplier == 4 then
    love.graphics.setColor(250, 0, 255, 255)
  end if multiplier == 5 then
    love.graphics.setColor(255, 0, 0, 200)
  end
  
  if scoreBonus or gameOver then
    if scoreBonusTimer % 1 > 0 then
      love.graphics.setColor(255, 0, 0, 200)
    end if scoreBonusTimer % 1 > 0.25 then
      love.graphics.setColor(0, 250, 0, 200)
    end if scoreBonusTimer % 1 > 0.5 then
      love.graphics.setColor(250, 0, 255, 200)
    end if scoreBonusTimer % 1 > 0.75 then
      love.graphics.setColor(0, 250, 0, 200)
    end
  end
  
  if not titleScreen then
    love.graphics.draw(backgroundImg, 500, 0, 1.56, 1.3)
  end
  
  love.graphics.setColor(255, 255, 255, 255)
  if not (gameOver or titleScreen) then
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(player.img, player.x, player.y)
  
    for i, speedBoost in ipairs(speedBoosts) do
      love.graphics.draw(speedBoost.img, speedBoost.x, speedBoost.y)
    end
    
    for i, bonus in ipairs(scoreBoosts) do
      love.graphics.draw(bonus.img, bonus.x, bonus.y)
    end
    
    for i, bullet in ipairs(bullets) do
      love.graphics.draw(bullet.img, bullet.x, bullet.y)
    end
    
    for i, enemy in ipairs(enemies) do
      love.graphics.draw(enemy.img, enemy.x, enemy.y)
    end
    
    love.graphics.print("HP " .. playerHP, 00, 00)
    love.graphics.print("SCORE " .. score .. " (x" .. multiplier .. ")", 0, 10)
    love.graphics.print("COMBO " .. comboCounter, love.graphics.getWidth() - 120, 0)
    if playerBoosts == 3 then
      love.graphics.print("BOOSTS: X X X", love.graphics.getWidth() - 120, 10)
    end if playerBoosts == 2 then
      love.graphics.print("BOOSTS: X X", love.graphics.getWidth() - 120, 10)
    end if playerBoosts == 1 then
      love.graphics.print("BOOSTS: X", love.graphics.getWidth() - 120, 10)
    end if playerBoosts == 0 then
      love.graphics.print("OUT OF BOOSTS", love.graphics.getWidth() - 120, 10)
    end
        
    if speedBoost then
      love.graphics.print("SPEED BOOSTED for " .. math.ceil(speedBoostTimer), 0, 20)
    end
  end
  
  if titleScreen then
    love.graphics.print("a to shoot", 208, 200)
    love.graphics.print("arrow keys to move", 183, 215)
    love.graphics.print("f to use a speed boost", 173, 230)
    love.graphics.print("ready to play?", 205, 435)
    love.graphics.print("press space", 210, 450)
  end
  
  
  if gameOver then
    love.graphics.print("SCORE: " .. score, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 20)
    love.graphics.print("Q TO QUIT", (love.graphics.getWidth() / 3) * 2, (love.graphics.getHeight() / 3) * 2)
    local r, b, g, a = love.graphics.getColor()
    local rb, bb, gb, ab = love.graphics.getColor()
    --love.graphics.print(r .. " " .. g .. " " .. b .. a .. " HIHI", 00, 00)
    --love.graphics.print(rb .. " " .. gb .. " " .. bb .. ab .. " HIHI", 00, 10)
    if love.keyboard.isDown('q') then
      os.exit()
    end
    
  end
  

end