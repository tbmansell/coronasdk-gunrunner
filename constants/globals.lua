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
    ready = 0,
    walk  = 1,
    hit   = 2,
    dead  = 3,
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
    rifle       = {name="rifle",      ammoType="bullet",  shotSound="rifleShot", hitSound="bulletHit", hitAnim="", damage=1,  speed=200, rof=250,  ammo=25,  shieldBuster=false},
    machineGun  = {name="machinegun", ammoType="bullet",  shotSound="rifleShot", hitSound="bulletHit", hitAnim="", damage=1,  speed=300, rof=100,  ammo=50,  shieldBuster=false},
    launcher    = {name="launcher",   ammoType="rocket",  shotSound="",          hitSound="",          hitAnim="", damage=10, speed=250, rof=1000, ammo=6,   shieldBuster=true},
    laserGun    = {name="laser",      ammoType="laser",   shotSound="",          hitSound="",          hitAnim="", damage=5,  speed=400, rof=300,  ammo=100, shieldBuster=false},
}

