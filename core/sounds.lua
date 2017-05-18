local Sounds = {}

-- Aliases
local loadSound   = audio.loadSound
local unloadSound = audio.dispose
local findChannel = audio.findFreeChannel
local setVolume   = audio.setVolume
local play        = audio.play


function Sounds:loadStaticSounds()
    self.rifleShot = loadSound("sounds/rifle-shot.mp3")
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


return Sounds