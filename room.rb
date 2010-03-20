=begin

Problems
========

Generate 100 rooms

1 initial branch ("path")
Connections up, down, left, right
Corresponding back connections

Multiple secondary branches

Possible creation steps
=======================

# Create initial branch (will not die)
	
# Continue intial branch
# Continue or kill secondary branch

# Create offshoot
# Create secondary branch

=end

class Rooms
	attr_accessor :num, :rooms
	
	def initialize
		@rooms = {}
		@num = 0
	end
	
	def create_room width=nil, height=nil
		width ||= rand(540)+100
		height ||= rand(380)+100
		@rooms[@num] = {
			:width => width,
			:height => height,
			:doors => {},
			:has_doors_on => [],
			:num => @num,
		}
		@num += 1
		return @rooms[@num-1]
	end
	
	def add_connection room1, room2, side=nil
		# Pick side
		if side == nil
			sides = [:top, :right, :bottom, :left]
			room1[:has_doors_on].each do |part|
				sides.delete_if { |value| value == part }
			end
			side = sides[rand(sides.length)]
		end
		
		case side
			when :top
				x = rand(room1[:width]-100)
				x2 = rand(room2[:width]-100)
				door1 = [x,0,x+100,2]
				door2 = [x2,room2[:height]-2,x2+100,room2[:height]]
				spawn1 = [door2[0]+50-10,room2[:height]-30]
				spawn2 = [door1[0]+50-10,10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:top]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:bottom]
			when :right
				y = rand(room1[:height]-100)
				y2 = rand(room2[:height]-100)
				door1 = [room1[:width]-2,y,room1[:width],y+100]
				door2 = [0,y2,2,y2+100]
				spawn1 = [10,door2[1]+50-10]
				spawn2 = [room1[:width]-30,door1[1]+50-10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:right]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:left]
			when :bottom
				x = rand(room1[:width]-100)
				x2 = rand(room2[:width]-100)
				door1 = [x,room1[:height]-2,x+100,room1[:height]]
				door2 = [x2,0,x2+100,2]
				spawn1 = [door2[0]+50-10,10]
				spawn2 = [door1[0]+50-10,room1[:height]-30]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:bottom]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:top]
			when :left
				y = rand(room1[:height]-100)
				y2 = rand(room2[:height]-100)
				door1 = [0,y,2,y+100]
				door2 = [room2[:width]-2,y2,room2[:width],y2+100]
				spawn1 = [room2[:width]-30,door2[1]+50-10]
				spawn2 = [10,door1[1]+50-10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:left]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:right]
		end
	end
	
	def export
		return @rooms
	end
end

def create_dungeon
	dungeon = Rooms.new
	20.times do |i|
		dungeon.create_room
		if i != 0
			dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
		end
	end
	dungeon.export
end

if __FILE__ == $0
	require 'pp'
	pp create_dungeon
end
