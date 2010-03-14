require 'rubygems'
require 'rubygame'
require 'httparty'
require 'engine'
include Engine
include Rubygame::Events

#$ip = "10.240.2.67:4567"
$ip = "localhost:4567"
#$ip = "localhost:9393"

def safe_get url
	begin
		HTTParty.get("http://#{$ip}/" + url)
	rescue Errno::EADDRINUSE
		puts "FAIL, unknown reason"
	rescue Errno::ECONNREFUSED
		puts "Connection refused"
	end
end

class Player < GameObject
	def initialize name, color
		super :width => 10, :height => 10
		@color = color
		@name = name
		@id = safe_get "add_player/?r=#{@color[0]}&g=#{@color[1]}&b=#{@color[2]}&name=#{@name}"
		@x = safe_get("x/?id=#{@id}").to_i
		@y = safe_get("y/?id=#{@id}").to_i
		
		while_key_pressed(:down) do
			@y += 5
			update_y
		end
		while_key_pressed(:up) do
			@y -= 5
			update_y
		end
		while_key_pressed(:right) do
			@x += 5
			update_x
		end
		while_key_pressed(:left) do
			@x -= 5
			update_x
		end
	end
	
	def update_x
		safe_get "set_x/#{@x}?id=#{@id}"
	end
	
	def update_y
		safe_get "set_y/#{@y}?id=#{@id}"
	end
	
	def update
		safe_get "alive/?id=#{@id}"
		#x = safe_get("x/?id=#{@id}").to_i
		#y = safe_get("y/?id=#{@id}").to_i
		#@x = x unless x == nil
		#@y = y unless y == nil
	end
end

class PlayerManager < GameObject
	class NameText < Text
		def initialize text, num, manager
			super :text => text, :size => 12
			@num = num
			@manager = manager
		end
		
		def update
			unless @manager.players[@num] == nil
				@x = @manager.players[@num][0]
				@y = @manager.players[@num][1]-20
			else
				@life = 0
			end
		end
	end
	
	def initialize
		super
		begin
			pl = eval safe_get("list_players")
			@players = pl if pl != nil
			@players_inst = {}
		rescue
			puts "Fail"
		end
	end
	
	def update
		begin
			pl = eval safe_get("list_players")
			@players = pl if pl != nil
			@players.each do |key,val|
				if @players_inst[key] == nil
					@players_inst[key] = NameText.new val[3], key, self
				end
			end
		rescue
			puts "Fail"
		end
	end
	
	def draw
		@players.each_value do |x,y,color,name|
			@@screen.draw_box_s([x,y],[x+20,y+20], color)
		end
	end
	
	def players
		@players
	end
end

class InGame < State
	def initialize name, color
		super()
		@name = name
		@color = color
	end
	
	def setup
		PlayerManager.new
		Player.new @name, @color
		key_release(:u) do
			game = safe_get("update/game")
			server = safe_get("update/server")
			engine = safe_get("update/engine")
			File.open("game.rb", "w") { |f| f.puts game }
			File.open("server.rb", "w") { |f| f.puts server }
			File.open("engine.rb", "w") { |f| f.puts engine }
			Rubygame.quit
			exec("ruby.exe game.rb")
		end
	end
end

class Setup < State
	class NameInput < Text
		class FlashingLine < Box
			def initialize x, y, obj
				super :width => 1, :height => 20, :x => x, :y => y
				@draw = 0
				@obj = obj
			end
			
			def update
				@draw += 1
				@draw = 0 if @draw >= 30
				@x = @obj.x + @obj.width
			end
			
			def draw
				super if @draw >= 10
			end
		end
		
		def initialize
			super :text => "", :x => 200, :y => 100
			
			t = Text.new :text => "Name: ", :y => @y
			t.x = @x-t.width
			FlashingLine.new @x, @y+5, self
			
			key_release(:left_shift) do
				@shift = false
			end
			key_release(:right_shift) do
				@shift = false
			end
			event(KeyPressed) do |ev|
				@shift = true if ev.key == :left_shift or ev.key == :right_shift
				
				unless ev.key == :backspace or ev.key.to_s.length > 1
					@text += ev.key if !@shift
					@text += ev.key.upcase if @shift
				end
				@text += " " if ev.key == :space
				@text = @text[0..-2] if ev.key == :backspace

				rerender_text
			end
		end
	end
	
	class SlidyThing < Box
		def initialize slider
			height = slider.height+4
			@start_x = slider.x-height/2
			super :x => @start_x+255, :y => slider.y-2, :height => height, :width => height
			
			@slider = slider
			@pressed = false
			
			mouse_pressed_on do
				@pressed = true
			end
			mouse_release do
				@pressed = false
			end
			mouse_motion do |ev|
				if @pressed
					@x += ev.rel[0]
					@x = @slider.x-@width/2 if @x < @slider.x-@width/2
					@x = @slider.x+@slider.width-@width/2 if @x > @slider.x+@slider.width-@width/2
					update_val
				end
			end
		end
		
		def update_val
			@slider.val = @x-@start_x
		end
	end
	
	class Slider < Box
		def initialize x, y
			super :x => x, :y => y, :width => 255, :height => 10, :color => [0,0,0]
			@surface.draw_box([0,0],[@width-2,@height-2],[255,255,255])
			SlidyThing.new self
		end
		
		def val= a
			method(:color=).call [a,0,0]
		end
		
		def color= opt
			super opt
			@surface.draw_box([0,0],[@width-2,@height-2],[255,255,255])
		end
	end
	
	class RGB < Box
		def initialize red, green, blue
			super :x => 450, :y => 165, :width => 100, :height => 100
			@red = red
			@green = green
			@blue = blue
		end
		
		def update
			method(:color=).call [@red.color[0],@green.color[1],@blue.color[2]]
		end
	end
	
	class StartButton < Drawable
		def initialize name, rgb
			surface = Rubygame::Surface.new [80, 30]
			super :y => 350, :width => surface.width, :height => surface.height, :surface => surface
			center_x
			@surface.draw_box([1,1],[@width-2,@height-2],[255,255,255])
			@orig_surface = @surface
			@hover_surface = Rubygame::Surface.new [@width, @height]
			@hover_surface.fill [255,255,255]
			@text = Text.new :text => "Start", :x => @x+20, :y => @y
			
			@name = name
			@rgb = rgb
			
			mouse_hovering_over do
				@surface = @hover_surface
				@text.color = [0,0,0]
			end
			
			mouse_not_hovering_over do
				@surface = @orig_surface
				@text.color = [255,255,255]
			end
			
			mouse_pressed_on do
				@@game.switch_state InGame.new @name.text, @rgb.color
			end
		end
	end
	
	def setup
		name = NameInput.new
		Text.new :x => 135, :y => 150, :text => "Color:"
		red = Slider.new 135, 190
		green = Slider.new 135, 210
		def green.val= a
			method(:color=).call [0,a,0]
		end
		blue = Slider.new 135, 230
		def blue.val= a
			method(:color=).call [0,0,a]
		end
		[red,green,blue].each do |obj|
			obj.val = 255
		end
		rgb = RGB.new red, green, blue
		StartButton.new name, rgb
	end
end

game = Game.new
game.event(QuitRequested) do
	exit
end
game.switch_state Setup.new
game.run
