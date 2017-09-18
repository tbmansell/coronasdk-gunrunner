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
    strike = 3,
    dead   = 4,
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


EnvironmentalWeapon = {
    gasSmall = {damage=5, area=75},
    gasBig   = {damage=5, area=125},
}


Weapons = {
    club     = {name="club",     damage=1, time=500},
    rifle    = {name="rifle",    damage=1, ammoType="bullet", speed=650, rof=250,  ammo=30, reload=1000},
    shotgun  = {name="shotgun",  damage=1, ammoType="bullet", speed=650, rof=750,  ammo=10, reload=1000},
    launcher = {name="launcher", damage=5, ammoType="rocket", speed=550, rof=1500, ammo=4,  reload=1000, shieldBuster=true, area=75},
    laserGun = {name="laserGun", damage=2, ammoType="laser",  speed=600, rof=400,  ammo=20, reload=1000, ricochet=2},
}


-- Load in weapon stats for spine, sound and particles:
Weapons.club.slot     = "weapon"; Weapons.club.skin     = "weapons/weapon-club";  Weapons.club.hitSound = "";
Weapons.rifle.slot    = "weapon"; Weapons.rifle.skin    = "weapons/gun_assault";  Weapons.rifle.bone    = "rifle";    Weapons.rifle.shotSound    = "rifleShot";  Weapons.rifle.hitSound    = "bulletHit"; Weapons.rifle.hitAnim    = "bulletImpact"
Weapons.shotgun.slot  = "weapon"; Weapons.shotgun.skin  = "weapons/gun_shotgun";  Weapons.shotgun.bone  = "rifle";    Weapons.shotgun.shotSound  = "rifleShot";  Weapons.shotgun.hitSound  = "bulletHit"; Weapons.shotgun.hitAnim  = "bulletImpact"
Weapons.launcher.slot = "weapon"; Weapons.launcher.skin = "weapons/gun_launcher"; Weapons.launcher.bone = "launcher"; Weapons.launcher.shotSound = "rocketShot"; Weapons.launcher.hitSound = "rocketHit"; Weapons.launcher.hitAnim = "smoke";       Weapons.launcher.hitAnim2nd="explosion"
Weapons.laserGun.slot = "weapon"; Weapons.laserGun.skin = "weapons/gun_laser";    Weapons.laserGun.bone = "laser";    Weapons.laserGun.shotSound = "laserShot";  Weapons.laserGun.hitSound = "laserHit";  Weapons.laserGun.hitAnim = "plasmaImpact";


EnemyTypes = {
    melee = {
        -- ranked in order of dangerousness
        [1] = {skin="lizard_club",     weapon="club",     health=1, decisionDelay=1000, aggression=30, fidgit=50, roaming=1000, speed=150, melee=true},
    },
    shooter = {
        -- ranked in order of dangerousness
        [1] = {skin="lizard_assault",  weapon="rifle",    health=2,  inaccuracy=50, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100},
        [2] = {skin="lizard_shotgun",  weapon="shotgun",  health=2,  inaccuracy=40, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100},
        [3] = {skin="lizard_launcher", weapon="launcher", health=3,  inaccuracy=30, decisionDelay=1000, aggression=50, fidgit=20, roaming=1000, speed=50},
        [4] = {skin="lizard_laser",    weapon="laserGun", health=3,  inaccuracy=30, decisionDelay=1000, aggression=50, fidgit=20, roaming=1000, speed=200},
    },
}
