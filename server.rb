#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'digest/sha1'

require 'lib/dungeon'

$salt = rand
$ids = {}
$num = 0
$rooms = create_dungeon

helpers do
	def cleanup_timeouts
		$ids.delete_if { |id,val| Time.now - val[:last_conn] > 5  }
	end
	
	def transform_params params
		params.each do |param|
			instance_variable_set("@" + param[0],param[1])
		end
	end
end

before do
	transform_params params
end

get '/add_player/?' do
	id = Digest::SHA1.hexdigest(($num + $salt).to_s)
	$ids[id] = {:x => rand($rooms[0][:width]-40),
				:y => rand($rooms[0][:height]-40),
				:color => [@r.to_i,@g.to_i,@b.to_i],
				:last_conn => Time.now,
				:name => @name,
				:num => $num,
				:room => 0,
				:width => 20,
				:height => 20,
				:rooms_visted => [0],
				:angle => 0,
				}
	$num += 1
	id
end

get '/list_ids/?' do
  if @pass == "awesome"
  	$ids.keys.join "<br/>\n"
  else
  	redirect "/404"
  end
end

get '*/?' do
	if @id == nil
		return "No id"
	elsif $ids[@id] == nil
		return "Incorrect id"
	else
		@player = $ids[@id]
		pass
	end
end

get '/list_players/?' do
	cleanup_timeouts
	hash = {}
	$ids.each_value do |val|
		hash[val[:num]] = [val[:x], val[:y], val[:angle], val[:color], val[:name]] unless @player[:room] != val[:room]
	end
	hash[-1] = [$rooms[@player[:room]][:width]/2-10, $rooms[@player[:room]][:height]/2-10, 0, [255,200,100], ""] if $rooms[@player[:room]][:last]
	hash.to_s
end

get '/num/?' do
	@player[:num].to_s
end

get '/alive/?' do
	@player[:last_conn] = Time.now
end

get '/x/?' do
	@player[:x].to_s
end

get '/y/?' do
	@player[:y].to_s
end

get '/update_player' do
	limit = 5
	unless @x == nil or @y == nil or @angle == nil
		@x = @x.to_i
		@x = limit if @x > limit
		@x = -limit if @x < -limit
		@player[:x] = @player[:x]+@x
		@player[:x] = 0 if @player[:x] < 0
		room = @player[:room]
		@player[:x] = $rooms[room][:width]-@player[:width] if @player[:x] > $rooms[room][:width]-@player[:width]
		
		@y = @y.to_i
		@y = limit if @y > limit
		@y = -limit if @y < -limit
		@player[:y] = @player[:y]+@y
		@player[:y] = 0 if @player[:y] < 0
		room = @player[:room]
		@player[:y] = $rooms[room][:height]-@player[:height] if @player[:y] > $rooms[room][:height]-@player[:height]
		
		@player[:angle] = @angle.to_i
		return "#{@player[:x]},#{@player[:y]},#{@player[:angle]}"
	end
	""
end

get '/room/?' do
	return $rooms[@player[:room]].to_s
end

get '/change_room/:room/?' do
	@room = params[:room]
	unless params[:room] == nil
		@player[:x], @player[:y] = $rooms[@player[:room]][:doors][@room.to_i][1]
		@player[:room] = @room.to_i
		@player[:rooms_visted] += [@room.to_i]
	end
	""
end

get '/map/?' do
	visted = {}
	@player[:rooms_visted].each do |room|
		visted[room] = $rooms[room]
	end
	return visted.to_s
end
