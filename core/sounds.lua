local Sounds = {    
    -- grouped sets of sounds
    playerSounds      = {},
    projectileSounds  = {},
    enemySounds       = {},
    collectableSounds = {},
    music             = {},
}

-- Aliases
local loadSound   = audio.loadSound
local unloadSound = audio.dispose
local findChannel = audio.findFreeChannel
local setVolume   = audio.setVolume
local play        = audio.play


function Sounds:preload()
    self.playerSounds.hurt          = loadSound("sounds/hurt.mp3")
    self.playerSounds.killed        = loadSound("sounds/killed.mp3")

    self.projectileSounds.rifleShot = loadSound("sounds/rifleShot.mp3")
    self.projectileSounds.bulletHit = loadSound("sounds/bulletHit.mp3")
    self.projectileSounds.reload    = loadSound("sounds/reload.mp3")

    self.enemySounds.hurt           = loadSound("sounds/hurt.mp3")
    self.enemySounds.killed         = loadSound("sounds/killed.mp3")
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


return Sounds