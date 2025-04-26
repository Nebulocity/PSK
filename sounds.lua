-- Play a random Peon voice line
function PlayRandomPeonSound()
    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg", -- "Work work."
        "Sound\\Creature\\Peon\\PeonYes2.ogg", -- "Zug zug."
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg" -- "Me not that kind of orc!"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true -- Rare triggered!
    else
        local randomIndex = math.random(1, #normalSounds)
        PlaySoundFile(normalSounds[randomIndex])
        return false
    end
end
