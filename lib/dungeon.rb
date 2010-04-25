#!/usr/bin/env ruby
class Rooms
	attr_accessor :num, :rooms, :poses, :fail
	
	def initialize
		@rooms = {}
		@num = 0
		@poses = [[0,0]]
		@fail = false
	end
	
	def create_room branch=nil, width=nil, height=nil
		width ||= rand(1000)+100
		height ||= rand(1000)+100
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
		room1[:pos] = [0,0] if room1[:pos] == nil
		
		# Pick side
		if side == nil
			sides = dirs_available(room1)
			if sides == []
				$stderr.puts "Fail creating connection between:"
				$stderr.puts "#{room1[:num]} of branch #{room1[:branch]}"
				$stderr.puts "#{room2[:num]} of branch #{room2[:branch]}"
				@fail = true
				return false
			end
			side = sides[rand(sides.length)]
		end
		
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
		@poses += [room2[:pos]]
	end
	
	def dirs_available room
		doors = [:top, :right, :bottom, :left]
		room[:has_doors_on].each do |door|
			doors.delete door
		end
		doors.delete :top if @poses.index([room[:pos][0],room[:pos][1]-1]) != nil
		doors.delete :right if @poses.index([room[:pos][0]+1,room[:pos][1]]) != nil
		doors.delete :bottom if @poses.index([room[:pos][0],room[:pos][1]+1]) != nil
		doors.delete :left if @poses.index([room[:pos][0]-1,room[:pos][1]]) != nil
		return doors
	end
	
	def rooms_available
		rooms = @rooms.clone
		rooms.delete_if { |key,value| value[:has_doors_on].length == 4 }
		rooms.delete_if do |key,value|
			doors = dirs_available value
			doors.length == 0
		end
		return rooms
	end
	
	def export
		return @rooms
	end
end

def create_dungeon
	dungeon = Rooms.new
	loop do
		dungeon = Rooms.new
		# Create main branch
		20.times do |i|
			dungeon.create_room(:main)
			if i != 0
				dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
			end
		end
		redo if dungeon.fail
		dungeon.rooms[19][:last] = true
		
		# Walk initial branch, add secondary branches
		branches = []
		rand(5).times do |i|
			branch = []
			rooms = dungeon.rooms_available
			room = dungeon.create_room("s#{i}".to_sym)
			num = rooms.keys[rand(rooms.keys.length)]
			room2 = rooms[num]
			dungeon.add_connection(room2, room)
			branch += [room]
			11.times do |j|
				break if dungeon.dirs_available(dungeon.rooms[dungeon.num-1]).length == 0
				room = dungeon.create_room("s#{i}".to_sym)
				dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
				branch += [room]
			end
			room[:last] = true
			branches += [branch]
		end

		branches.each do |branch|
			# Add tertiary branches to secondary branches
			branch.length.times do |i|
				if rand(4) == 0
					next if dungeon.rooms_available[(branch[i][:num])] == nil 
					room = dungeon.create_room(:t)
					dungeon.add_connection(branch[i], room)
					5.times do |j|
						break if dungeon.dirs_available(dungeon.rooms[dungeon.num-1]).length == 0
						room = dungeon.create_room(:t)
						dungeon.add_connection(dungeon.rooms[dungeon.num-2],dungeon.rooms[dungeon.num-1])
					end
					room[:last] = true
				end
			end
		end
		
		# Walk dungeon, add offshoots
		20.times do |i|
			if rand(3) == 0
				rooms = dungeon.rooms_available
				num = rooms.keys[rand(rooms.keys.length)]
				room = rooms[num]
				room2 = dungeon.create_room(:offshoot)	
				dungeon.add_connection(room, room2)
			end
		end
		
		# This shouln't happen!
		if dungeon.fail
			$stderr.puts "Uh oh, fail in dungeon generator"
			redo
		elsif dungeon.num < 100
			redo
		else
			raise StopIteration
		end
	end
	dungeon.export
end

if __FILE__ == $0
	require 'pp'
	pp create_dungeon
end
