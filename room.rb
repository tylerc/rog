class Rooms
	attr_accessor :num, :rooms
	
	def initialize
		@rooms = {}
		@num = 0
	end
	
	def create_room branch=nil, width=nil, height=nil
		width ||= rand(540)+100
		height ||= rand(380)+100
		@rooms[@num] = {
			:width => width,
			:height => height,
			:doors => {},
			:has_doors_on => [],
			:num => @num,
			:branch => branch,
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
		
		room1[:pos] = [0,0] if room1[:pos] == nil
		
		case side
			when :top
				x = rand(room1[:width]-100).to_i
				x2 = rand(room2[:width]-100).to_i
				door1 = [x,0,x+100,2]
				door2 = [x2,room2[:height]-2,x2+100,room2[:height]]
				spawn1 = [door2[0]+50-10,room2[:height]-30]
				spawn2 = [door1[0]+50-10,10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:top]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:bottom]
				room2[:pos] = [room1[:pos][0],room1[:pos][1]-1]
			when :right
				y = rand(room1[:height]-100).to_i
				y2 = rand(room2[:height]-100).to_i
				door1 = [room1[:width]-2,y,room1[:width],y+100]
				door2 = [0,y2,2,y2+100]
				spawn1 = [10,door2[1]+50-10]
				spawn2 = [room1[:width]-30,door1[1]+50-10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:right]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:left]
				room2[:pos] = [room1[:pos][0]+1,room1[:pos][1]]
			when :bottom
				x = rand(room1[:width]-100).to_i
				x2 = rand(room2[:width]-100).to_i
				door1 = [x,room1[:height]-2,x+100,room1[:height]]
				door2 = [x2,0,x2+100,2]
				spawn1 = [door2[0]+50-10,10]
				spawn2 = [door1[0]+50-10,room1[:height]-30]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:bottom]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:top]
				room2[:pos] = [room1[:pos][0],room1[:pos][1]+1]
			when :left
				y = rand(room1[:height]-100).to_i
				y2 = rand(room2[:height]-100).to_i
				door1 = [0,y,2,y+100]
				door2 = [room2[:width]-2,y2,room2[:width],y2+100]
				spawn1 = [room2[:width]-30,door2[1]+50-10]
				spawn2 = [10,door1[1]+50-10]
				room1[:doors][room2[:num]] = [door1,spawn1]
				room1[:has_doors_on] += [:left]
				room2[:doors][room1[:num]] = [door2,spawn2]
				room2[:has_doors_on] += [:right]
				room2[:pos] = [room1[:pos][0]-1,room1[:pos][1]]
		end
	end
	
	def export
		return @rooms
	end
end

def create_dungeon
	dungeon = Rooms.new
	# Create main branch
	20.times do |i|
		dungeon.create_room(:main)
		if i != 0
			dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
		end
	end
	dungeon.rooms[19][:last] = true
	
	# Walk initial branch, add offshoots
	20.times do |i|
		if rand(3) == 0
			room = dungeon.create_room(:offshoot)
			dungeon.add_connection(dungeon.rooms[i], room)
		end
	end
	
	# Walk initial branch, add secondary branches
	branches = []
	rand(5).times do |i|
		branch = []
		room = dungeon.create_room("s#{i}".to_sym)
		dungeon.add_connection(dungeon.rooms[rand(20)], room)
		branch += [room]
		11.times do |j|
			room = dungeon.create_room("s#{i}".to_sym)
			dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
			branch += [room]
		end
		room[:last] = true
		branches += [branch]
	end
	
	branches.each do |branch|
		# Add offshoots to secondary branches
		branch.length.times do |i|
			if rand(3) == 0
				room = dungeon.create_room(:offshoot)
				dungeon.add_connection(branch[i], room)
			end
		end
		
		# Add tertiary branches to secondary branches
		branch.length.times do |i|
			if rand(4) == 0
				room = dungeon.create_room(:t)
				dungeon.add_connection(branch[i], room)
				5.times do |j|
					room = dungeon.create_room(:t)
					dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
				end
				room[:last] = true
			end
		end
	end
	
	dungeon.export
end

if __FILE__ == $0
	require 'pp'
	pp create_dungeon
end
