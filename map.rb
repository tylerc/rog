require 'rubygems'
require 'rubygame'
require 'engine'
require 'pp'
include Engine
include Rubygame::Events

game = Game.new
game.event(QuitRequested) do
	exit
end

class Map < GameObject
	class Room < Box
		def initialize x, y, doors
			super :width => 30, :height => 30, :x => x, :y => y
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
		height = rows.keys.length * 10
		width = cols.keys.length * 10
		p rows.keys.sort
		p cols.keys.sort
		puts width
		puts height
		# Shift pos so everything is positive
		shift_rows = -rows.keys.sort[0]
		shift_cols = -cols.keys.sort[0]
		p shift_rows
		p shift_cols
		total.times do |i|
			rooms[i][:pos] = [rooms[i][:pos][0]+shift_cols,rooms[i][:pos][1]+shift_rows]
		end
		total.times do |i|
			r = Room.new rooms[i][:pos][0]*30, rooms[i][:pos][1]*30, rooms[i][:has_doors_on]
			r.color = [0,255,0] if i == 0
			r.color = [255,200,100] if rooms[i][:last]
		end
		super :x => 0, :y => 0, :width => width, :height => height
	end
end

rooms = eval File.read('rooms.txt')

Map.new rooms

game.run
