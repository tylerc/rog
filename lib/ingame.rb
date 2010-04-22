class Player < GameObject
	attr_reader :num
	attr_accessor :sx, :sy
	
	def initialize name, color, room
		super :width => 20, :height => 20
		@room = room
		@num = safe_get("num/?id=#{$id}").to_i
		@sx = safe_get("x/?id=#{$id}").to_i
		@sy = safe_get("y/?id=#{$id}").to_i
		@x = @sx+@room.x
		@y = @sy+@room.y
		@mouse_goat = ScapeGoat.new(:x => 0, :y => 0)
		@angle = 0
		mouse_motion do |ev|
			@mouse_goat.x = ev.pos[0]
			@mouse_goat.y = ev.pos[1]
			find_slope @mouse_goat
			update_player 0, 0, @angle
		end
		
		while_key_pressed(:w) do
			x = x_offset(@angle, 5).to_i
			y = y_offset(@angle, 5).to_i
			update_player x, y, @angle
		end
	end
	
	def find_slope target
		rise = @y - (target.y+target.height/2).to_f
		run = @x - (target.x+target.width/2).to_f
		run = 1 if run == 0
		dx = target.x - @x
		dy = target.y - @y
		radians = Math.atan2(dx, dy)
		@angle = -radians * 180 / Math::PI + 180
	end
	
	def update_player x=0, y=0, angle=@angle
		vals = safe_get("update_player?x=#{x}&y=#{y}&angle=#{angle}&id=#{$id}")
		x,y,angle = vals.split ','
		@x = x.to_i+@room.x
		@y = y.to_i+@room.y
		@angle = angle.to_i
	end
	
	def update
		safe_get "alive/?id=#{$id}"
	end
	
	#def draw
		#@@screen.draw_box([@x,@y],[@x+@width,@y+@height],[0,255,0])
	#end
end

class PlayerManager < GameObject
	attr_reader :player
	class NameText < Text
		def initialize name, player, room
			super :text => name, :size => 12, :depth => 0.2
			@room = room
			@player = player
		end
		
		def update
			@x = @player.x+10-@width/2
			@y = @player.y-20
		end
	end
	
	class GhostPlayer < Drawable
		def initialize x, y, angle, color, name, num, manager, room
			super :x => x, :y => y, :width => 20, :height => 20, :angle => angle, :depth => 0.1
			@num = num
			@name = name
			@manager = manager
			@room = room
			@text = NameText.new name, self, room
			@surface.fill color
		end
		
		def update
			unless @manager.players[@num] == nil
				@x = @manager.players[@num][0]+@room.x
				@y = @manager.players[@num][1]+@room.y
				@angle = @manager.players[@num][2]
			else
				@life = 0
			end
		end
		
		def destroy
			@text.life = 0
		end
	end
	
	
	
	def initialize player, room
		super()
		pl = eval safe_get("list_players?id=#{$id}")
		@players = pl if pl != nil
		@players_inst = {}
		@player = player
		@player_num = player.num
		@room = room
	end
	
	def update
		get = safe_get("list_players?id=#{$id}")
		unless get == nil
			pl = eval get
			@players = pl if pl != nil
			@players.each do |key,val|
				if @players_inst[key] == nil or (@players_inst[key] != nil and @players_inst[key].life == 0)
					@players_inst[key] = GhostPlayer.new val[0], val[1], val[2], val[3], val[4], key, self, @room
				end
			end
		end
	end
	
	def players
		@players
	end
end

class Room < Drawable
	attr_reader :room
	class Door < Drawable
		def initialize pos, to, room
			@rect = pos[0]
			@player_pos = pos[1]
			@to = to
			@room = room
			surface = Rubygame::Surface.new [@rect[2]-@rect[0],@rect[3]-@rect[1]]
			surface.fill [255,0,0]
			super :surface => surface, :x => @rect[0]+@room.x, :y => @rect[1]+@room.y
		end
		
		def draw
			@surface.blit @@screen, [@x,@y]
		end
		
		def collision obj
			if obj.class == Player
				safe_get "change_room/#{@to}?id=#{$id}"
				@room.change
				obj.update_player
				@@game.current_state.objs.delete_if { |obj| obj.class == Door }
			end
		end
	end
	
	def initialize	
		super(:depth => -1)
		change
	end
	
	def change
		@room = eval safe_get("room?id=#{$id}")
		@width = @room[:width]
		@height = @room[:height]
		center
		@surface = Rubygame::Surface.new [@width,@height]
		@surface.draw_box([0,0],[surface.width-2,surface.height-2],[255,255,255])
		@room[:doors].each do |to, pos|
			Door.new pos, to, self
		end
	end
end

class InGame < State
	def initialize name, color
		super()
		@name = name
		@color = color
	end
	
	def setup
		$id = safe_get "add_player/?r=#{@color[0]}&g=#{@color[1]}&b=#{@color[2]}&name=#{@name.gsub(' ', '+')}"
		room = Room.new
		player = Player.new @name, @color, room
		manager = PlayerManager.new player, room
		key_press(:m) do
			@@game.push_state(MapState.new(@@screen.convert,room.room[:num]))
		end
	end
end
