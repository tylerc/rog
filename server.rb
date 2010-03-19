require 'rubygems'
require 'sinatra'
require 'digest/sha1'

$salt = rand
$ids = {}
$num = 0
$rooms = {
		0 => {	:width => 400, 
				:height => 320, 
				:doors => { [100,0,200,0] => 1} },
		1 => {	:width => 320,
				:height => 320,
				:doors => { [100,320,200,320] => 0 } },
		}
$player_width = 20
$player_height = 20

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

get '/list_players' do
	cleanup_timeouts
	hash = {}
	$ids.each_value do |val|
		hash[val[:num]] = [val[:x], val[:y], val[:color], val[:name]]
	end
	hash.to_s
end

get '/add_player/?' do
	id = Digest::SHA1.hexdigest(($num + $salt).to_s)
	$ids[id] = {:x => rand($rooms[0][:width]-40),
				:y => rand($rooms[0][:height]-40),
				:color => [@r.to_i,@g.to_i,@b.to_i],
				:last_conn => Time.now,
				:name => @name,
				:num => $num,
				:room => 0}
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
	else
		@player = $ids[@id]
		pass
	end
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

get '/set_x/:x' do
	@x = params[:x]
	unless @x == nil
		@player[:x] = @x.to_i
		@player[:x] = 0 if @x.to_i < 0
		room = @player[:room]
		@player[:x] = $rooms[room][:width]-$player_width if @x.to_i > $rooms[room][:width]-$player_width
		return @player[:x].to_s
	end
end

get '/set_y/:y' do
	@y = params[:y]
	unless @y == nil
		@player[:y] = @y.to_i
		@player[:y] = 0 if @y.to_i < 0
		room = @player[:room]
		@player[:y] = $rooms[room][:height]-$player_height if @y.to_i > $rooms[room][:height]-$player_height
		return @player[:y].to_s
	end
end

get '/room/?' do
	return $rooms[@player[:room]].to_s
end

get '/change_room/:room/?' do
	@room = params[:room]
	unless params[:room] == nil
		@player[:room] = @room.to_i
	end
end

get '/update/game' do
	File.read("game.rb")
end

get '/update/server' do
	File.read('server.rb')
end

get '/update/engine' do
	File.read('engine.rb')
end
