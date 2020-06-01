minetest.register_chatcommand("mapgen", {
  params = "radius [max_height]",
  description = "Generate map in a square box of size 2*radius centered at your current position.",
  func = function(name, params)
    local found, _, s_radius, s_height = params:find("^%s*(%d+)%s*(-?%d*)%s*$")
    if found == nil then
      minetest.chat_send_player(name, "Usage: /mapgen radius max_height")
      return
    end

    local player = minetest.get_player_by_name(name)
    local pos = player:getpos()

    local radius = tonumber(s_radius)
    local max_height = tonumber(s_height)

    if max_height == nil then
      max_height = pos.y+1
    end

    if radius == 0 then radius = 1 end

    local start_pos = {
      x = pos.x - radius,
      y = pos.y,
      z = pos.z - radius
    }
    local end_pos = {
      x = pos.x + radius,
      y = max_height,
      z = pos.z + radius
    }
    local start_time = minetest.get_us_time()

    minetest.emerge_area(start_pos, end_pos, function(blockpos, action, remaining)
        local dt = math.floor((minetest.get_us_time() - start_time) / 1000)
        local block = (blockpos.x * 16)..","..(blockpos.y * 16)..","..(blockpos.z * 16)
        local info = "(mapgen-"..remaining.."-"..dt.."ms) "
        if action==core.EMERGE_GENERATED then
          minetest.log("action", info.."Generated new block at "..block)
          minetest.chat_send_player(name, info.."Generated new block at "..block)
        elseif (action==core.EMERGE_CANCELLED) or (action==core.EMERGE_ERRORED) then
          minetest.log("action", info.."Block at "..block.." did not emerge")
          minetest.chat_send_player(name, info.."Block at "..block.." did not emerge")
        else
          --minetest.chat_send_player(name, "(mapgen-"..remaining.."-"..dt.."s) Visited block at "..(blockpos.x)..","..(blockpos.y)..","..(blockpos.z))
        end
        if remaining<=0 then
          minetest.log("action", "(mapgen-"..dt.."ms) Generation done.")
          minetest.chat_send_player(name, "(mapgen-"..dt.."ms) Generation done.")
        end
      end
    )
  end
})
