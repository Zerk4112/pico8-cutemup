pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- game info and credits

-->8
-- game loop

function _init()
	gravity_x,gravity_y=0,0.1
	debug = false
	mchunks = {}
	printh('~~~~~~~~PROG INIT~~~~~~')
	menuitem(1,"toggle debug", function() debug = not debug end)
	menuitem(2,"toggle player 2", function() local p2=players[2] p2.pos.x = players[1].pos.x p2.pos.y = players[1].pos.y p2.act=not p2.act end)
	init_scenes()
	max_ents=2
	aroutines={}
	drigs = {}
	routines={}
	entities={}
	particles={}
	cament = create_ent({}, -1, {x=0,y=0,w=4,h=4}, _mot, _coll_box)
	del(drigs, cament.draw_rig)
	del(entities, cament)
	init_players()
	for p in all(players) do clean_ent(p) end
	ents=2
	add(routines, test)
	switch_scene(scenes.stage1, true)
end

function _update60()
	if (current_scene~=nil and current_scene.update~=nil and not scene_switch) current_scene:update()
	manage_routines()
end

function _draw()
    cls()
	if (current_scene~=nil and current_scene.draw~=nil) current_scene:draw()
	local o = {}
	manage_routines(particles)

	if not cament.moving then
		local ordered={}
		for obj in all(entities) do
			local i = flr(obj.pos.y+obj.pos.h)
			ordered[i] = ordered[i] or {} -- ensure table is there
			add(ordered[i],obj.draw_rig)
		end
		for i=cament.pos.y,cament.pos.y+127 do -- or whatever your min/max Y is
			for k,r in pairs(ordered[i]) do
				add(o,r)
			end
		end	
		manage_routines(o)
	else
		manage_routines(drigs)
	end
	-- manage_routines(drigs)
	manage_routines(aroutines)
	for e in all(entities) do
		if (e.act and debug) draw_coll_box(e.coll_box)
	end
	if (_cls) cls(1)
	if debug then
		print('debug', cament.pos.x,cament.pos.y,14)
		print(players[1].stats.lives)
		print(players[1].playing)
		print(players[1].invinframes)
		-- print('p.dodging: '..tostr(players[1].dodging))
		-- print('entities: '..#entities)
		print('aroutines: '..#aroutines)
		print('routines: '..#routines)
		-- print('drigs: '..#drigs)
		-- print(players[1].sprhflip)
	end
	
end

-->8
-- player functions

function init_players()
	if (players~=nil) for p in all(players) do clean_ent(p) end
	players={}

	pstand = {31}
	psstand = {62}
	pfstand = {46}
	pfsstand = {30}

	prun = {18,19,20,21}
	psrun = {58,59,60,61}
	pfrun = {42,43,44,45}
	pfsrun = {26,27,28,29}
	
	pdodge={4,5,6,7,8,9,10,11}
	ptd = {2,3}
	pdying = {4,12,13,14}
	pdead = {15}
	for i=0,1 do
		local p = create_ent(prun, i)
		p.stats.hp=3
		p.chx,p.chy=0,0
		if (i==1)add(p.pal, {9,12})
		p.logic = create_timer(function()
			
			if p.mot.dx<-0.1 or p.mot.dy < -0.1 or p.mot.dx > 0.1 or p.mot.dy > 0.1 then
				p.moving=true
				if p.shooting then
					if p.sprhflip then
						p.sprtab = pfsrun
					else
						p.sprtab = psrun
					end
				else
					if p.sprhflip then
						p.sprtab = pfrun
					else

						p.sprtab = prun
					end
				end
			else
				p.moving=false
				if p.shooting then
					if p.sprhflip then
						p.sprtab = pfsstand
					else
						p.sprtab = psstand
					end
				else
					if p.sprhflip then
						p.sprtab = pfstand
					else
						p.sprtab = pstand
					end
				end
			end
			if (p.dodging)p.sprtab=pdodge
			if (p.td) p.sprtab=ptd
			if (p.dying)  p.sprtab=pdying
			if (p.dead) p.sprtab=pdead
		end,1,true)
		p.draw = create_timer(function()
			if btn(5,p.pid) then
				circ(p.chx,p.chy,1,10)
				circ(p.chx,p.chy,4,8)
			end
		end,1,true)
		add(aroutines, p.draw)
		add(routines, p.logic)
		add(players, p)
		init_scoreboard(p)
	end
end

function create_bullet(_x,_y,_s,_a,_e)
	local collided = {}
	local dx,dy = getposfromang(_a,_s)
	local b = create_ent({}, -2, {x=_x,y=_y,w=1,h=1}, {
		dx=dx, --dx
		dy=dy, --dy,
		a=1,
		mspd=_s,
		drg=1,
		ang=_a
	})
	b.behavior = create_timer(function()
		local entshot = false
		move_entity(b)
		local bx,by = b.pos.x,b.pos.y
		local a = aget(_x,_y,bx,by)
		local ddx,ddy = getposfromang(a,-_s*2)
		circfill(bx,by,1,1)

		line(bx,by,bx+ddx,by+ddy,6)
		pset(bx,by,10)
		for e in all(entities) do
			if check_pos_collision(bx,by, e.coll_box) then 
				if e.pid>1 and e.act then
					if e.stats.hp>0 and not vintab(e, collided) then
						e.stats.hp-=1
						sfx(4)
						add(collided, e)
						ai__steer(e,0)
						if (#collided>_e.stats.pierce) clean_ent(b)
						for k = 1,8 do
							create_particle(e.pos.x+e.pos.w/2,e.pos.y+e.pos.h/2,randbi(0,1),a+rnd(0.125)-rnd(0.125),randbi(20,35),randbi(120,360),randbi(4,24),{8}, update_gravity_particle)
						end
					elseif not vintab(e, collided) then
						clean_ent(e)
						for k = 1,64 do
							create_particle(e.pos.x+e.pos.w/2,e.pos.y+e.pos.h/2,randbi(0,1),rnd(1)-rnd(0.5),20,randbi(60,360),randbi(2,24),{8}, update_gravity_particle)
						end
						e.act=false
						clean_ent(b)
						sfx(1)
					end
				end
			end
		end
		if flr(b.mot.dx)~=flr(dx) or flr(b.mot.dy)~=flr(dy) or off_cam(bx, by) then
			clean_ent(b)
		end
	end,1,true)
	add(aroutines,b.behavior)
	del(drigs,b.draw_rig)
	b.draw_rig=nil
	return b
end

function player_dodge(p)
	local dx,dy = p.mot.dx,p.mot.dy
	local mspd = p.mot.mspd
	if (not p.dodging) p.dodging=true
	
	local r = create_timer(function()
		p.animdelay = 3
		p.mot.mspd = mspd*2
		for f=1,32 do
			if (p.td) break 
			p.mot.dx = dx*10
			if (f==4) player_damframes(p, 5, false)
			p.mot.dy = dy*10
			yield()
		end
		p.animdelay = 5
		p.mot.mspd = mspd
		p.mot.dx=0
		p.mot.dy=0
		p.dodging=false
		p.shooting=false
	end,1) 
	add(aroutines, r)
end

function player_death(p)
	if not p.dead then
		p.dying=true
		del(routines, p.invinframes)
		p.invinframes=nil
		p.tdr = create_timer(function()
			sfx(3)
			for t=0,20 do
				p.animdelay=9
				p.mot.dx=0
				p.mot.dy=0
				yield()

			end
			p.dying=false
			p.dead=true
			for t=0,60 do
				yield()
			end
			p.act=false
			p.dead=false
			p.animdelay=5
		end,1) 
		add(routines, p.tdr)
	end
end

function player_damframes(p, _f, _b)
	local f = _f or 10
	local blink = _b
	if (blink==nil) blink = true
	if p.invinframes==nil then
		p.invinframes = create_timer(function()
			for i=1,f do
				if (blink) p.blink = not p.blink 
				yields(5)
			end
			p.blink=false
			del(routines,p.invinframes)
			p.invinframes = nil
			
		end,1) 
		add(routines,p.invinframes)
	end
end

function player_takedam(p,e)
	if not p.td and p.invinframes==nil then
		p.td=true
		
		local a = oaget(e,p)
		local dx,dy = getposfromang(a, 2)
		if (p.stats.hp>0)p.stats.hp-=1
		p.tdr = create_timer(function()
			sfx(2)
			p.animdelay=2
			for t=0,24 do
				p.mot.dx=dx
				p.mot.dy=dy
				yield()
			end
			for t=0,16 do
				yield()
			end
			p.animdelay=5
			player_damframes(p)
			p.td=false
			p.shooting=false
			p.dodging=false
			if (p.stats.hp==0) player_death(p)
			
		end,1) 
		add(routines, p.tdr)
	end
	
end

function player_shoot(p)
	local r = create_timer(function()
		local i=0
		local x,y=0,0
		while not p.dodging and not p.td do
			x,y=p.pos.x+3.5,p.pos.y+3.5
			local ox = 0
			if (i==0) sfx(0) create_bullet(x, y,3,aget(x, y,p.chx,p.chy)+rnd(0.015)-rnd(0.015),p)
			i+=1
			if (btn(5,p.pid) and i==p.shtdelay) i=0
			if (i==p.shtdelay) break
			yield()
		end
		p.srtn=nil
		p.shooting=false
	end,1) 
	p.srtn=r
	add(routines, r)

end

function check_respawn(p)
	if p.playing and p.stats.lives>0 then
		p.act=true
		p.stats.hp=3
		p.stats.lives-=1
		player_damframes(p)
	end
	if not p.playing and btn(4,p.pid) then
		p.playing=true
		p.act=true
		p.mot.dx, p.mot.dy=0,0
	end
end

function update_controls(p)
	local pid,a,td = p.pid,p.mot.a,p.td
	if (not btn(0, pid) and not btn(1, pid)) and (btn(2, pid) or btn(3, pid)) and not btn(5,pid) then
		p.chdx=0
	else
		if p.sprflip and not btn(5,pid)then
			p.chdx=-10
		elseif not btn(5,pid) then
			p.chdx=10
		end
	end
	if not btn(2, pid) and not btn(3, pid) and not btn(5,pid) then
		p.chdy=0
	end
	local ps = p.shooting
	if p.mot.dy <=0.1 and p.mot.dy >= -0.1 and not ps then
		p.sprhflip = false
	end
	if (btn(0,pid)) then
		if not td then
			p.mot.dx-=a 
			if (not btn(5,pid)) p.chdx=-10 
		end
	end
	if (btn(1,pid)) then 
		if not td then
			p.mot.dx+=a 
			if (not btn(5,pid)) p.chdx=10 
		end
	end
	if (btn(2,pid)) then 
		if not td then
			p.mot.dy-=a 
			if (not btn(5,pid)) p.chdy=-10 
		end
	end
	if (btn(3,pid)) then 
		if not td then
			p.mot.dy+=a
			if (not btn(5,pid)) p.chdy=10 
		end
	end
	
	if btn(5, pid) then
		if p.srtn == nil then 
			p.shooting=true
			if (not p.dodging and not td) player_shoot(p)
		end
	end
	if (btn(4, pid)) then
		if not p.dodging and p.moving then
			if (not td) player_dodge(p)
		end
		
	end
	if p.chdx==-10 then
		p.sprflip=true
	else
		p.sprflip=false
	end
	if p.chdy==-10 then
		p.sprhflip=true
	else
		p.sprhflip=false
		
	end
	p.chx,p.chy=p.pos.x+3.5+p.chdx,p.pos.y+3.5+p.chdy
end

function tbl_dump(o)
    if type(o) == 'table' then
		local h,f='',''
        local s = '{'
        for k,v in pairs(o) do
            if (type(k) == 'number') h='[' f=']'
            s = s .. h..k..f..' = ' .. tbl_dump(v) .. ','
        end
        return s .. '}'
    else
		if (type(o)=="string") return '"'..o..'"'
        return tostr(o)
    end
end

-->8 
-- entity ai functions
function ai__rotate_to_target(e) 
	local t = e.targ
	local a = e.mot.ang
	local epos,tpos = e.pos,t.pos
	local ex,ey = epos.x+epos.w/2, epos.y+epos.h/2
	local tx,ty = tpos.x+tpos.w/2, tpos.y+tpos.h/2
	-- angle code credits: https://www.gamedev.net/forums/topic/679527-rotate-towards-a-target-angle/ USER https://www.gamedev.net/draika-the-dragon/
	local aim_ang=oaget(t,e)
	if (not t.act) aim_ang=oaget(e,t)
	local desiredanglem1=aim_ang-1
	local desiredanglep1=aim_ang+1
	
	local dadiff=abs(aim_ang-a)
	local dam1diff=abs(desiredanglem1-a)
	local dap1diff=abs(desiredanglep1-a)
	local closestuniverse=aim_ang
	closestdifftozero=dadiff
	if dam1diff<closestdifftozero then
		closestdifftozero=dam1diff
		closestuniverse=desiredanglem1
	end
	if dap1diff<closestdifftozero then
		closestdifftozero=dap1diff
		closestuniverse=dam1diff
	end

	
	if closestuniverse>e.mot.ang then
		e.mot.ang+=e.mot.steerspd
	elseif closestuniverse<e.mot.ang then
		e.mot.ang-=e.mot.steerspd
	end


	if (e.mot.ang>1) e.mot.ang=0
	if (e.mot.ang<0) e.mot.ang=0.999

end

function create_dummy(_x, _y)

	local p = create_ent({106}, 4, {
		x=_x, --x
		y=_y, --y,
		w=_w or 7,
		h=_h or 7
	})
	p.coll_box=create_coll_box(-1, 2, 9, 8)
	p.stats.hp=999
	p.behavior=create_timer(function()
		update_coll_box(p)
		check_collision(p)
	end,1,true)
	add(routines, p.behavior)
	return p
end

function anim_bounce(p,_x,_y,_tx,_ty, _b,_tt)
	local tt = _tt or randbi(15,20)
	local b = _b or 3
	for i = 1,b do
		dx,dy = ballisticlaunchspeed(_x,_y,_x,_y,gravity_x,gravity_y,tt)
		repeat
			p.mot.dx,p.mot.dy=getposfromang(aget(_x,_y,_tx,_ty),dst_basic(_x,_y,_tx,_ty))

			move_entity(p)
			p.pos.zoff+=dy
			dy+=gravity_y
			yield()
		until p.pos.zoff>=0
		p.pos.zoff=0
		dy=0
		tt-=tt/b
	end
end
function create_spawner(_x,_y,_type,_tx,_ty, _tt)
	local p = create_ent({148,149,150,151,152,153}, -30, {
		x=_x, --x
		y=_y, --y,
		w=_w or 7,
		h=_h or 7,
		zoff=-10
	})

	local tx = _tx or _x
	local ty = _ty or _y
	p.animdelay=2.2
	local dx,dy=0,0
	p.behavior=create_timer(function()
		while ent_off_cam(p) do
			yield()
		end
		anim_bounce(p,_x,_y,tx,ty)
		yields(3) p.sprtab={154}
		spawn_enemy(p.pos.x,p.pos.y-8,_type)
		yields(120)
		clean_ent(p)
	end,1)
	add(routines,p.behavior)
end

function spawn_enemy(_x,_y,_type)
	local x,y=_x,_y
	local can_spawn = false
	if solid(x,y) then
		y+=16
	end
	
	if _type==1 then
		create_wanderer(x, y)
	elseif _type==2 then
		create_wanderer(x, y,2,{80,82,84,82})
	end
end

function create_wanderer(_x,_y, _type, _sprtab)
	local sprtab = _sprtab or {71,72,71,70}
	local pid = 2
	if (_type==2) pid=3
	-- local sprtab = _sprtab or {112,113,114,115}
	local p = create_ent(sprtab, pid, {
		x=_x, --x
		y=_y, --y,
		w=_w or 7,
		h=_h or 7
	})
	p.act=false
	p.spawning=true
	p.coll_box=create_coll_box(-1, 2, 9, 8)
	p.mot.mspd=0.28
	p.animdelay=18
	if _type==2 then
		p.stats.hp=40
		p.mot.mspd=0.35
		p.mot.steerspd=0.065
		p.animdelay=10
		p.pos.w=15
		p.pos.h=15
		p.coll_box=create_coll_box(1, 5, 13, 13)
	end
	
	p.coll_box.coll_callback = function(cb, e) 
		if e.pid <2 then
			if (not e.dying and not e.dead and not debug)player_takedam(e,p)
		end
	end
	p.behavior=create_timer(function()
		if not ent_off_cam(p) and p.act then
			update_coll_box(p)
			check_collision(p)
			ai__move_to_target(p)
			move_entity(p)
		elseif not ent_off_cam(p) and not p.act then
			if (p.spawning) spawn_effect(p)
		end
	end,1,true)
	p.pathing = create_timer(function()
		if not ent_off_cam(p) and p.act then
			p.targ=ai__pick_player_target(p)
			ai__rotate_to_target(p)
			ai__path_to_players(p)
			-- if (debug) print(p.mot.ang..":"..p.mot.steerspd,p.pos.x-2,p.pos.y-8)
		end
	end,1,true)
	if (_type==2) then
		p.spawner = create_timer(function()
			local delay = randbi(80,180)
			if not ent_off_cam(p) and p.act then
				for i=0,delay do
					yield()
				end
				local a=p.mot.ang
				local x,y=p.pos.x,p.pos.y
				local mspd = p.mot.mspd
				local sprtab = p.sprtab
				p.sprtab={82}
				p.mot.mspd=0
				yields(20)
				local x,y=p.pos.x,p.pos.y
				local tx,ty = getposfromang(oaget(p,p.targ),dst(p.targ,p)*2)
				tx+=p.pos.x
				ty+=p.pos.y
				create_spawner(x+p.pos.w/2,y+p.pos.h/2, 1,tx,ty,40)
				p.mot.mspd=mspd/2
				anim_bounce(p,x,y,x,y,3,25)
				p.mot.mspd=mspd

				p.sprtab=sprtab
				
			end
		end,1,true)
		add(routines, p.spawner)
	end
	add(routines, p.behavior)
	add(aroutines, p.pathing)
	-- add(entities, p)
	ents+=1
	return p
end

function ai__steer(e, d)
	local sspd = e.mot.steerspd+0.1
	if d<0 then
		-- e.mot.a=e.mot.oa
		e.mot.ang+=sspd
	elseif d>0 then
		-- e.mot.a=e.mot.oa
		e.mot.ang-=sspd
	elseif d==0 then
		e.mot.ang+=0.5
	end
	
	if (e.mot.ang>1) e.mot.ang=0
	if (e.mot.ang<0) e.mot.ang=0.999
end

function ai__pick_player_target(e)
	local p1, p2 = players[1], players[2]
	local p1d, p2d = dst(e,p1), dst(e,p2)
	local p1a, p2a = p1.act, p2.act
	if (p1a and not p2a) return p1
	if (p2a and not p1a) return p2
	if (p1d<p2d) return p1
	return p2
end

function ai__path_to_players(e)
	local targ = e.targ -- target entity stored in source entity table
	local tx, ty -- undefined local variables for temp x and y
	local ang = e.mot.ang -- current path angle of source entity
	local r = 1
	if (e.pid==3) r=1.5
	for n=-0.25,0.25, 0.125 do -- draw 3 pixels. One in front, and one on each side
		tx=(e.pos.x+e.pos.w/2)-(cos(ang+n)*e.pos.w/r) -- define x for current pixel
		ty=(e.pos.y+e.pos.h/2)-(sin(ang+n)*e.pos.h/r)+1 -- define y for current pixel
		if solid(tx,ty) then
			ai__steer(e,n*1.5) -- steer function to turn enemy away from walls
		end
		-- pset(tx,ty,col)
		yield() -- yield processing back to main loop
		for i, ent in pairs(entities) do -- loop through entities to see if any are colliding with path pixel

			if e ~= ent and ent.pid>1 then -- If the entity is another enemy, then continue
				if check_pos_collision(tx,ty, ent.coll_box) then -- if colliding with another enemy
					if e.pid==3 and ent.pid==2 then
						ai__steer(ent,n*1.5) -- steer function to avoid clumping of mobs
					else
						ai__steer(e,n) -- steer function to avoid clumping of mobs
					end
				else
					e.mot.a=e.mot.oa -- if nothing is colliding, reset accelleration back to default. needs refactoring for stats!
				end
			end
		end
		if (debug) circfill(tx,ty,1,7) 
	end
end

function ai__move_to_target(ent)
	ent.mot.dx,ent.mot.dy=getposfromang(ent.mot.ang,-1)
end

-->8
-- scene functions

function init_scenes()
	_cls = true
	scenes = {
		title={
			init=function()
				add(aroutines,create_timer(function()
					local y=-1
					local flashing,c,s = false, 9,0
					local tm=2
					yields(15)
					while true do
						if (y<68) y+=2.5 
						if y>=68 and stat(54)==-1 then
							-- music(0)
							if (tm<3)tm+=0.1
						end
						if (not flashing) print("untitled shoot'm up",25, y-16,7)
						hor_wave_print("press 🅾️ /z to start!",21,y,c,tm,t(),1.2) 
						if (btnp(4)) flashing = true
						if flashing then
							c+=0.2
							s+=0.1
							if (s>1.5) tm+=2
							if (s>5) switch_scene(scenes.stage1) music(-1, 1000) break
							if (c>11) c=9
						end
						yield()
					end
				end,1))
			end,
			draw=function()
				-- map(32,0,0,0,16,16)
			end
		},
		test_menu={
			init=function()
				add(aroutines,create_timer(function()
					print('hey look a new scene')
				end,1,true))
				music(0)
			end,
			update=function()
				if (btnp(4)) switch_scene(scenes.title) music(-1)
			end
		},
		stage1={
			init=init_stage1,
			draw=draw_stage1,
			update=function()
				-- if (btnp(4)) switch_scene(scenes.test_menu) music(-1)
				update_stage1()
			end
		}
	}
end

function switch_scene(_scene, _t)
	local n=create_timer(function()
		scene_switch=true
		local f,s
		if not _t then
			f,s = scene_fade()
		end
		while s=='suspended' do
			s=costatus(f)
			yield()
		end
		for i=1,#routines do
			deli(routines, 1)
		end
		for i=1,#aroutines do
			deli(aroutines, 1)
		end
		current_scene = _scene
		f,s = scene_fade(true,current_scene.init)
		while s=='suspended' do
			s=costatus(f)
			yield()
		end
	end)
	add(aroutines, n)
end

function scene_fade(_in, _cb)
	local lin = _in or false
	local cb = _cb or false
    local g={}
    local t = create_timer(function()
        for y=0,8 do
            for x=0,8 do
                local c = create_timer(function()

                    local r=0
                    if (lin) r=16 
                    while true do
                        if not lin then
                            r+=0.5
                            if (r>16)r=16
                        else
                            r-=0.5
                            if (r<0)r=0
                        end
                        circfill(cament.pos.x+x*16,cament.pos.y+y*16,r,1)
                        yield()
                    end
                end,1) 
                add(aroutines, c)
                add(g, c)
            end
        end
        yield()
        if (lin) _cls=false 
        yields(31)
        for i, h in pairs(g) do
            del(aroutines, h)
        end
		
        if (not lin) _cls=true
		
		if (cb) cb() scene_switch=false
    end)
    add(aroutines, t)
	return t, costatus(t)
end

-->8
-- animation and draw helpers

function ballisticlaunchspeed(ox,oy, tx,ty, gx,gy, frames)
    return (tx-ox)/frames-(gx*frames)/2,(ty-oy)/frames-(gy*frames)/2
end

function getposfromang(a,_d)
	local d = _d or 1
	return cos(a)*d, sin(a)*d
end

function update_gravity_particle(p)
	p.x+=p.dx
	p.y+=p.dy
	p.dx+=gravity_x
	p.dy+=gravity_y
end

function update_dumb_particle(p)
	p.x+=p.dx
	p.y+=p.dy
end

function init_particle()
end

function create_particle(_x,_y,_r,_a,_tt,_lt,_s,_pal, _rtn)
	local traveltime=0
	local tt = _tt or 30 + randbi(0,60)
	-- printh(_r)
	local p = {
		x=_x,
		y=_y,
		r=_r or 0,
		s=_s or 1,
		a=_a,
		tt=tt,
		lt=_lt or 0,
		pal = _pal or {7},
		pi=1,
		update = _rtn or update_dumb_particle
	}
	local tx,ty = _x+cos(_a)*_s,_y+sin(_a)*_s
	p.dx,p.dy = ballisticlaunchspeed(_x,_y,tx,ty,gravity_x,gravity_y,_tt)
	local np = create_timer(function()
		
		repeat
		-- while lifetime~=p.l do
			circfill(p.x,p.y,p.r,p.pal[p.pi])
			p:update(p)
			traveltime+=1
			yield()
		-- end
		until traveltime==p.tt
		for lt=0,p.lt do
			circfill(p.x,p.y,p.r,p.pal[p.pi])
			yield()
		end
		del(particles, np)
	end,1)
	add(particles, np)
end

function spawn_effect(_e)
	local sprtab = {176,177,178,179,180,181,182,183,184,185}
	local spri=1
	local d = 0.10
	_e.spawning=false
	local speff = create_timer(function()
		for f in all(sprtab) do
			for i=0,d,0.1 do
				spr(f,_e.pos.x,_e.pos.y)
				yield()
			end
		end
		yields(3)
		_e.act=true
	end,1)
	add(aroutines, speff)
end

function ent_drawing_rig(e)
	local animi = 1
	local animpos = true
	e.prev_tab = e.sprtab
	local rig = create_timer(function()
		local gsp = function()
			local newi = animi
			local negchk = newi-1<1
			local poschk = newi+1>#e.sprtab
			if animpos then
				if poschk then
					newi=1
				else
					newi += 1
				end

			else
				if negchk then
					animpos=true
					if (not poschk) newi+=1
				else
					newi -=1
				end
			end
			animi=newi
		end
		gsp()
		
		if (e.act and not e.blink and e.pid~=-10) draw_entity(e,animi)
		
		if (e.prev_tab ~= e.sprtab) animi=1 animpos=true 

	end,1,true)
	return rig
end


function hor_wave_print(_str,_x,_y,_col,_dst, _i,_spd)
	local dst = _dst or 4
	local spd = _spd or 1
	local i = _i or t()
	local x = _x
	local xm = 1
	for c=1,#_str do
		local s=sub(_str,c,c)
		local y = _y+cos((i+c/#_str*2)/spd)*dst
		print(s,x-1+(4*xm),y+1,1)
		print(s,x+(4*xm),y,_col)
		xm+=1
	end
end

-->8
-- coroutine functions
function create_timer(_callback, _max, _loop, _lc, _finally, _call_asap)
	local loop = _loop or false 
	local lc = _lc
    local finally = _finally
    local call_asap = _call_asap or false
    local call_index = 1
	local max = _max or 1
    if call_asap then
        call_index = 1
    else
        call_index = max
    end
    local new_timer = cocreate(function()
		local i=1
		local li=1
        while i<=max do
            yield()
            if (i==call_index) _callback()
			if (i==max) then
				if (loop) then
					if (lc~=nil and li>=lc) then
                        break 
                    end
					i=0
					li+=1
				end
			end
			i+=1
        end
        if (finally~=nil) finally() 
    end)
    return new_timer
end

function manage_routines(_t)
    local t = _t or routines
    for i, routine in pairs(t) do
        manage_routine(routine)
    end
end

function manage_routine(routine)
	if routine~=nil then
		if costatus(routine) then
			a,e = coresume(routine)
            if (e) printh('COROUTINE EXCEPTION: '..e)
		end
		if costatus(routine)=='dead' then
            del(aroutines, routine)
			del(routines, routine)
			del(drigs, routine)
			del(particles, routine)
		end
	end
end

function yields(n) for i=1,n do yield() end end

-->8
-- entity functions
function clean_ent(e)
	del(routines,e.behavior)
	del(aroutines,e.behavior)
	del(routines,e.pathing)
	del(aroutines,e.pathing)
	del(routines, e.spawner)
	del(drigs, e.draw_rig)
	del(entities, e)
end

function create_ent(_sprtab, _pid, _pos, _mot, _coll_box, _pal)
	local e={
		shtdelay=26,
		pid=_pid or 2,
		sprtab=_sprtab or {240},
		prev_tab = {}, -- previous animation table, stored to track animation index when it swaps
		animdelay = 5,
		sprflip = false,
		pal=_pal or {},
		act=true,
		playing=_pid==0,
		pos = _pos or {
			x=60, --x
			y=60, --y,
			w=7,
			h=7
		},
		mot = _mot or {
			dx=0, --dx
			dy=0, --dy,
			a=0.075,
			mspd=0.55,
			drg=0.9,
			ang=0,
			steerspd=0.018
		},
		stats={
			hp=1,
			max_hp=5,
			ammo=0,
			stype=1,
			keys=0,
			coin=0,
			score=0,
			lives=6,
			pierce=0
		},
		chdx=10,
		chdy=0,
		coll_box = _coll_box or create_coll_box(2, 6, 4, 4, function()  end)
	}
	
	e.mot.oa=e.mot.a
	e.draw_rig = ent_drawing_rig(e)
	add(aroutines, e.shadow)
	add(drigs, e.draw_rig)
	add(entities, e)
	return e
end

function swap_pal(ptab)
	for k,t in pairs(ptab) do
		pal(t[1], t[2])
	end
end

function draw_entity(e,i)
	local ds = function()
		if e.act then
			if (e.pos.zoff==nil)e.pos.zoff=0
			local x,y,w,h = e.pos.x,e.pos.y,e.pos.w,e.pos.h
			ovalfill(x,y+h,x+w,y+h+2,0)
			if (#e.pal>0) swap_pal(e.pal)
			spr(e.sprtab[i],x, y+e.pos.zoff,ceil(w/8),ceil(h/8), e.sprflip)
			pal()
			e.prev_tab = e.sprtab
		end
	end

	if e.animdelay > 1 then
		for d=0, e.animdelay do
			ds()
			yield()
			if (e.sprtab ~= e.prev_tab) i=1
			ds()
		end
	else
		ds()
	end
end

function move_entity(p)
	p.context_show=false

	p.mot.dx=mid(-p.mot.mspd,p.mot.dx,p.mot.mspd)
	p.mot.dy=mid(-p.mot.mspd,p.mot.dy,p.mot.mspd)
	local dx,dy = p.mot.dx,p.mot.dy

	wall_check(p)

	if (can_move(p,dx,dy)) then
		p.pos.x+=dx
		p.pos.y+=dy
	else
		tdx,tdy=p.mot.dx,p.mot.dy
		while (not can_move(p,tdx,tdy)) do
			if (abs(tdx)<=0.1) then
				tdx=0
			else
				tdx*=0.9
			end
			if (abs(tdy)<=0.1) then
				tdy=0
			else
				tdy*=0.9
			end
			if tdx==0 and tdy==0 then
				tdx=dx*-1/10*0.9
				tdy=dy*-1/10*0.9
				break
			end
		end
		p.pos.x+=tdx
		p.pos.y+=tdy
	end 
	if (abs(dx)>0) p.mot.dx*=p.mot.drg
	if (abs(dy)>0) p.mot.dy*=p.mot.drg
	if (abs(dx)<0.01) p.mot.dx=0
	if (abs(dy)<0.01) p.mot.dy=0

	pi=3.14
end

-->8
-- stage1 functions

function init_scoreboard(p)
	local ox=1
	local sc = 9
	if (p.pid==1) sc=12
	p.sx,p.sy=0,0
	if p.pid>0 then
		ox=66
	end
	local ur = create_timer(function()
		p.sx,p.sy = cament.pos.x+ox,cament.pos.y
	end,1,true)
	local r = create_timer(function()
		
		local sx,sy = p.sx,p.sy
		local lives = p.stats.lives
		rectfill(sx, sy, sx+60,sy+14, sc)
		rect(sx-1, sy, sx+61,sy+14, 13)
		if p.act then
			local shp=158
			local sox=1
			for i=1,p.stats.max_hp do
				if (i>p.stats.hp) shp=159
				spr(shp,sx+sox,sy+2)
				sox+=6
			end
			sox=0
			for i=1,5 do
				print('웃',sx+sox, sy+8,1)
				sox+=6
			end
			sox=0
			for i=1,lives do
				if (i>5)break
				if (i>p.stats.hp) shp=159
				print('웃',sx+sox, sy+8,7)
				sox+=6
			end
			local ammo = p.stats.ammo
			if (p.stats.stype==1) ammo="○"
			spr(189,sx+32,sy+2)
			spr(190,sx+31,sy+8)
			print(":"..p.stats.coin,sx+38, sy+2,1)
			print(":"..ammo,sx+38, sy+8,1)
		else
			if lives <1 then
				hor_wave_print("game over",sx+8,sy+5,7,2,t(),1.5) 
			else
				hor_wave_print("🅾️  to join!",sx+6,sy+5,7,2,t(),1.5) 
			end
		end
		
	end,1,true)
	add(routines, ur)
	
	add(aroutines, r)
end

function init_stage1()
	music(0)
	-- for i = 0,5 do
	-- 	create_spawner(randbi(146,220), randbi(24,100),1)
	-- end
	create_spawner(randbi(146,220), randbi(24,100),2)
	create_dummy(64,64)
	init_players()
	players[2].act=false
	
end

function draw_stage1()
	map(0,0,0,0,32,32)	
end

function update_stage1()
	if not scene_switch then
		for i, p in pairs(players) do
			update_coll_box(p)
			if p.act then 
				if (not p.dying and not p.dead) update_controls(p)
				if (not cament.moving) move_entity(p) 
			else
				check_respawn(p)
			end
		end
		update_camera()
	end
end


-->8
-- camera code
	
function move_camera(newx,_newy, ie,ae)
	newy = _newy or cament.pos.y
	cament.moving = true
	local tdst=2
	local a = aget(newx,newy,cament.pos.x,cament.pos.y)+.5
	local dx,dy = getposfromang(a)
	local newr = create_timer(function()
		while tdst>1 do
			tdst = dst_basic(newx,newy,cament.pos.x,cament.pos.y)
			cament.pos.x+=dx*(tdst/6)
			cament.pos.y+=dy*(tdst/6)
			ie.pos.x+=dx*0.6
			ie.pos.y+=dy*0.6
			yield()
		end
		cament.pos.x = newx
		cament.pos.y = newy
		ae.pos.x=ie.pos.x
		ae.pos.y=ie.pos.y
		ae.mot.dx=ie.mot.dx
		ae.mot.dy=ie.mot.dy
		ae.sprflip = ie.sprflip
		ae.sprhflip = ie.sprflip
		cament.moving=false
	end,1) 
	add(routines, newr)
end

function update_camera()
	local p1p,cx,cy = players[1].pos,cament.pos.x,cament.pos.y
	local ie,ae
	for p in all(players) do
		if ent_off_cam(p) then
			p1p=p.pos
			ie=p
		else
			ae = p
		end
	end
	local x,y,w,h = p1p.x,p1p.y,p1p.w,p1p.h
	if not cament.moving then
		if x < cx then
			move_camera(cx-128,cy, ie, ae)
		elseif x+w > cx+127 then
			move_camera(cx+128,cy, ie, ae)
		end

		if y < cy then
			move_camera(cx,cy-128, ie, ae)
		elseif y+h > cy+127 then
			move_camera(cx,cy+128, ie, ae)
		end
	end
	camera(cx,cy)
end

-->8
-- math functions

function vintab(_v,t)
	for k, v in pairs(t) do
		if (v == _v) return true
	end
	return false
end

--random int between 0,h
function rand(h) --exclusive
    return flr(rnd(h))
end
function randi(h) --inclusive
    return flr(rnd(h+1))
end

--random int between l,h
function randb(l,h) --exclusive
    return flr(rnd(h-l))+l
end
function randbi(l,h) --inclusive
    return flr(rnd(h+1-l))+l
end

function aget(x1,y1,x2,y2) return atan2(-(x1-x2), -(y1-y2)) end

function oaget(o1,o2)
	return aget(o1.pos.x+o1.pos.w/2, o1.pos.y+o1.pos.h/2, o2.pos.x+o2.pos.w/2, o2.pos.y+o2.pos.h/2)
end

function dst(o1,o2)
	local x0,y0=o1.pos.x,o1.pos.y
	local x1,y1=o2.pos.x,o2.pos.y
  	return dst_basic(x0,y0,x1,y1)
end
function dst_basic(x0,y0,x1,y1)
  -- scale inputs down by 6 bits
  local dx=(x0-x1)/64
  local dy=(y0-y1)/64
  
  -- get distance squared
  local dsq=dx*dx+dy*dy
  
  -- in case of overflow/wrap
  if(dsq<0) return 32767.99999
  
  -- scale output back up by 6 bits
  return sqrt(dsq)*64
end
function sqr(x) return x*x end

-->8
--collision functions

function create_coll_box(_cx, _cy, _cw, _ch, _coll_callback)
    local coll_box = {
        cx = _cx,
        cy = _cy,
        cw = _cw,
        ch = _ch,
        cx_l = 0,
        cx_r = 0,
        cy_t = 0,
        cy_b = 0,
		coll_callback = _coll_callback or function() end
    }
	return coll_box
end

function check_pos_collision(x,y, coll_box)
	return (coll_box.cx_r>=x and
	coll_box.cx_l<=x) and
	(coll_box.cy_b>=y and
	coll_box.cy_t<=y)
end

function simple_coll_check(cb1, cb2)
	local touching = (cb1.cx_r>=cb2.cx_l and
	cb1.cx_l<=cb2.cx_r) and
	(cb1.cy_b>=cb2.cy_t and
	cb1.cy_t<=cb2.cy_b)
	return touching
end

function check_collision(e)
    
    collide = false
	for i, tar in pairs(entities) do
		if tar.act==true and e.act==true and tar.pid~=e.pid then
			if tar.coll_box~=nil then
				if simple_coll_check(e.coll_box, tar.coll_box) then
						e.coll_box:coll_callback(tar)
				end
			end
		end
	end
    return collide
end

function draw_coll_box(coll_box)
	local cl,cr,ct,cb = coll_box.cx_l,coll_box.cx_r,coll_box.cy_t,coll_box.cy_b
    line(cl,ct,cr,ct,3)
    line(cl,cb,cr,cb,14)
    line(cl,ct,cl,cb,12)
    line(cr,ct,cr,cb,2)

end

function update_coll_box(e)
	local cb = e.coll_box

    cb.cx_l = e.pos.x + cb.cx
    cb.cx_r = e.pos.x + cb.cx + cb.cw
    cb.cy_t = e.pos.y + cb.cy
    cb.cy_b = e.pos.y + cb.cy + cb.ch
end

function can_move(a,dx,dy)
	local nx_l=a.pos.x+dx       --lft
	local nx_r=a.pos.x+dx+a.pos.w   --rgt
	local ny_t=a.pos.y+dy       --top
	local ny_b=a.pos.y+dy+a.pos.h   --btm
	local top_left_solid=solid(nx_l,ny_t)
	local btm_left_solid=solid(nx_l,ny_b)
	local top_right_solid=solid(nx_r,ny_t)
	local btm_right_solid=solid(nx_r,ny_b)
	return not (top_left_solid or
			btm_left_solid or
			top_right_solid or
			btm_right_solid)
end

function ent_off_cam(e)
	local x,y,w,h = e.pos.x,e.pos.y,e.pos.w,e.pos.h
	return (off_cam(x,y) or
				off_cam(x+w,y) or
				off_cam(x,y+h) or
				off_cam(x+w,y+h)
			)
end

function off_cam(x,y)
	if cament.pos.x>x or cament.pos.x+127<x or cament.pos.y>y or cament.pos.y+127<y then
		return true
	end
	return false
end
function solid(x,y)
 local map_x=flr(x/8)
 local map_y=flr(y/8)
 local map_sprite=mget(map_x,map_y)
 local flag=fget(map_sprite)
 return flag==1
end

function wall_check(a)
	local x,y,w,h,dx,dy = a.pos.x,a.pos.y,a.pos.w,a.pos.h,a.mot.dx,a.mot.dy
	if (dx<0) then
		local wall_top_left=solid(x-1,y)
		local wall_btm_left=solid(x-1,y+h)
		if (wall_top_left or wall_btm_left) then
			a.mot.dx=0
		end
	elseif (dx>0) then
		local wall_top_right=solid(x+w+1,y)
		local wall_btm_right=solid(x+w+1,y+h)
	if (wall_top_right or wall_btm_right) then
		a.mot.dx=0
	end
end

	if (dy<0) then
		local wall_top_left=solid(x,y-1)
		local wall_top_right=solid(x+w,y-1)
		if (wall_top_left or wall_top_right) then
			a.mot.dy=0
		end
	elseif (dy>0) then
			local wall_btm_left=solid(x,y+h+1)
			local wall_btm_right=solid(x+w,y+h+1)
		if (wall_btm_right or wall_btm_left) then
			a.mot.dy=0
		end
	end
end
__gfx__
00000000000000000000000000000000000000000044444000444440004444400000000000000000000000000000000000000000000000000000000000000000
00000000000000000444440001111100004444400441ff140441ff14044fff4400000440000711000044f0000044444000000000000000000000000000000000
0000000000000000441ff140117cc710044fff4404ffeef404ffeef404f1ff140000ff440071190004419f70044fff4400000000000000000000000000000000
00000000000000004f1ff1401c7cc71004f1ff1400fffff000fffff000ffee9f0199f1f400f9990004ffe91704fffff404444400004444400044444000444440
00000000000000000ffeef000cc11c0000ffeef00f9999000f9999f0000999f00119eff40f9eeff004ffe91100f1ff1044fff440044fff44044fff44044fff44
000000000000000079999700177771000f9999000f11110000111100000911700719eff4041ff1f404f1f991009999004f1ff14004f1ff1404fffff404fffff4
00000000000000000111100001111000001111f0077000000700700000011700007f9144044fff44044ff0000f1111f00fffff0f70fffff000f1ff1000f7ff70
00000000000000000070070000600600070070000000000000000000000000000000f440004444400044000007000070711999f00711999f711999ff711999ff
00000000000000000000000000444440004444400000000000000000000000000000000000000000000000000044440000444400000000000000000000000000
000000000000000000444440044fff44044fff440044444004444400044444000444440000000000004444000444444004444440004444000044440000444440
0000000000000000044fff4404f1ff1404f1ff14044fff4444fff44044fff44044fff4400000000004444440044444f0044444f00444444004444440044fff44
000000000000000004f1ff1400fffff000fffff004f1ff144fbffb404fbffb404fbffb4000000000044444f00044ffdd0044ffdd044444f0044444f004f1ff14
000000000000000000fffff0009999000099990000fffff00ffeef000ffeef000ffeef00000000000044ffdd009999f0009999f00044ffdd0044ffdd00fffff0
00000000000000000099990000111170071111000099990009999ff009999ff009999ff000000000009999f00011117007111100009999f0009999f000999900
0000000000000000001111700700000000000070071111000111170071111000711110000000000000111170070000000000007007111100001111000f1111f0
00000000000000000070000000000000000000000000070007000000000007000000700000000000007000000000000000000000000007000070070000700700
08828200000000800022200000288200000000000000000000000000000000000000000000000000000000000044440000444400000000000000000000000000
89289820002802980289820002899820000000000000000000000000000000000000000000000000004444000444444004444440004444000044440000000000
0208998202898028289a98202899a98200000000000000000000000000000000000000000000000004444440044444f0044444f0044444400444444000000000
0089a998889a988289a7a980899a7a92000000000000000000000000000000000000000000000000044444f00044ff000044ff00044444f0044444f000000000
089a7a9889a7a998899a98002889a9820000000000000000000000000000000000000000000000000044ff0000999900009999000044ff000044ff0000000000
0289a982889a99822899802082089820000000000000000000000000000000000000000000000000009999000011117007111100009999000099990000000000
00289820028998200289829889208200000000000000000000000000000000000000000000000000001111700700000000000070071111000f1111f000000000
00088800002882000028288008000000000000000000000000000000000000000000000000000000007000000000000000000000000007000070070000000000
0cc1c100000000c000111000001cc1000f4444f00044440000444400000000000000000000000000000000000044444000444440000000000000000000000000
cc1ccc10001c01cc01ccc10001cccc100f4ff4f00f4ff4f0041ff14000000000000000000000000000444440044fff44044fff44004444400044444000000000
010cccc101ccc01c1cc7cc101ccc7cc1091ff190f41ff14ff4feef4f000000000000000000000000044fff4404f1ff1404f1ff14044fff44044fff4400000000
00cc7cccccc7ccc1cc777cc0ccc777c109feef9099feef9990ffff0900000000007000700000000004f1ff1400ffeddd00ffeddd04f1ff1404f1ff1400000000
0cc777cccc777cccccc7cc001ccc7cc100999900009999000999999000000000007000700000000000ffeddd0099fdf00099fdf000ffeddd00ffeddd00000000
01cc7cc1ccc7ccc11cccc010c10ccc100011110000111100001111000000000007670767000000000099fdf000111170071111000099fdf00099fdf000000000
001ccc1001cccc1001ccc1cccc10c1000011110000111100001111000000000006d606d600000000001111700700000000000070071111000011110000000000
000ccc00001cc100001c1cc00c000000007707700077077007700770000000000d5d0d5d00000000007000000000000000000000000007000070070000000000
06000000000000000000000000011170000111700001117001444000000000000004441000077000000000000000000000000000000000000000000000000000
dd6111700661117000011170011cc720011cc720011cc72044144410014444100144414400777700007777000000000000000000000000000000000000000000
0dd6c720ddd6c720011cc7201cccc7201cccc7201cccc72047644144441441444414467400770700077007700777777000000000000000000000000000000000
ddd6c7201dd6c720166cc720ddd6cc101cc6cc101dd6cc1043744674476446744764473400700700070700707770007700000000000000000000000000000000
1dd6cc101cc6cc10ddd6cc10166ccc111dd6cc11ddd6cc1143788734437447344378873400700700070000707700007700000000000000000000000000000000
1ccccc111ccccc111ccccc1149999400ddd694004dd6940044488734437887344378844400700700077007700777777000000000000000000000000000000000
4999940049999400499994000444400006644000dd64400011fff44444488444444fff1100777700007777000000000000000000000000000000000000000000
04444000044440000444400000000000000000000600000000000f1111ffff1111f0000000077000000000000000000000000000000000000000000000000000
0011444440000000000000000000000000000004444411000202770220772020000555500551650000dddd0000dddd0000000000000000000000000000000000
01111444444411000011444444441100001144444441111000771b7007b17700005165007dd175500d7667d00d7667d000000000000000000000000000000000
044111444441111001111444444111100111144444111440271771722717717205d1750507ddd5050d7667d00d7667d000000000000000000000000000000000
44441114441114400441114444111440044111444111444407b1778008771b705ddddd5d0000dd5d006226000062260000000000000000000000000000000000
4466d11441114444444411144111444444441114411d6644187788822888778149999ddd00009ddd669999666699996600000000000000000000000000000000
46776d14411d66444466d114411d66444466d11441d6776418888710017888810499940507999405001111000011110000000000000000000000000000000000
4733764441d6776446776d1441d6776446776d144467337401781102211187100044440079999440077111000011177000000000000000000000000000000000
47337644446733744733764444673374473376444467337420110200002011020004444004444400000007700770000000000000000000000000000000000000
47337648846733744733764444673374473376488467337400111100000000001111111111111111000000000000000000000000000000000000000000000000
473376888867337447337648846733744733768888673374011333100001110018fff8f116fff6f1004444400000000000000000000000000000000000000000
4477648888673374473376888867337447337688884677440137b710001133101789978117699761044444440000000000000000000000000000000000000000
0444442288467744447764888846774444776488224444400131b1100117b7101789978117699761044544540000000000000000000000000000000000000000
01111fff22444440044444222244444004444422fff1111011bbb3100131b1101f9999911f999991004455400000000000000000000000000000000000000000
1dd51ffffff1111001111ffffff1111001111ffffff15dd113bb131011bbb3101f9888811f966661004444000000000000000000000000000000000000000000
11111000fff15dd11dd51ffffff15dd11dd51fff0001111113bb131013bb13101f8888811f666661044444400000000000000000000000000000000000000000
00000000000111111111100000011111111110000000000013bbb31013bb13111111111111111111004004000000000000000000000000000000000000000000
000570000000000000000000000d5000111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
00076000000760000006d0000005700012ffff211f2fff2112fff2f118ffff8116ffff611f8fff811f6fff610000000000000000000000000000000000000000
0076d5000006d000000d500000576d00172992711279927117299721178998711769967118799871167996710000000000000000000000000000000000000000
076d5760006d570000d576000576d570172992711279927117299721178998711769967118799871167996710000000000000000000000000000000000000000
76d576d506d576d50d576d50576d576d1f9999911f9999911f9999911f9999911f9999911f9999911f9999910000000000000000000000000000000000000000
555555556d576d57d576d576555555551f9229911f9229911f9229911f8888911f66669118888991166669910000000000000000000000000000000000000000
011001005555555555555555001001101f2992911f2992911f2992911f8888911f66669118888891166666910000000000000000000000000000000000000000
11100110011001101100001101100111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000
02202200002020000002000000202000111111111111111111111111111111111111111111111111111111110011110000011000000110000001100011111111
278288200272820000222000028272001f7771f117771ff11771ff71171ff77111ff77711ff777111f2221f101eeee10001ee100001ee100001ee100ff1ffff1
288888200288820000828000028882001f717191171719911171997117199711119971711f9717111f2121411e88882101e882100018810001288e10f41f4441
288888200288820000828000028882001f117191111719911171991117199111119911711f9117111f1121411e88882101e882100018810001288e10f41f4441
128882100128210000828000012821001f9711911f7119911711999111199971119997111f9971111f4211411e88882101e882100018810001288e1011111111
012821000028200000828000002820001f9119911f11999111199991119999111f9991111f9911911f4114411e88882101e882100018810001288e10fff1ff1f
001210000012100000212000001210001f9719911f71999117199991119999711f9997111f9971911f421441012222100012210000122100001221004441f41f
0001000000010000000100000001000011111111111111111111111111111111111111111111111111111111001111000001100000011000000110004441f41f
0022220000022000000220000002200011111111111111111111111111111111111111111111111111111111000000000007a900144444410101000002020000
027777200027720000277200002772001ff777111f7771f117771ff11771ff71171ff77111ff77711ff2221100000000000a22004ffffff21718100021212000
27aaaa92027aa920002aa200029aa7201f9711111f711191171119911111997111199711119971111f421111000000000007a9004f1111f21888100021112000
27aaaa92027aa920002aa200029aa7201f9777111f777191177719911771997117199771119977711f42221100000000000a22004ffffff20181000002120000
27aaaa92027aa920002aa200029aa7201f9711111f711191171119911111997111199711119971111f42111100000000007aaa004f11f1f20010000000200000
27aaaa92027aa920002aa200029aa7201f77771117777191177719711771977117197771119777711f22221100000000092222904ffffff20000000000000000
029999200029920000299200002992001f77771117777191177719711771977117197771119777711f2222110000000002999920122222210000000000000000
00222200000220000002200000022000111111111111111111111111111111111111111111111111111111110000000000222200000420000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000001110000011100000111000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000171000001b10000017100000171000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b1000001710000017100000171000
0000000000000000000000d000000d0d0000000d0000000000000000000000000000000000000000000000000000000001b7b10001b7b10001b7b10001bbb100
000000000000000000000d0d000060000000006000000000000000000000000000000000000000000000000000000000137bb310137bb31013bbb310137bb310
0000000000060d00000060d00000000d000000000000000000000000000000000000000000000000000000000000000013bb331013bb331013bb331013bb3310
06000000006060000006060d00006060000000000000000000000000000000000000000000000000000000000000000013333310133333101333331013333310
77600000777606000777606000770000000700000000000000000000000000000000000000000000000000000000000001111100011111000111110001111100
00000000000000000000000000000000000550000077770000055000000550000005000000000000009000000000000000000000001000000111100000000000
009aa900002882000000000000055000055dd55007777770055dd550055d0000055000000000000009a9000000a0000000000000017100001dddd10000000000
09a77a900287f82000055000005dd50005d66d507777777705d6005005d0000005000000000000009a7a90000a7a00000070000017a910001d61100000000000
0a77ffa008ffa980005dd50005d66d505d6776d5777777775d6700d55d6000055d0000005000000009a9000000a0000000000900019100001d10000000000000
0affffa008aaa980005dd50005d66d505d6776d5777777775d6776d55d6700d55d600005500000000090000000000a0000009a90001000000100000000000000
09affa900289982000055000005dd50005d66d507777777705d66d5005d66d5005d6005005000000000007000000a7a00009a7a9000000000000000000000000
009aa900002882000000000000055000055dd55007777770055dd550055dd550055dd550005000000000000000000a0000009a90000000000000000000000000
00000000000000000000000000000000000550000077770000055000000550000005500000055000000000000000000000000900000000000000000000000000
000830083008300830083000000830000000000000000000000000000000000000000000000000000000000000000000000330200000000009a00a900b303000
003ab83ab33ab83ab33ab800003ab3000000000000000000000000000000000000000000000000000000000000000000020b32e2030b3000009aa900bbb30000
08a33b1338a33b1338a33b1008a33b10000000000000000000000000000000000b3000000bb3000000003bb000003b002e2bb02000bbb30300099000b3bb0030
03b8b331b3b8b331b3b8b33103b8b3310000000000000000000000000b30000000b0003b000b3000bb30b00b03b3b0000203b0300b3bbb30303b3300bbb30bb3
8bbbbb318bbbbb318bbbbb318bbbbb31000003b0b300000300000b3b00b3000000b3b0b00000b03b00b3b0003b0b0000030bbb300bbbbb300bbbb3303bbb03bb
3bbb8b313bbb8b313bbb8b313bbb8b3100003b000b03000b030000b3bbbb3bb0b30b03b000b0b3b0000b003bb00b00b30b3bb0003b3b3b300bb3bb300b3b0bbb
13833311138333111383331113833311b300b0b3bb0bb0bb0b3000bb3bbbbb000b0b0b000b30bb00b30b00b3b00b003b0bbbb0000bbbbb3303bbbb3030bb3b30
011111100111111001111110011111103bbb3bbb3bbb3bbbbbb33b3bbb3bbbb30b0b0b000b00bb000b0b00b0b00b000b000b300003bbb3300bbb3b3000033300
000000000000000000000000004ff40000e77e0000d66d00eeeeeee8eeeeeeeee888888233333333ffffffff1111111111111111111111110000000110000000
00000000000000000000000002ffff2008777780026666208eeeee82e88888818e88882133333b33f7fff7ff12155211155d1551166166610000001111000000
0044210000ee820000dd2100244ff4428ee77ee82dd66dd228eee821e8eeee21882222113b333333ffffffff115215511111111116516d510000011111100000
044442100eeee8200dddd2101244442128eeee8212dddd21288e8221e8e82121882222113333333bfff7fff7152152211155d151165165510000111111110000
044222100ee888200dd2221001111110022222200111111028822221e8e2212188222211333b3333ffffffff1255215111111111111111110001111111111000
01211110028222200121111000022000000880000002200028211221e8e111218822221133333333f7fff7ff155225511d155d11166666510011666166661100
00021000000820000002100000021000000820000002100082111121e822222182111121333333b3ffffffff15211551111111111655555101116d516dd51110
00042000000e8000000d200000021000000820000002100021111112e11111112111111233b33333fff7fff71111111115d155d1111111111111655165551111
000330000003300007ccc700000880000000e0000a000000aaaaaaa9aaaaaaaaa99999949999dddd000000000000000000000001100000001111111111111111
0038a3000038a3007c191c700087a800000e8e00a4a00a009aaaaa94a99999929a9999429aaad666000000121100000000000011110000000111166666611110
003ab300003ab300c19a91c0008a780000e8a8e00ab3a4a049aaa942a9aaaa42994444229aaad66600000221222000000000011111100000001116dddd511100
033bb380035b5580c9a7a9c000088000000e8e000003ba00499a9442a9a94242994444229aaad666000021255512000000001111111100000001155555511000
03abb33003a55330c19a91c0000300000000e00000a0300049944442a9a4424299444422dddd9999000211552251200000011111111110000000111111110000
33bb833335bb83537c191c7000b3b000033030330a4a30a049422442a9a2224299444422d6669aaa0021255215521200001111115d1111000000011111100000
38bbbb31385b553107ccc700b35b53b00bb333bb00abba4a94222242a944444294222242d6669aaa011115525521111001111111111111100000001111000000
3bbbb8313bb55831000300000b353b0000bbbbb000003ba042222224a222222242222224d6669aaa0215552122155520111155d155d111110000000110000000
13bb333115bb33510005000b000ee0000000d0000700000077777776777777777666666d15ddd5dd022255225522552011111111111111110000000000000000
018333100185551000030bb300e7fe00000d2d007f7007006777776d76666661676666d15ddd15dd01155215221551100111155d155d11100000000000000000
00111100001111000bb3bb3b00ef7e0000d212d007b37f70d67776d1767777d166dddd115dd15dd1001115512152210000111111111111000000000000000000
0011210000115100b33533b0000ee000000d2d000003b700d6676dd17676d1d166dddd115dd55dd5000222255521100000011155d11110000000000000000000
00221200002215003bb30000000300000000d00000703000d66dddd1767dd1d166dddd115ddd5dd5000011552212000000001111111100000000000000000000
0042210000422100b005000000b3b0000330303307f73070d6d11dd1767111d166dddd11ddd151dd000001221210000000000111111000000000000000000000
002421000024210000050000b35b53b00bb333bb007bb7f76d1111d176ddddd16d1111d1dd15551d000000122100000000000011110000000000000000000000
0042210000422100000350000b353b0000bbbbb000003b70d111111d71111111d111111dd15dd55d000000000000000000000001100000000000000000000000
__label__
ee00eee0eee0e0e00ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e000e0e0e0e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0ee00ee00e0e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e000e0e0e0e0e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0eee0eee00ee0eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee00000ee000ee0ee000ee0eee0ee000ee000000000eee0eee0e0000ee0eee00000000000000000000000000000000000000000000000000000000000000000
e0e00000e0e0e0e0e0e0e0000e00e0e0e0000e000000e000e0e0e000e000e0000000000000000000000000000000000000000000000000000000000000000000
eee00000e0e0e0e0e0e0e0000e00e0e0e00000000000ee00eee0e000eee0ee000000000000000000000000000000000000000000000000000000000000000000
e0000000e0e0e0e0e0e0e0e00e00e0e0e0e00e000000e000e0e0e00000e0e0000000000000000000000000000000000000000000000000000000000000000000
e0000e00eee0ee00eee0eee0eee0e0e0eee000000000e000e0e0eee0ee00eee00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0ee00eee0eee0eee0eee0eee00ee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e0e00e000e000e000e00e000e0000e00000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00e0e00e000e000e000e00ee00eee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e0e00e000e000e000e00e00000e00e000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0e0e00e00eee00e00eee0eee0ee0000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0eee00ee0e0e0eee0eee0ee00eee00ee000000000eee000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e0e0e0e0e00e000e00e0e0e000e0000e000000e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0ee00e0e0e0e00e000e00e0e0ee00eee000000000e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e0e0e0e0e00e000e00e0e0e00000e00e000000e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e0ee000ee00e00eee0e0e0eee0ee0000000000eee000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee00ee0e0e0eee0eee0ee00eee00ee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e0e0e00e000e00e0e0e000e0000e00000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00e0e0e0e00e000e00e0e0ee00eee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e0e0e00e000e00e0e0e00000e00e000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0ee000ee00e00eee0e0e0eee0ee0000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00eee0eee00ee00ee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e00e00e000e0000e00000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0ee000e00e000eee000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e0e0e00e00e0e000e00e000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0e0e0eee0eee0ee0000000000eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee0eee0e0000ee0eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e0e0e000e000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00eee0e000eee0ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e0e0e00000e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e000e0e0eee0ee00eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000004444400000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000044fff440000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000004f1ff140000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000fffff00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000009999000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000f1111f00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000010000000000000000010101010100000000010101000000000000000000
0000000000000000000000000001000000000000000000010101010000000000000000000000000001010101000000000000000001010100000000000000000000000000000000000000000000000000000000000000010101000001010101010000000000000101010001010101010100000000000001010100010101010000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dedddddddddddddddddddddddddddddfdedddddddddddddddddddddddddddddf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9d9ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9d9ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9d9ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9d9ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd9d9d9d9d9d9d9d9d9d9d9d9d9d9ddddd9d9d9d9d9d9d9d9d9d9d9d9d9d9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeddddddddddddddddddddddddddddefeeddddddddddddddddddddddddddddef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000a63000630006300061000610006100061000610016100063000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000100201102013020150201602016020150201401011010100001800016000160001700019000000001a000000001a0001b0001b0000000000000000000000000000000000000000000000000000000000
010100000d4200f4202d4202c3202b4202812024420251102121022110206101f110227101f110170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000000038020340203302032020000003a05038020350203302031020300202d0202c0200000000000000003503032030300302e0302b0302a030000000000000000000000000000000000000000000000
000100001a02018020160201602017020190201d0201e01011010100001800016000160001700019000000001a000000001a0001b0001b0000000000000000000000000000000000000000000000000000000000
730200051825018230184421823218342003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040900020c04200115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00201ad301ad301dd311dd321dd321dd321a5001ad301ad351ad351fd311fd321fd321fd3200d001ad301ad351ad351dd311dd321dd321dd3200d0018d3500d0018d3518d3500d0018d3519d3219d321ad35
010d00201ad301ad301dd311dd321dd321dd321ad001ad401ad351ad351fd311fd321fd321fd3200d001ad301ad351ad351dd311dd321dd321dd3200d001dd351fd3020d3121d3121d3221d3221d3221d3221d30
010d00201ad3015d3518d351ad301ad3515d3018d351ad341dd351dd211cd211ad221ad2518d2418d3200d001fd301fd3200d0021d2221d2200d001dd321dd321dd321dd301dd221dd301dd221dd3221d2021d32
010d00201fd301fd2521d351fd201fd301fd251dd311dd211ad311ad201ad351ad221ad321ad2218d3518d201dd351dd201cd321ad2218d3018d251dd301dd251cd321cd221dd311dd201dd351fd211fd321fd25
010d00201ad3015d3518d351ad301ad3515d3518d351ad301fd301ad351dd3518d301fd351cd3221d3518d3022d301dd3521d351dd301fd311ad321dd321fd3021d301cd351fd3221d3224d3221d3722d371dd37
010d002024d3226d3226d321ad210ed2102d1200d0000d0021d3221d3200d0000d0018d3218d351dd321dd3521d3521d3224d3124d3200d0000d0024d3224d321fd311fd321fd001fd3521d3021d3222d3222d32
010d002024d3226d2226d2224d2029d3229d2028d2028d3024d3226d3226d3026d2018d2224d1229d1229d2229d3528d3226d3124d2226d2024d201fd1224d121fd211fd221fd002bd252bd102dd2230d1230d22
010d00200c0333160015625000000c0331562515625156250c0000c033096250c0000c0000c03315625000000c0333160015625000000c03315625156250c0330c00015625156251562515600156251562515625
010d00200c0333160015625000000c0331562515625156250c0000c033096250c0000c0000c03315625000000c0333160015625000000c0331562515625096250c00009625096250962715600096251562500000
010d00200c0333160015625000000c0333160015625000000c0330c000096250c0000c0000c03315625000000c0330000015625000000c0330000015625000000c0330c033156250c0330c0000c0331562500000
010d00200213502135021350213502130021350213502135021350213502135021350213502135021350213500135001350013500135001300013500135001350013500135001350013500135001350013500135
010d00200a1350a13516125161250a1300a13516125161150a1350a13516125161150a1350a135161251611507135071351312513115071300713507135071351310013120111101012011115101200e1150c125
010d00200a1350a13516125161150a1350a13516125161150a1350a13516125161150a1350a1351512513111131310e1211113513125141350e1251113514125151351112213132151321813218132181421a142
010d00200213502135021350213502130021320213502135021350213502135021350713507135051350513502135021350213502135021300213202135021350213502135021350213505135051350413504135
010d00200c1350c1350c1350c1550c1300c1350c1350c1350c1350c1350c1350c135111351113210135101320a1350a1350a1350a1350a1300a1350a1350a1350913509135091350913511135111350c1350c135
010d00000213502135021350213502135021350513505135021350213502135021350213502135071350713502135021350213502135021350213505135051350010000100001350013001135011320113201132
010d00000213502135021350213502135021350513505135021350213502135021350213502135071350713502135021350213502135021350213505135051350010007130081320913209132091320913209132
__music__
01 1a211244
00 1a221344
00 1b1c1444
00 1b1d1544
00 1b1c1444
00 1b1e1644
00 1b1f1744
02 1b201844
01 1b1c4344
00 1b1d4344
00 1b1c4344
00 1b1e4344
00 1b1f5744
02 1b205844

