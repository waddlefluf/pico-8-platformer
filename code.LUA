
---------- PAGE 0 ----------

-- main --

function _init()
	plyr = {
		sp = 1,
		x = 59,
		y = 59,
		w = 8,
		h = 8,
		flp = false, -- plyr flipped?
		dx = 0,
		dy = 9,
		max_dx = 2,  -- max x speed
		max_dy = 3,  -- max y speed
		accel = 0.5,
		boost = 4,
		anim = 0,
		extra_speed = 1,
		running = false,
		jump = false,
		fall = false,
		slide = false,
		grounded = false
		
	}
	
	checkpoint = {
		sp = 129,
		x = 0,
		y = 0
		}
		
		gravity = 0.3
		friction = 0.85

	-- camera
	cam_x = 0
	cam_y = 0
	
	-- map ends
	map_start = 0
	map_end = 1024
	
	
end
----------------------------

---------- PAGE 1 ---------- 

-- functions

-- wait
function wait(_wait)
	repeat
	_wait-=1
	flip()
	until _wait<0
end

	-- collision w/ map
function collide_map(obj,aim,flag)
	
	local x = obj.x		local y = obj.y
	local w = obj.w  local h = obj.h
	
	local x1 = 0  local y1 = 0
	local x2 = 0  local y2 = 0
	
	if (aim == "left") then
	 x1 = x - 1  y1 = y
	 x2 = x      y2 = y + (h - 1)
	 
	elseif (aim == "right") then
		x1 = x + w	- 1	 y1 = y
		x2 = x + w  	  	y2 = y + (h - 1)
			
	elseif (aim == "up") then
		x1 = x + 2       y1 = y - 1
		x2 = x + (w - 3) y2 = y
		
	elseif (aim == "down") then
		x1 = x + 2    y1 = y + h
		x2 = x + w-3  y2 = y + h
		
	end

	x1 /= 8  y1 /= 8
	x2 /= 8  y2 /= 8
	
	if (fget(mget(x1,y1), flag))
	or (fget(mget(x1,y2), flag))
	or (fget(mget(x2,y1), flag))
	or (fget(mget(x2,y2), flag)) then
		return true
	else
		return false
	end
	
end

-- player update/movement
function plyr_update()
	
	-- hazards
	if collide_map(plyr,"down",2) then
		sfx(1)
		plyr.x = checkpoint.x
		plyr.y = checkpoint.y
	end
	
	-- checkpoint
	if collide_map(plyr,"right",3) then
		sfx(1)
		checkpoint.x = plyr.x
		checkpoint.y = plyr.y	
	end

 -- gravity / friction
	plyr.dy += gravity
	plyr.dx *= friction
	
	-- input
	
	-- walk
	if btn(0) then
		plyr.dx -= plyr.accel
		plyr.running = true
		plyr.flp = true
	end		
	if btn(1) then
		plyr.dx += plyr.accel
		plyr.running = true
		plyr.flp = false
	end
	-- run (fast)
	if btn(5) then
		plyr.extra_speed = 1.5
	end
	if not btn(5) then
		plyr.extra_speed = 1
	end
	
	-- smooth stop
	if plyr.running
	and not btn(0)
	and not btn(1)
	and not btn(5)
	and not plyr.fall
	and not plyr.jump then
		plyr.running = false
		plyr.slide = true
	end
	
	-- jump
	if btnp(4)
	and plyr.grounded then
		plyr.dy -= plyr.boost
		plyr.grounded = false
		sfx(0)
	end
	
	-- y collision
	if (plyr.dy > 0) then
		plyr.fall = true
		plyr.grounded = false
		plyr.jump = false
		plyr.dy = speed_limit(plyr.dy,plyr.max_dy)
		
		if (collide_map(plyr, "down", 0)) then
			plyr.grounded = true
			plyr.fall = false
			plyr.dy = 0
			plyr.y -= ((plyr.y + plyr.h+1)%8) - 1
		end
	elseif (plyr.dy < 0) then
		plyr.jump = true
		if collide_map(plyr, "up", 1) then
			plyr.dy = 0
		end
	end

	-- x collision
	if (plyr.dx < 0) then
	
		plyr.dx = speed_limit(plyr.dx, plyr.max_dx)
	
		if (collide_map(plyr, "left", 1)) then
			plyr.dx = 0
		end
	elseif (plyr.dx > 0) then
	
		plyr.dx = speed_limit(plyr.dx, plyr.max_dx)
	 	
		if (collide_map(plyr, "right", 1)) then
		 plyr.dx=0
		end
	end	
	
	-- stop
	if (plyr.slide) then
		if abs(plyr.dx) < .2
		or plyr.run then
			plyr.dx = 0
		 plyr.slide = false
		end
	end
	
	plyr.x += plyr.dx * plyr.extra_speed
	plyr.y += plyr.dy 
	

	-- prevent player from exit map
	if (plyr.x < map_start) then
		plyr.x = map_start
	end
	if (plyr.x > map_end - plyr.w) then
		plyr.x = map_end - plyr.w
	end
 
end

function plyr_animate()
	if plyr.jump then
		plyr.sp = 7
	elseif plyr.fall then
		plyr.sp = 8
	elseif plyr.slide then
		plyr.sp = 9
	elseif plyr.running then
		if time() - plyr.anim > .1 then
			plyr.anim = time()
			plyr.sp += 1
			if plyr.sp > 6 then
				plyr.sp = 3
			end
		end
	else -- idle
	 if time() - plyr.anim > .3 then
	 	plyr.anim = time()
	 	plyr.sp += 1
	 	if plyr.sp > 2 then
	 		plyr.sp = 1
	 	end
	 end
	end
end

function speed_limit(num,maxi)
	return mid(-maxi,num,maxi)
end

--
-- camera

function cam()
	cam_x = plyr.x - 64 + (plyr.w/2)
	if cam_x < map_start then
		cam_x = map_start
	end
	if cam_x > map_end - 128 then
		cam_x = map_end - 128
	end
	
	cam_y = plyr.y - 64 + (plyr.h/2)
	
	if cam_y < map_start then
		cam_y = map_start
	end
	if cam_y > map_end - 128 then
		cam_y = map_end - 128
	end
	camera(cam_x,cam_y)
	
end

-- testing
function gets()
	ok = mget(0,8)
	print(ok,0,20)
	
--	if (x <= ok+1 or x >= ok+1) then
		--print("dead",plyr.x,plyr.y-30)
	--else
	--	print(ok,plyr.x,plyr.y-30)
	--end
end

----------------------------

---------- PAGE 2 ----------

-- update/draw

function _update()
	plyr_update()
 plyr_animate()
 cam()
end

function _draw()
	cls()
	map(0,0)
	spr(plyr.sp,plyr.x,plyr.y,1,1,plyr.flp,false)
	print("flipped:")
	print(plyr.flp)
	print(plyr.y,plyr.x,plyr.y - 10,7)
	print(plyr.x,plyr.x,plyr.y - 16,7)
	gets()	
	
end	
