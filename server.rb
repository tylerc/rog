require 'rubygems'
require 'sinatra'
require 'digest/sha1'

$salt = rand
$ids = {}
$num = 0
$rooms = {0 => {:width => 320, :height => 320}}
$player_width = 20
$player_height = 20

helpers do
	def cleanup_timeouts
		$ids.delete_if { |id,val| Time.now - val[:last_conn] > 5  }
	end
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
	$ids[id] = {:x => rand(280), :y => rand(280), :color => [params[:r].to_i,params[:g].to_i,params[:b].to_i], :last_conn => Time.now, :name => params[:name], :num => $num, :room => 0}
	$num += 1
	id
end

get '*/?' do
	if params[:id] == nil
		return "No id"
	else
		pass
	end
end

get '/num/?' do
	$ids[params[:id]][:num].to_s
end

get '/alive/?' do
	$ids[params[:id]][:last_conn] = Time.now
end

get '/x/?' do
	$ids[params[:id]][:x].to_s
end

get '/y/?' do
	$ids[params[:id]][:y].to_s
end

get '/set_x/:x' do
	unless params[:x] == nil
		$ids[params[:id]][:x] = params[:x].to_i
		$ids[params[:id]][:x] = 0 if params[:x].to_i < 0
		room = $ids[params[:id]][:room]
		$ids[params[:id]][:x] = $rooms[room][:width]-$player_width if params[:x].to_i > $rooms[room][:width]-$player_width
		return $ids[params[:id]][:x].to_s
	end
end

get '/set_y/:y' do
	unless params[:y] == nil
		$ids[params[:id]][:y] = params[:y].to_i
		$ids[params[:id]][:y] = 0 if params[:y].to_i < 0
		room = $ids[params[:id]][:room]
		$ids[params[:id]][:y] = $rooms[room][:height]-$player_height if params[:y].to_i > $rooms[room][:height]-$player_height
		return $ids[params[:id]][:y].to_s
	end
end

get '/list_ids/?' do
  if params[:pass] == "awesome"
  	$ids.keys.join "<br/>\n"
  else
  	redirect "/404"
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
