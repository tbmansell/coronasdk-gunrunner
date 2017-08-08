-- Game states
GameMode = {
    loading = 1,
    started = 2,
    playing = 3,
    paused  = 4,
    over    = 5,
}


PlayerMode = {
    ready       = 0,
    walk        = 1,
    run         = 2,
    jumpStart   = 3,
    jump        = 4,
    fall        = 5,
    land        = 6,
    hit         = 7,
    dead        = 8,
}


EnemyMode = {
    ready  = 0,
    walk   = 1,
    charge = 2,
    dead   = 3,
}


Filters = {
    player        = {categoryBits=1,   maskBits=220},
    playerJumping = {categoryBits=2,   maskBits=0},
    obstacle      = {categoryBits=4,   maskBits=113},
    collectable   = {categoryBits=8,   maskBits=1},
    enemy         = {categoryBits=16,  maskBits=181},
    playerShot    = {categoryBits=32,  maskBits=20},
    enemyShot     = {categoryBits=64,  maskBits=5},
    hole          = {categoryBits=128, maskBits=17}
}


Weapons = {
    club     = {name="club",     slot="weapon", skin="weapons/weapon-club",  damage=1},
    rifle    = {name="rifle",    slot="weapon", skin="weapons/gun_assault",  damage=1,  ammoType="bullet",  shotSound="rifleShot",  hitSound="bulletHit", hitAnim="", speed=800, rof=250,  ammo=10},
    shotgun  = {name="shotgun",  slot="weapon", skin="weapons/gun_shotgun",  damage=5,  ammoType="bullet",  shotSound="rifleShot",  hitSound="bulletHit", hitAnim="", speed=300, rof=1000, ammo=8},
    launcher = {name="launcher", slot="weapon", skin="weapons/gun_launcher", damage=10, ammoType="rocket",  shotSound="rocketShot", hitSound="rocketHit", hitAnim="", speed=250, rof=3000, ammo=4,   shieldBuster=true},
    laserGun = {name="laser",    slot="weapon", skin="weapons/gun_laser",    damage=5,  ammoType="laser",   shotSound="",           hitSound="",          hitAnim="", speed=400, rof=300,  ammo=100},
}


EnemyTypes = {
    melee = {
        -- ranked in order of dangerousness
        [1] = {--[[modifyImage={.1, .3, .1},]] skin="lizard_club",     weapon="club",     health=2, decisionDelay=1000, aggression=30, fidgit=50, roaming=1000, speed=150, melee=true},
    },
    shooter = {
        -- ranked in order of dangerousness
        [1] = {--[[modifyImage={.6, .6,  1},]] skin="lizard_assault",  weapon="rifle",    health=2, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100},
        [2] = {--[[modifyImage={.2, .2,  1},]] skin="lizard_shotgun",  weapon="shotgun",  health=4, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100},
        [3] = {--[[modifyImage={1,  .3, .3},]] skin="lizard_launcher", weapon="launcher", health=8, decisionDelay=1000, aggression=50, fidgit=20, roaming=1000, speed=50},
    },
}

