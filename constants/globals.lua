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
    club     = {name="club",     slot="weapon", skin="weapons/weapon-club",  damage=1,  hitSound=""},
    rifle    = {name="rifle",    slot="weapon", skin="weapons/gun_assault",  damage=1,  ammoType="bullet", speed=700, rof=250,  ammo=30,  bone="rifle",    shotSound="rifleShot",  hitSound="bulletHit", hitAnim="bulletImpact"},
    shotgun  = {name="shotgun",  slot="weapon", skin="weapons/gun_shotgun",  damage=1,  ammoType="bullet", speed=700, rof=750,  ammo=10,  bone="rifle",    shotSound="rifleShot",  hitSound="bulletHit", hitAnim="bulletImpact"},
    launcher = {name="launcher", slot="weapon", skin="weapons/gun_launcher", damage=10, ammoType="rocket", speed=250, rof=3000, ammo=4,   bone="launcher", shotSound="rocketShot", hitSound="rocketHit", hitAnim="smoke", hitAnim2nd="explosion", shieldBuster=true},
    laserGun = {name="laser",    slot="weapon", skin="weapons/gun_laser",    damage=5,  ammoType="laser",  speed=400, rof=300,  ammo=100, bone="laser",    shotSound="",           hitSound="",          hitAnim=nil},
}


EnemyTypes = {
    melee = {
        -- ranked in order of dangerousness
        [1] = {skin="lizard_club",     weapon="club",     health=2, decisionDelay=1000, aggression=30, fidgit=50, roaming=1000, speed=150, melee=true},
    },
    shooter = {
        -- ranked in order of dangerousness
        [1] = {skin="lizard_assault",  weapon="rifle",    health=2, inaccuracy=50, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100},
        [2] = {skin="lizard_shotgun",  weapon="shotgun",  health=4, inaccuracy=40, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100},
        [3] = {skin="lizard_launcher", weapon="launcher", health=8, inaccuracy=30, decisionDelay=1000, aggression=50, fidgit=20, roaming=1000, speed=50},
    },
}

