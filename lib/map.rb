require './lib/engine'
include Engine

class Map < GameObject
	class Room < Box
		def initialize x, y, size, doors, room_num, is_current_room
			super :width => size, :height => size, :x => x, :y => y, :depth => -room_num
			@is_current_room = is_current_room
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
			@surface.draw_box([0,0],[@width-2,@height-2],[0,0,0])# if !@is_current_room
			@surface.draw_box_s([3,3],[@width-5,@height-5],[0,0,255]) if @is_current_room
		end
		
		def color= opt
			super
			draw_border
			draw_doors
		end
	end
	
	def initialize rooms, current_room
		rows = {}
		cols = {}
		size = 15
		rooms.keys.each do |i|
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
		rooms.keys.each do |i|
			rooms[i][:pos] = [rooms[i][:pos][0]+shift_cols,rooms[i][:pos][1]+shift_rows]
		end
		rooms.keys.each do |i|
			is_current_room = false
			is_current_room = true if current_room == i
			r = Room.new rooms[i][:pos][0]*size+diff_x, rooms[i][:pos][1]*size+diff_y, size, rooms[i][:has_doors_on], i, is_current_room
			r.color = [0,255,0] if i == 0
			r.color = [255,200,100] if rooms[i][:last] and rooms[i][:branch] == :main
			r.color = [255, 100, 0] if rooms[i][:last] and rooms[i][:branch].to_s[0] == 's'
			r.color = [0, 200, 200] if rooms[i][:last] and rooms[i][:branch] == :t
		end
	end
end

class MapState < State
	def setup surface, room
		Drawable.new :surface => surface, :depth => -200
		map = Map.new(eval(safe_get("map/?id=#{$id}")),room)
		map.center
		backdrop = Box.new :x => map.x-10, :y => map.y-10, :width => map.width+20, :height => map.height+20, :depth => -199, :color => [255,0,0,100]
		key = Box.new :y => 10, :width => 345, :height => 70, :color => [255,0,0,100], :depth => -198
		key.center_x
		start = Box.new :x => key.x+10, :y => key.y+10, :color => [0,255,0]
		start_t = Text.new :x => start.x+start.width+10, :y => start.y-3, :text => "Start", :size => 16
		end_of_main = Box.new :x => start_t.x+start_t.width+10, :y => start.y, :color => [255,200,100]
		end_of_main_t = Text.new :x => end_of_main.x+end_of_main.width+10, :y => start_t.y, :text => "Main goal", :size => 16
		end_of_s = Box.new :x => end_of_main_t.x+end_of_main_t.width+10, :y => start.y, :color => [255, 100, 0]
		end_of_s_t = Text.new :x => end_of_s.x+end_of_s.width+10, :y => end_of_s.y-3, :text => "Secondary goal", :size => 16
		end_of_t = Box.new :x => start.x, :y => end_of_s.y+end_of_s.height+10, :color => [0,200,200]
		end_of_t_t = Text.new :x => start_t.x, :y => end_of_t.y-3, :text => "Tertiary goal", :size => 16
		yah = Box.new :x => end_of_t_t.x+end_of_t_t.width+10, :y => end_of_t.y, :color => [0,0,255]
		yah_t = Text.new :x => yah.x+yah.width+10, :y => end_of_t_t.y, :text => "You are here", :size => 16
		key_press(:m) do
			@@game.pop_state
		end
	end
end
