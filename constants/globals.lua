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
    resetAim    = 9,
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
    club              = {name="club",              damage=1, time=500},
    claws             = {name="claw",              damage=1, time=500},
    rifle             = {name="rifle",             damage=1, ammoType="bullet",    speed=650, rof=205,  ammo=30, reload=1000, collect=15},
    shotgun           = {name="shotgun",           damage=1, ammoType="shell",     speed=650, rof=750,  ammo=10, reload=1200, collect=25},
    launcher          = {name="launcher",          damage=5, ammoType="rocket",    speed=550, rof=1200, ammo=4,  reload=1500, collect=50, area=75},
    laserGun          = {name="laserGun",          damage=2, ammoType="laser",     speed=600, rof=400,  ammo=15, reload=1300, collect=50, ricochet=2},
    chainGun          = {name="chainGun",          damage=1, ammoType="bullet",    speed=700, rof=150,  ammo=50, reload=2000, collect=50, burst=3},
    chainGunTurret    = {name="chainGun",          damage=1, ammoType="bullet",    speed=700, rof=150,  ammo=50, reload=2000, collect=50, burst=3},
    laserCannon       = {name="laserCannon",       damage=4, ammoType="laserBolt", speed=600, rof=1200, ammo=20, reload=2000, collect=50, shootThrough=true},
    laserCannonTurret = {name="laserCannonTurret", damage=4, ammoType="laserBolt", speed=600, rof=1200, ammo=20, reload=2000, collect=50, shootThrough=true},
}

-- Load in weapon stats for spine, sound and particles:
Weapons.club.slot        = "weapon"; Weapons.club.skin        = "weapons/weapon-club";  Weapons.club.hitSound    = "";
Weapons.rifle.slot       = "weapon"; Weapons.rifle.skin       = "weapons/gun_assault";  Weapons.rifle.bone       = "rifle";       Weapons.rifle.shotSound       = "rifleShot";    Weapons.rifle.hitSound    = "bulletHit"; Weapons.rifle.hitAnim    = "bulletImpact"
Weapons.shotgun.slot     = "weapon"; Weapons.shotgun.skin     = "weapons/gun_shotgun";  Weapons.shotgun.bone     = "rifle";       Weapons.shotgun.shotSound     = "shotGunShot";  Weapons.shotgun.hitSound  = "bulletHit"; Weapons.shotgun.hitAnim  = "bulletImpact"
Weapons.launcher.slot    = "weapon"; Weapons.launcher.skin    = "weapons/gun_launcher"; Weapons.launcher.bone    = "launcher";    Weapons.launcher.shotSound    = "rocketShot";   Weapons.launcher.hitSound = "rocketHit"; Weapons.launcher.hitAnim = "smoke";       Weapons.launcher.hitAnim2nd="explosion"
Weapons.laserGun.slot    = "weapon"; Weapons.laserGun.skin    = "weapons/gun_laser";    Weapons.laserGun.bone    = "laser";       Weapons.laserGun.shotSound    = "laserShot";    Weapons.laserGun.hitSound = "laserHit";  Weapons.laserGun.hitAnim = "plasmaImpact";
Weapons.chainGun.slot    = "weapon"; Weapons.chainGun.skin    = "weapons/chainGun";     Weapons.chainGun.bone    = "chainGun";    Weapons.chainGun.shotSound    = "chainGunShot"; Weapons.chainGun.hitSound    = "bulletHit"; Weapons.chainGun.hitAnim    = "bulletImpact"
Weapons.laserCannon.slot = "weapon"; Weapons.laserCannon.skin = "weapons/laserCannon";  Weapons.laserCannon.bone = "laserCannon"; Weapons.laserCannon.shotSound = "laserShot";    Weapons.laserCannon.hitSound = "laserHit";  Weapons.laserCannon.hitAnim = "plasmaImpact";

Weapons.chainGunTurret.slot    = "weapon"; Weapons.chainGunTurret.skin    = "turrets/chainGun";     Weapons.chainGunTurret.bone    = "chainGun";    Weapons.chainGunTurret.shotSound    = "chainGunShot"; Weapons.chainGunTurret.hitSound    = "bulletHit"; Weapons.chainGunTurret.hitAnim    = "bulletImpact"
Weapons.laserCannonTurret.slot = "weapon"; Weapons.laserCannonTurret.skin = "turrets/laserCannon";  Weapons.laserCannonTurret.bone = "laserCannon"; Weapons.laserCannonTurret.shotSound = "laserShot";    Weapons.laserCannonTurret.hitSound = "laserHit";  Weapons.laserCannonTurret.hitAnim = "plasmaImpact";


Powerups = {
    health     = "health",
    shield     = "shield",
    damage     = "damage",
    fastMove   = "fastMove",
    fastShoot  = "fastShoot",
    extraAmmo  = "extraAmmo",
    laserSight = "laserSight",
}


EnemyTypes = {
    melee = {
        -- lizard men
        [1] = {skin="lizard_club",              weapon="club",     health=1, decisionDelay=1000, aggression=70, fidgit=50, roaming=1000, speed=150, melee=true},
        [2] = {skin="lizard_club_captain",      weapon="club",     health=2, decisionDelay=750,  aggression=80, fidgit=50, roaming=1000, speed=150, melee=true},
        [3] = {skin="lizard_club_elite",        weapon="club",     health=3, decisionDelay=500,  aggression=90, fidgit=50, roaming=1000, speed=150, melee=true},
    },
    reptile = {
        [1] = {skin="reptile_runner",           weapon="claws",    health=1, decisionDelay=500, aggression=50, fidgit=90, roaming=2500, speed=250, melee=true, scale=0.2},
        [2] = {skin="reptile_runner_captain",   weapon="claws",    health=5, decisionDelay=500, aggression=50, fidgit=90, roaming=2000, speed=200, melee=true, scale=0.4, json="reptiles-captain"},
    },
    shooter = {
        -- Infantry of each weapon
        [1]  = {skin="lizard_assault",          weapon="rifle",    health=2, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100, inaccuracy=50},
        [2]  = {skin="lizard_shotgun",          weapon="shotgun",  health=2, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100, inaccuracy=40},
        [3]  = {skin="lizard_launcher",         weapon="launcher", health=3, decisionDelay=1000, aggression=40, fidgit=20, roaming=1000, speed=50,  inaccuracy=50},
        [4]  = {skin="lizard_laser",            weapon="laserGun", health=3, decisionDelay=1000, aggression=50, fidgit=40, roaming=1000, speed=150, inaccuracy=40},
        -- Captains of each weapon
        [5]  = {skin="lizard_assault_captain",  weapon="rifle",    health=4, decisionDelay=750, aggression=50, fidgit=40, roaming=1000, speed=150,  inaccuracy=30},
        [6]  = {skin="lizard_shotgun_captain",  weapon="shotgun",  health=4, decisionDelay=750, aggression=70, fidgit=60, roaming=1000, speed=150,  inaccuracy=25},
        [7]  = {skin="lizard_launcher_captain", weapon="launcher", health=6, decisionDelay=750, aggression=60, fidgit=30, roaming=1000, speed=100,  inaccuracy=30},
        [8]  = {skin="lizard_laser_captain",    weapon="laserGun", health=6, decisionDelay=750, aggression=70, fidgit=50, roaming=1000, speed=200,  inaccuracy=20},
        -- Elites of each weapon
        [9]  = {skin="lizard_assault_elite",    weapon="rifle",    health=6, decisionDelay=500, aggression=70, fidgit=50, roaming=1000, speed=200,  inaccuracy=10},
        [10] = {skin="lizard_shotgun_elite",    weapon="shotgun",  health=6, decisionDelay=500, aggression=90, fidgit=70, roaming=1000, speed=200,  inaccuracy=10},
        [11] = {skin="lizard_launcher_elite",   weapon="launcher", health=8, decisionDelay=500, aggression=80, fidgit=40, roaming=1000, speed=150,  inaccuracy=10},
        [12] = {skin="lizard_laser_elite",      weapon="laserGun", health=8, decisionDelay=500, aggression=90, fidgit=60, roaming=1000, speed=250,  inaccuracy=10},
    },
    turret = {
        [1] = {skin="chainGun",                 weapon="chainGunTurret",    health=10, inaccuracy=20, decisionDelay=1000, aggression=50},
        [2] = {skin="laserCannon",              weapon="laserCannonTurret", health=10, inaccuracy=20, decisionDelay=1000, aggression=50},
    }
}


EnemyWeaponAllocations = {
    meleeOnly       = 1,
    riflesOnly      = 2,
    meleeAndRifles  = 3,
    heavyOnly       = 4,
    meleeAndHeavy   = 5,
    heavyAndRifles  = 6,
    all             = 7,
}


EnemyRankAllocations = {
    infantry            = 1,
    captain             = 2,
    infantryWithCaptain = 3,
    elite               = 4,
    infantryWithElite   = 5,
    captainWithElite    = 6,
    all                 = 7,
}


EntityFormations = {
    clusterFuck = 1,  -- spread everywhere, no connection
    mob         = 2,  -- in one mass group, close together
    chain       = 3,  -- in one group, spread out
    wall        = 4,  -- sequential vertically or horiz
    triangle    = 5,  
    square      = 6,  
    jagged      = 7,  -- in a jagged line horiz (1 up, 1 down, 1 up, etc)
    circle      = 8,
    cross       = 9,
}

--[[
EnemyFormationMinimums = {
    EntityFormations.clusterFuck = 1,
    EntityFormations.mob         = 2,
    EntityFormations.squad       = 2,
    EntityFormations.wall        = 2,
    EntityFormations.triangle    = 3,  
    EntityFormations.square      = 4, 
    EntityFormations.jagged      = 4,
    EntityFormations.circle      = 6,
    EntityFormations.cross       = 6,
}]]
