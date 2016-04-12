local explore = { step = 80, wait = 10 }

explore.explore_map_players = {}
explore.stop_explore_map = function(name, param)
  if(explore.explore_map_players[name]==nil) then
    return
  end

  local player = minetest.get_player_by_name(name)
  local data = explore.explore_map_players[name]
  explore.explore_map_players[name] = nil
  player:moveto(data.start)
  local dt = math.floor((minetest.get_us_time() - data.startTime) / 1000)
  minetest.chat_send_player(name, "Visited "..(data.count).." locations in "..dt.."ms")
  minetest.debug(name, "Visited "..(data.count).." locations in "..dt.."ms")
end

explore.player_explore_map = function(name, data)
  data.wait = data.wait - 1
  if(data.wait > 0) then
    return
  end

  data.wait = explore.wait
  local player = minetest.get_player_by_name(name)
  local pos = { x=data.cur.x+data.dX, y=data.cur.y, z=data.cur.z+data.dZ }
  data.step = data.step - 1
  data.count = data.count + 1
  if(data.step==0) then
    if(data.change) then
      data.size = data.size + 1
      if((data.maxSize ~= nil) and (data.size >= data.maxSize)) then
        explore.stop_explore_map(name, data)
        return
      end
    end
    data.change = not data.change
    data.step = data.size
    local tmp = data.dX
    data.dX = data.dZ
    data.dZ = -tmp
  end
  data.cur = pos
  minetest.chat_send_player(name, "position: ("..pos.x..","..pos.y..","..pos.z.."), size: "..data.size)
  player:moveto(pos)
end

minetest.register_chatcommand("explore_map", {
  params = "[stop_at_steps]",
  description = "Start exploring the map by teleporting on a spiral of 80 nodes steps starting at current player location.",
  func = function(name, params)
    local found, _, stop_at_steps = params:find("^(%d+)%s*$")
    local maxSize = nil
    if found ~= nil then
      maxSize = tonumber(stop_at_steps)
    end
    local player = minetest.get_player_by_name(name)
    local pos = player:getpos()
    explore.explore_map_players[name] = {
      wait = explore.wait,
      start = pos,
      dX = explore.step,
      dZ = 0,
      size = 1,
      step = 1,
      change = false,
      cur = {x=pos.x, y=pos.y, z=pos.z},
      maxSize = maxSize,
      startTime = minetest.get_us_time(),
      count = 0
    }
  end
})

minetest.register_chatcommand("stop_explore", {
  params = "",
  description = "Stop current exploration and go back to start point.",
  func = explore.stop_explore_map
})

minetest.register_globalstep(function(dtime)
  for name, data in pairs(explore.explore_map_players) do
    explore.player_explore_map(name, data)
  end
end
)

minetest.register_chatcommand("mapgen", {
  params = "radius, max_height",
  description = "Generate map in a square box of size 2*radius up to max_height centered at your current position.",
  func = function(name, params)
    local found, _, s_radius, s_height = params:find("^%s*(%d+)%s*,%s*(-?%d+)%s*$")
    if found == nil then
      minetest.chat_send_player(name, "Usage: /mapgen radius, max_height")
      return
    end
    local radius = tonumber(s_radius)
    local max_height = tonumber(s_height)

    if radius == 0 then radius = 1 end

    local player = minetest.get_player_by_name(name)
    local pos = player:getpos()
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
          minetest.chat_send_player(name, info.."Generated new block at "..block)
        elseif (action==core.EMERGE_CANCELLED) or (action==core.EMERGE_ERRORED) then
          minetest.chat_send_player(name, info.."Block at "..block.." did not emerge")
        else
          --minetest.chat_send_player(name, "(mapgen-"..remaining.."-"..dt.."s) Visited block at "..(blockpos.x)..","..(blockpos.y)..","..(blockpos.z))
        end
      end
    )
  end
})
