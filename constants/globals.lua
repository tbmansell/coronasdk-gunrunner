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
    player        = {categoryBits=1,  maskBits=92},
    playerJumping = {categoryBits=2,  maskBits=0},
    obstacle      = {categoryBits=4,  maskBits=113},
    collectable   = {categoryBits=8,  maskBits=1},
    enemy         = {categoryBits=16, maskBits=53},
    playerShot    = {categoryBits=32, maskBits=20},
    enemyShot     = {categoryBits=64, maskBits=5},
}


Weapons = {
    melee    = {name="melee",    damage=1, shieldBuster=false},
    rifle    = {name="rifle",    ammoType="bullet",  shotSound="rifleShot",  hitSound="bulletHit", hitAnim="", damage=1,  speed=200, rof=250,  ammo=10,  shieldBuster=false},
    smg      = {name="sgm",      ammoType="bullet",  shotSound="rifleShot",  hitSound="bulletHit", hitAnim="", damage=1,  speed=300, rof=100,  ammo=50,  shieldBuster=false},
    launcher = {name="launcher", ammoType="rocket",  shotSound="rocketShot", hitSound="rocketHit", hitAnim="", damage=10, speed=250, rof=3000, ammo=4,   shieldBuster=true},
    laserGun = {name="laser",    ammoType="laser",   shotSound="",           hitSound="",          hitAnim="", damage=5,  speed=400, rof=300,  ammo=100, shieldBuster=false},
}


EnemyTypes = {
    melee = {
        -- ranked in order of dangerousness
        [1] = {modifyImage={.1, .3, .1}, melee=true, health=2, decisionDelay=1000, aggression=30, fidgit=50, roaming=1000, speed=150},
    },
    shooter = {
        -- ranked in order of dangerousness
        [1] = {modifyImage={.6, .6,  1}, weapon="rifle",    health=2, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100},
        [2] = {modifyImage={.2, .2,  1}, weapon="smg",      health=4, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100},
        [3] = {modifyImage={1,  .3, .3}, weapon="launcher", health=8, decisionDelay=1000, aggression=50, fidgit=20, roaming=1000, speed=50},
    },
}

