local Sounds = {    
    -- grouped sets of sounds
    playerSounds      = {},
    projectileSounds  = {},
    enemySounds       = {},
    collectableSounds = {},
    generalSounds     = {},
    music             = {},
}

-- Aliases
local loadSound   = audio.loadSound
local unloadSound = audio.dispose
local findChannel = audio.findFreeChannel
local setVolume   = audio.setVolume
local play        = audio.play


function Sounds:preload()
    self.playerSounds.hurt           = loadSound("sounds/hurt.mp3")
    self.playerSounds.killed         = loadSound("sounds/killed.mp3")

    self.projectileSounds.rifleShot  = loadSound("sounds/rifleShot.wav")
    self.projectileSounds.shotGunShot  = loadSound("sounds/shotGunShot.mp3")

    self.projectileSounds.bulletHit  = loadSound("sounds/bulletHit.mp3")
    self.projectileSounds.rocketShot = loadSound("sounds/rocketShot.mp3")
    self.projectileSounds.rocketHit  = loadSound("sounds/rocketHit.mp3")
    self.projectileSounds.laserShot  = loadSound("sounds/laserShot.mp3")
    self.projectileSounds.laserHit   = loadSound("sounds/laserHit.mp3")
    self.projectileSounds.reload     = loadSound("sounds/reload.mp3")

    self.enemySounds.hurt            = loadSound("sounds/hurt.mp3")
    self.enemySounds.killed          = loadSound("sounds/killed.mp3")
    self.enemySounds.charge          = loadSound("sounds/charge.wav")
<<<<<<< HEAD
    self.enemySounds.charge          = loadSound("sounds/charge.mp3")
=======
>>>>>>> 33f7ae4b65a4a62914c3cf8fcd7d2abd5565561c
    self.enemySounds.melee           = loadSound("sounds/melee.mp3")

    self.collectableSounds.gotWeapon = loadSound("sounds/collectedWeapon.wav")

    self.generalSounds.gameOver      = loadSound("sounds/gameOver.mp3")
end


function Sounds:play(sound, options)
    local channel = nil

    if options and options.channel then
        channel = options.channel
    else
        channel = findChannel()
        if options then
            options.channel = channel
        else
            options = {channel=channel}
        end
    end

    setVolume(options.volume or 1, options)
    play(sound, options)
end


function Sounds:player(sound, params)
    self:play(self.playerSounds[sound], params)
end


function Sounds:projectile(sound, params)
    self:play(self.projectileSounds[sound], params)
end


function Sounds:enemy(sound, params)
    self:play(self.enemySounds[sound], params)
end


function Sounds:collectable(sound, params)
    self:play(self.collectableSounds[sound], params)
end


function Sounds:general(sound, params)
    self:play(self.generalSounds[sound], params)
end


return Sounds