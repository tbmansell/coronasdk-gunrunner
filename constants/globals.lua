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


Filters = {
    player        = {categoryBits=1,  maskBits=1},
    playerJumping = {categoryBits=2,  maskBits=1},
    layerShielded = {categoryBits=4,  maskBits=1},
    obstacle      = {categoryBits=8,  maskBits=1},
    enemy         = {categoryBits=16, maskBits=1},
    playerShot    = {categoryBits=32, maskBits=1},
    enemyShot     = {categoryBits=66, maskBits=1},
}


Weapons = {
    rifle           = {name="rifle",            ammoType="bullet", damage=1,   speed=200,  rof=250,    ammo=25},
    machineGun      = {name="machinegun",       ammoType="bullet", damage=1,   speed=300,  rof=100,    ammo=50},
    missileLauncher = {name="missileLauncher",  ammoType="rocket", damage=10,  speed=250,  rof=1000,   ammo=6},
    laserGun        = {name="laser",            ammoType="laser",  damage=5,   speed=400,  rof=300,    ammo=100},
}

