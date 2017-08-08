local mte = require("engines.mte")

local TileEngine = {}


function TileEngine:create(view, tiles, levelGenerator)
    mte.loadTileSet("Tiles1", "images/tiles.png")
    --mte.loadMap("json/RunAndGunMap")
    mte.loadMap("tiled/tiled1")
    --mte.loadMap("json/RunAndGunMap")
end


return TileEngine