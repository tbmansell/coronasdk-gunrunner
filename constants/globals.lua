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


Powerups = {
    damage     = "damage",
    extraAmmo  = "extraAmmo",
    fastMove   = "fastMove",
    fastShoot  = "fastShoot",
    health     = "health",
    laserSight = "laserSight",
    shield     = "shield",
}


EnvironmentalWeapon = {
    gasSmall = {damage=5, area=125},
    gasBig   = {damage=5, area=175},
}


Weapons = {
    club              = {name="club",        damage=1, time=500},
    claws             = {name="claw",        damage=1, time=500},
    rifle             = {name="rifle",       damage=1, ammoType="bullet",    speed=650, rof=205,  ammo=30, reload=1000, collect=15},
    shotgun           = {name="shotgun",     damage=1, ammoType="shell",     speed=650, rof=750,  ammo=10, reload=1200, collect=25},
    launcher          = {name="launcher",    damage=5, ammoType="rocket",    speed=550, rof=1200, ammo=6,  reload=1500, collect=50, area=75},
    flamer            = {name="flamer",      damage=1, ammoType="flame",     speed=0,   rof=1000, ammo=5,  reload=1500, collect=50},
    laserGun          = {name="laserGun",    damage=2, ammoType="laser",     speed=600, rof=400,  ammo=15, reload=1500, collect=50, ricochet=2,        customDeath=true},
    chainGun          = {name="chainGun",    damage=1, ammoType="chainShot", speed=700, rof=150,  ammo=50, reload=2000, collect=50, burst=3,           customDeath=true},
    chainGunTurret    = {name="chainGun",    damage=1, ammoType="chainShot", speed=700, rof=150,  ammo=50, reload=2000, collect=50, burst=3,           customDeath=true},
    laserCannon       = {name="laserCannon", damage=4, ammoType="laserBolt", speed=600, rof=900,  ammo=20, reload=2000, collect=50, shootThrough=true, customDeath=true},
    laserCannonTurret = {name="laserCannon", damage=4, ammoType="laserBolt", speed=600, rof=900,  ammo=20, reload=2000, collect=50, shootThrough=true, customDeath=true},
}

-- Load in weapon stats for spine and particles:
Weapons.club.slot              = "weapon";  Weapons.club.skin              = "weapons/weapon-club";
Weapons.rifle.slot             = "weapon";  Weapons.rifle.skin             = "weapons/gun_assault";   Weapons.rifle.bone             = "rifle";         Weapons.rifle.hitAnim             = "bulletImpact"
Weapons.shotgun.slot           = "weapon";  Weapons.shotgun.skin           = "weapons/gun_shotgun";   Weapons.shotgun.bone           = "rifle";         Weapons.shotgun.hitAnim           = "bulletImpact"
Weapons.launcher.slot          = "weapon";  Weapons.launcher.skin          = "weapons/gun_launcher";  Weapons.launcher.bone          = "launcher";      Weapons.launcher.hitAnim          = "smoke";         Weapons.launcher.hitAnim2nd="explosion"
Weapons.flamer.slot            = "weapon";  Weapons.flamer.skin            = "weapons/gun_flamer";    Weapons.flamer.bone            = "flamer";        Weapons.flamer.hitAnim            = "smoke";         --Weapons.flamer.hitAnim2nd="explosion"
Weapons.laserGun.slot          = "weapon";  Weapons.laserGun.skin          = "weapons/gun_laser";     Weapons.laserGun.bone          = "laser";         Weapons.laserGun.hitAnim          = "plasmaImpact";
Weapons.chainGun.slot          = "weapon";  Weapons.chainGun.skin          = "weapons/chainGun";      Weapons.chainGun.bone          = "chainGun";      Weapons.chainGun.hitAnim          = "bulletImpact"
Weapons.laserCannon.slot       = "weapon";  Weapons.laserCannon.skin       = "weapons/laserCannon";   Weapons.laserCannon.bone       = "laserCannon";   Weapons.laserCannon.hitAnim       = "plasmaImpact";
Weapons.chainGunTurret.slot    = "weapon";  Weapons.chainGunTurret.skin    = "turrets/chainGun";      Weapons.chainGunTurret.bone    = "chainGun";      Weapons.chainGunTurret.hitAnim    = "bulletImpact"
Weapons.laserCannonTurret.slot = "weapon";  Weapons.laserCannonTurret.skin = "turrets/laserCannon";   Weapons.laserCannonTurret.bone = "laserCannon";   Weapons.laserCannonTurret.hitAnim = "plasmaImpact";

-- Load in weapon sounds
Weapons.club.hitSound               = "";
Weapons.rifle.shotSound             = "rifleShot";     Weapons.rifle.hitSound             = "bulletHit";
Weapons.shotgun.shotSound           = "shotGunShot";   Weapons.shotgun.hitSound           = "bulletHit";
Weapons.launcher.shotSound          = "rocketShot";    Weapons.launcher.hitSound          = "rocketHit";
Weapons.flamer.shotSound            = "rocketShot";    Weapons.flamer.hitSound            = "rocketHit";
Weapons.laserGun.shotSound          = "laserShot";     Weapons.laserGun.hitSound          = "laserHit";
Weapons.chainGun.shotSound          = "chainGunShot";  Weapons.chainGun.hitSound          = "bulletHit";
Weapons.laserCannon.shotSound       = "laserBolt";     Weapons.laserCannon.hitSound       = "laserHit";
Weapons.chainGunTurret.shotSound    = "chainGunShot";  Weapons.chainGunTurret.hitSound    = "bulletHit";
Weapons.laserCannonTurret.shotSound = "laserBolt";     Weapons.laserCannonTurret.hitSound = "laserHit";


EnemyCategories = {
    melee   = "melee",
    shooter = "shooter",
    heavy   = "heavy",
    turret  = "turret",
    flying  = "flying",
    vehicle = "vehicle",
}


EnemyRanks = {
    normal  = 1,
    captain = 2,
    elite   = 3,
}


EnemyTypes = {
    -- melee
    lizardClub          = 1,
    reptileSmall        = 2,
    -- shooter
    lizardRifle         = 1,
    lizardShotgun       = 2,
    -- heavy
    lizardLauncher      = 1,
    lizardLaserGun      = 2,
    reptileFlamer       = 3,
    -- turrets
    turretChainGun      = 1,
    turretLaserCannon   = 2,
}


Formations = {
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


-- Local Shortcuts
local melee               = EnemyCategories.melee
local shooter             = EnemyCategories.shooter
local heavy               = EnemyCategories.heavy
local turret              = EnemyCategories.turret
local flying              = EnemyCategories.flying
local vehicle             = EnemyCategories.vehicle

local normal              = EnemyRanks.normal
local captain             = EnemyRanks.captain
local elite               = EnemyRanks.elite

local lizardClub          = EnemyTypes.lizardClub
local reptileSmall        = EnemyTypes.reptileSmall
local lizardRifle         = EnemyTypes.lizardRifle
local lizardShotgun       = EnemyTypes.lizardShotgun
local lizardLauncher      = EnemyTypes.lizardLauncher
local lizardLaserGun      = EnemyTypes.lizardLaserGun
local reptileFlamer       = EnemyTypes.reptileFlamer
local turretChainGun      = EnemyTypes.turretChainGun
local turretLaserCannon   = EnemyTypes.turretLaserCannon


-- Rules: 
--  only allocating in units of 25
--  heavys  cant be more than 50% of enemies in section
--  turrets cant be more than 25% of enemies in section
EnemyLayouts = {
    [1] = {[melee]=100,     [shooter]=0,    [heavy]=0,      [turret]=0,     [flying]=0,     [vehicle]=0},
    [2] = {[melee]=0,       [shooter]=100,  [heavy]=0,      [turret]=0,     [flying]=0,     [vehicle]=0},

    [3] = {[melee]=75,      [shooter]=25,   [heavy]=0,      [turret]=0,     [flying]=0,     [vehicle]=0},
    [4] = {[melee]=50,      [shooter]=50,   [heavy]=0,      [turret]=0,     [flying]=0,     [vehicle]=0},
    [5] = {[melee]=25,      [shooter]=75,   [heavy]=0,      [turret]=0,     [flying]=0,     [vehicle]=0},
    
    [6] = {[melee]=75,      [shooter]=0,    [heavy]=25,     [turret]=0,     [flying]=0,     [vehicle]=0},
    [7] = {[melee]=50,      [shooter]=0,    [heavy]=50,     [turret]=0,     [flying]=0,     [vehicle]=0},
    
    [8] = {[melee]=0,       [shooter]=75,   [heavy]=25,     [turret]=0,     [flying]=0,     [vehicle]=0},
    [9] = {[melee]=0,       [shooter]=50,   [heavy]=50,     [turret]=0,     [flying]=0,     [vehicle]=0},
    
    [10] = {[melee]=50,     [shooter]=25,   [heavy]=25,     [turret]=0,     [flying]=0,     [vehicle]=0},
    [11] = {[melee]=25,     [shooter]=50,   [heavy]=25,     [turret]=0,     [flying]=0,     [vehicle]=0},
    [12] = {[melee]=25,     [shooter]=25,   [heavy]=50,     [turret]=0,     [flying]=0,     [vehicle]=0},
    
    [13] = {[melee]=50,     [shooter]=25,   [heavy]=0,      [turret]=25,    [flying]=0,     [vehicle]=0},
    [14] = {[melee]=25,     [shooter]=50,   [heavy]=0,      [turret]=25,    [flying]=0,     [vehicle]=0},
    [15] = {[melee]=50,     [shooter]=0,    [heavy]=25,     [turret]=25,    [flying]=0,     [vehicle]=0},
    [16] = {[melee]=25,     [shooter]=0,    [heavy]=50,     [turret]=25,    [flying]=0,     [vehicle]=0},
    [17] = {[melee]=0,      [shooter]=50,   [heavy]=25,     [turret]=25,    [flying]=0,     [vehicle]=0},
    [18] = {[melee]=0,      [shooter]=25,   [heavy]=50,     [turret]=25,    [flying]=0,     [vehicle]=0},

    [19] = {[melee]=25,     [shooter]=25,   [heavy]=25,     [turret]=25,    [flying]=0,     [vehicle]=0},
    
    --[[
    [1]  = {[100]=melee},
    [2]  = {[100]=shooter},

    [3]  = {[75]=melee,     [25]=shooter},
    [4]  = {[50]=melee,     [50]=shooter},
    [5]  = {[25]=melee,     [75]=shooter},

    [6]  = {[75]=melee,     [25]=heavy},
    [7]  = {[50]=melee,     [50]=heavy},

    [8]  = {[75]=shooter,   [25]=heavy},
    [9]  = {[50]=shooter,   [50]=heavy},

    [10] = {[50]=melee,     [25]=shooter,   [25]=heavy},
    [11] = {[25]=melee,     [50]=shooter,   [25]=heavy},
    [12] = {[25]=melee,     [25]=shooter,   [50]=heavy},

    [13] = {[50]=melee,     [25]=shooter,   [25]=turret},
    [14] = {[25]=melee,     [50]=shooter,   [25]=turret},
    [15] = {[50]=melee,     [25]=heavy,     [25]=turret},
    [16] = {[25]=melee,     [50]=heavy,     [25]=turret},
    [17] = {[50]=shooter,   [25]=heavy,     [25]=turret},
    [18] = {[25]=shooter,   [50]=heavy,     [25]=turret},

    [19] = {[25]=melee,     [25]=shooter,   [25]=heavy,     [25]=turret},
    ]]
}


EnemyLayoutIntro = {
    [1] = 0,  -- first section has no enemies
    [2] = 1,  -- start with all melee                 (melee=100%)
    [3] = 3,  -- introduce a few shooters             (melee=75%, shooters=25%)
    [4] = 4,  -- introduce more shooters              (melee=50%, shooters=50%)
    [5] = 6,  -- introduce some heavies               (melee=75%, heavies=25%)
    [6] = 10, -- mix melee, shooters and heavies      (melee=50%, shooters=25%, heavies=25%)
    [7] = 5,  -- majority shooters                    (melee=25%, shooters=75%)
    [8] = 13, -- introduce turrets                    (melee=50%, shooters=25%, turrets=5%)
    [9] = 17, -- mix turrets with shooters & heavy    (shooter=50%, heavy=25%,  turrets=25%)
    -- 10 is custom map
}


EnemyDefs = {
    melee = {
        [lizardClub] = {
            [normal]  = {skin="lizard_club",             weapon="club",     health=1, decisionDelay=1000, aggression=70, fidgit=50, roaming=1000, speed=150, melee=true},
            [captain] = {skin="lizard_club_captain",     weapon="club",     health=2, decisionDelay=750,  aggression=80, fidgit=50, roaming=1000, speed=150, melee=true},
            [elite]   = {skin="lizard_club_elite",       weapon="club",     health=3, decisionDelay=500,  aggression=90, fidgit=50, roaming=1000, speed=150, melee=true},
        },
        [reptileSmall] = {
            [normal]  = {skin="reptile_runner",          weapon="claws",    health=1, decisionDelay=500,  aggression=50, fidgit=90, roaming=2500, speed=250, melee=true, scale=0.2},
        }
    },
    shooter = {
        [lizardRifle] = {
            [normal]  = {skin="lizard_assault",          weapon="rifle",    health=2, decisionDelay=1000, aggression=30, fidgit=30, roaming=1000, speed=100, inaccuracy=50},
            [captain] = {skin="lizard_assault_captain",  weapon="rifle",    health=4, decisionDelay=750,  aggression=50, fidgit=40, roaming=1000, speed=150, inaccuracy=30},
            [elite]   = {skin="lizard_assault_elite",    weapon="rifle",    health=6, decisionDelay=500,  aggression=70, fidgit=50, roaming=1000, speed=200, inaccuracy=10},
        },
        [lizardShotgun] = {
            [normal]  = {skin="lizard_shotgun",          weapon="shotgun",  health=2, decisionDelay=1000, aggression=50, fidgit=50, roaming=1000, speed=100, inaccuracy=40},
            [captain] = {skin="lizard_shotgun_captain",  weapon="shotgun",  health=4, decisionDelay=750,  aggression=70, fidgit=60, roaming=1000, speed=150, inaccuracy=25},
            [elite]   = {skin="lizard_shotgun_elite",    weapon="shotgun",  health=6, decisionDelay=500,  aggression=90, fidgit=70, roaming=1000, speed=200, inaccuracy=10},
        },
    },
    heavy = {
        [lizardLauncher] = {
            [normal]  = {skin="lizard_launcher",         weapon="launcher", health=3, decisionDelay=1000, aggression=40, fidgit=20, roaming=1000, speed=50,  inaccuracy=50},
            [captain] = {skin="lizard_launcher_captain", weapon="launcher", health=6, decisionDelay=750,  aggression=60, fidgit=30, roaming=1000, speed=100, inaccuracy=30},
            [elite]   = {skin="lizard_launcher_elite",   weapon="launcher", health=8, decisionDelay=500,  aggression=80, fidgit=40, roaming=1000, speed=150, inaccuracy=10},
        },
        [lizardLaserGun] = {
            [normal]  = {skin="lizard_laser",            weapon="laserGun", health=3, decisionDelay=1000, aggression=50, fidgit=40, roaming=1000, speed=150, inaccuracy=40},
            [captain] = {skin="lizard_laser_captain",    weapon="laserGun", health=6, decisionDelay=750,  aggression=70, fidgit=50, roaming=1000, speed=200, inaccuracy=20},
            [elite]   = {skin="lizard_laser_elite",      weapon="laserGun", health=8, decisionDelay=500,  aggression=90, fidgit=60, roaming=1000, speed=250, inaccuracy=10},
        },
        [reptileFlamer] = {
            [normal]  = {skin="reptile_runner_captain",  weapon="claws",    health=5, decisionDelay=500,  aggression=50, fidgit=90, roaming=2000, speed=200, melee=true, scale=0.4, json="reptiles-flamer"},
        }
    },
    turret = {
        [turretChainGun] = {
            [normal]  = {skin="chainGun",                weapon="chainGunTurret",    health=10, inaccuracy=20, decisionDelay=1000, aggression=50},
        },
        [turretLaserCannon] = {
            [normal]  = {skin="laserCannon",             weapon="laserCannonTurret", health=10, inaccuracy=20, decisionDelay=1000, aggression=50},
        },
    },

}


TilePatterns = {
    -- TEST:

    -- DONE:
    "horizBar", "vertBar", "centreSquare", "centreRing", "vertBarSides", "cornerSquare", "cornerTriangle", "horizTriangles", "parallelTriangle", "cornerDiamond"
}

