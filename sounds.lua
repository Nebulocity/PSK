-- Play random Peon sounds for refresh fun
function PlayRandomPeonSound()
    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg",
        "Sound\\Creature\\Peon\\PeonYes2.ogg",
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg" -- "Me not that kind of orc!"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true
    else
        PlaySoundFile(normalSounds[math.random(1, #normalSounds)])
        return false
    end
end
