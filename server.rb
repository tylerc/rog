require 'rubygems'
require 'sinatra'
require 'digest/sha1'

$salt = rand
$ids = {}
$num = 0

helpers do
	def cleanup_timeouts
		$ids.delete_if { |id,val| Time.now - val[:last_conn] > 5  }
	end
end

get '/add_player/?' do
	id = Digest::SHA1.hexdigest(($num + $salt).to_s)
	$ids[id] = {:x => rand(640), :y => rand(480), :color => [params[:r].to_i,params[:g].to_i,params[:b].to_i], :last_conn => Time.now, :name => params[:name], :num => $num}
	$num += 1
	id
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

get '/list_players' do
	cleanup_timeouts
	hash = {}
	$ids.each_value do |val|
		hash[val[:num]] = [val[:x], val[:y], val[:color], val[:name]]
	end
	hash.to_s
end	

get '/set_x/:x' do
	if params[:id] == nil
		return "No id"
	else
		unless params[:x] == nil
			$ids[params[:id]][:x] = params[:x].to_i
		end
	end
end

get '/set_y/:y' do
	if params[:id] == nil
		return "No id"
	else
		unless params[:y] == nil
			$ids[params[:id]][:y] = params[:y].to_i
		end
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
