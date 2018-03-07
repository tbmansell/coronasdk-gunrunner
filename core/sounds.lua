local Sounds = {    
    -- grouped sets of sounds
    playerSounds      = {},
    projectileSounds  = {},
    enemySounds       = {},
    collectableSounds = {},
    voices            = {},
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
    self.playerSounds.hurt              = loadSound("sounds/hurt.mp3")
    self.playerSounds.killed            = loadSound("sounds/killed.mp3")

    self.projectileSounds.rifleShot     = loadSound("sounds/rifleShot.wav")
    self.projectileSounds.shotGunShot   = loadSound("sounds/shotGunShot.mp3")
    self.projectileSounds.rocketShot    = loadSound("sounds/rocketShot.mp3")
    self.projectileSounds.laserShot     = loadSound("sounds/laserShot.mp3")
    self.projectileSounds.laserBolt     = loadSound("sounds/laserBolt.mp3")
    self.projectileSounds.chainGunShot  = loadSound("sounds/chainGunShot.mp3")
    self.projectileSounds.flamerShot    = loadSound("sounds/flamerShot.wav")
    
    self.projectileSounds.bulletHit     = loadSound("sounds/bulletHit.mp3")
    self.projectileSounds.rocketHit     = loadSound("sounds/rocketHit.mp3")
    self.projectileSounds.laserHit      = loadSound("sounds/laserHit.mp3")
    self.projectileSounds.reload        = loadSound("sounds/reload.mp3")
    self.projectileSounds.flamerHit     = loadSound("sounds/flamerHit.wav")

    self.projectileSounds.crateExplode1 = loadSound("sounds/crateExplode_1.wav")
    self.projectileSounds.crateExplode2 = loadSound("sounds/crateExplode_2.wav")
    self.projectileSounds.crateExplode3 = loadSound("sounds/crateExplode_3.wav")

    self.enemySounds.hurt               = loadSound("sounds/hurt.mp3")
    self.enemySounds.killed             = loadSound("sounds/killed.mp3")
    self.enemySounds.charge             = loadSound("sounds/charge.mp3")
    self.enemySounds.melee              = loadSound("sounds/melee.mp3")

    self.collectableSounds.gotWeapon    = loadSound("sounds/collectedWeapon.wav")
    self.collectableSounds.gotJewel     = loadSound("sounds/collectedJewel.mp3")

    -- weapon voices
    self.voices.rifle                   = loadSound("sounds/voices/battleRifle.mp3")
    self.voices.shotgun                 = loadSound("sounds/voices/shotgun.mp3")
    self.voices.launcher                = loadSound("sounds/voices/rocketLauncher.mp3")
    self.voices.lasergun                = loadSound("sounds/voices/plasmaRifle.mp3")
    self.voices.chainGun                = loadSound("sounds/voices/chainGun.mp3")
    self.voices.laserCannon             = loadSound("sounds/voices/laserCannon.mp3")
    -- collectable voices
    self.voices.damage                  = loadSound("sounds/voices/increasedDamage.mp3")
    self.voices.extraAmmo               = loadSound("sounds/voices/extendedMag.mp3")
    self.voices.fastMove                = loadSound("sounds/voices/speedBoost.mp3")
    self.voices.fastShoot               = loadSound("sounds/voices/rapidFire.mp3")
    self.voices.health                  = loadSound("sounds/voices/health.mp3")
    self.voices.laserSight              = loadSound("sounds/voices/laserSight.mp3")
    self.voices.shield                  = loadSound("sounds/voices/shield.mp3")
    -- general voices
    self.voices.goodLuck                = loadSound("sounds/voices/goodLuck.mp3")
    self.voices.getReady                = loadSound("sounds/voices/getReady.mp3")
    self.voices.hopeReady               = loadSound("sounds/voices/hopeReady.mp3")
    self.voices.fight                   = loadSound("sounds/voices/fight.mp3")
    self.voices.warning                 = loadSound("sounds/voices/warning.mp3")
    self.voices.betterLuckNextTime      = loadSound("sounds/voices/betterLuck.mp3")
    self.voices.goodbye                 = loadSound("sounds/voices/goodBye.mp3")


    self.generalSounds.gameOver         = loadSound("sounds/gameOver.mp3")
    self.generalSounds.mapComplete      = loadSound("sounds/mapComplete.wav")
    self.generalSounds.doorOpen         = loadSound("sounds/doorOpen.wav")
    self.generalSounds.button           = loadSound("sounds/buttonClick.wav")

    self.music.rollingGame              = loadSound("sounds/music-cyborgNinja.mp3")
    self.music.customScene              = loadSound("sounds/music-powerBotsLoop.wav")
end


function Sounds:play(sound, options)
    local options = options or {channel=nil}

    if options.channel == nil then
        options.channel = findChannel()
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


function Sounds:voice(sound, params)
    self:play(self.voices[sound], params)
end


function Sounds:general(sound, params)
    self:play(self.generalSounds[sound], params)
end


return Sounds