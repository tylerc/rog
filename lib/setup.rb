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
			
			event(KeyPressed) do |ev|
				unless ev.key == :backspace or (ev.key.to_s.length > 1 and ev.key.to_s[0..-2] != "number_")
					key = ev.key.to_s
					key = key[-1] if key[0..-2] == "number_"
					key.upcase! if ev.modifiers.include?(:left_shift) or ev.modifiers.include?(:right_shift)
					@text += key
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
			
			start_game = Proc.new do
				@@game.switch_state InGame.new @name.text, @rgb.color
			end
			
			mouse_pressed_on { start_game.call }
			key_press(:return) { start_game.call }
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
