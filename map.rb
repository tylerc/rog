require 'engine'
include Engine

class Map < GameObject
	class Room < Box
		def initialize x, y, size, doors, depth
			super :width => size, :height => size, :x => x, :y => y, :depth => -depth
			@doors = doors
			draw_border
			draw_doors
		end
		
		def draw_doors
			@surface.draw_box_s([width/2,0],[width/2+1,height/2],[255,0,0]) if @doors.index(:top)
			@surface.draw_box_s([width/2,height/2],[width/2+1,height],[255,0,0]) if @doors.index(:bottom)
			@surface.draw_box_s([0,height/2],[width/2,height/2+1],[255,0,0]) if @doors.index(:left)
			@surface.draw_box_s([width/2,height/2],[width,height/2+1],[255,0,0]) if @doors.index(:right)
		end
		
		def draw_border
			@surface.draw_box([0,0],[@width-2,@height-2],[0,0,0])
		end
		
		def color= opt
			super
			draw_border
			draw_doors
		end
	end
	
	def initialize rooms
		total = rooms.keys.sort[-1]+1
		rows = {}
		cols = {}
		size = 15
		total.times do |i|
			if rows[rooms[i][:pos][1]] == nil
				rows[rooms[i][:pos][1]] = [rooms[i]]
			else
				rows[rooms[i][:pos][1]] += [rooms[i]]
			end
			
			if cols[rooms[i][:pos][0]] == nil
				cols[rooms[i][:pos][0]] = [rooms[i]]
			else
				cols[rooms[i][:pos][0]] += [rooms[i]]
			end
		end
		height = rows.keys.length * size
		width = cols.keys.length * size
		super :x => 0, :y => 0, :width => width, :height => height
		old_x = @x
		old_y = @y
		diff_x = center_x-old_x
		diff_y = center_y-old_y
		# Shift pos so everything is positive
		shift_rows = -rows.keys.sort[0]
		shift_cols = -cols.keys.sort[0]
		total.times do |i|
			rooms[i][:pos] = [rooms[i][:pos][0]+shift_cols,rooms[i][:pos][1]+shift_rows]
		end
		total.times do |i|
			r = Room.new rooms[i][:pos][0]*size+diff_x, rooms[i][:pos][1]*size+diff_y, size, rooms[i][:has_doors_on], i
			r.color = [0,255,0] if i == 0
			r.color = [255,200,100] if rooms[i][:last] and rooms[i][:branch] == :main
			r.color = [255, 100, 0] if rooms[i][:last] and rooms[i][:branch].to_s[0] == 's'
			r.color = [0, 200, 200] if rooms[i][:last] and rooms[i][:branch] == :t
		end
	end
end

class MapState < State
	def initialize surface
		super()
		@surface = surface
	end
	
	def setup
		Drawable.new :surface => @surface, :depth => -200
		Map.new(eval(safe_get("map/?id=#{$id}"))).center
		key_press(:m) do
			@@game.pop_state
		end
	end
end
