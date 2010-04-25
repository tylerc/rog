require 'rubygame'
Rubygame::TTF.setup

# Is a nice (hopefully) wrapper around Rubygame that should help
# make game development even easier!
#
# You can use it's API by using: require 'engine' in your code.
#
# You can see an example of its functionality in action by running:
#  ruby -rubygems engine_example.rb
#
# Notes about how the code looks:
# * the variable obj is used as shorthand when we iterate over game objects
# * the variable s is used for settings that have the defaults applied to them
#
# There aren't really any other code-style guides, we'll be pretty happy with
# what ever you feel like naming your variables
module Engine
	
	#--
	# We define this here so that we can have the actual module on the
	# bottom of the file. Dammit Ruby, why!?
	module EventOwner
	end
	
	#--
	# same deal as EventOwner...
	module Defer
	end

	# This is the Game class, it contains everything you need
	# to create your game
	#
	# For events (key_press, mouse_motion, etc.):
	# Takes:
	# * The key/button pressed (Rubygame::K_KEY)
	# * The code to run 
	#   * either: lambda { |pos| # code here } 
	#   * or: method(:name_of_method)
	# * The owner of the event. 
	#   * If it is the Game object, it is never destroyed (until the game ends)
	#   * If it is a State object, it is only active when the state is
	#   * If it is a GameObject, it is destroyed when the GameObject is destroyed
	class Game
		include EventOwner
		# The screen we're drawing to
		attr_reader :screen_surf
		# The state the game is in/using
		attr_reader :current_state
		# Game's FPS
		attr_reader :fps
		# Event queue
		attr_reader :queue
		# Game Events
		attr_accessor :events
		# Seconds since last update
		attr_reader :tick
		
		# Creates a new game
		#
		# Parameters are in hash format (i.e. Game.new(:width => 640, :height =. 480) )
		#
		# Takes:
		# * Window Width (:width)
		# * Window Height (:height)
		# * Flags (:flags) (best left at defaults)
		# * Window Title (:title)
		# * Desired Frames per Second (:fps)
		def initialize(settings={:width => 640, :height => 480, :flags => [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF], :title => "Game Engine Window", :fps => 30})
			s = 		{:width => 640, :height => 480, :flags => [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF], :title => "Game Engine Window", :fps => 30}.merge(settings)
			@fps = s[:fps]
			@screen = Rubygame::Screen.new [s[:width], s[:height]], 0, s[:flags]
			@screen.title = s[:title]
			@screen_surf = Rubygame::Surface.new [@screen.width, @screen.height]
		
			@queue = Rubygame::EventQueue.new
			@queue.enable_new_style_events
			@clock = Rubygame::Clock.new
			@clock.target_framerate = s[:fps]
			@clock.enable_tick_events
			@clock.calibrate
			@tick = 0.0
			
			GameObject.add_to_game self
			State.add_to_game self
			EventOwner.add_to_game self
			
			@current_state = State.new
			@states = []
			@objs2 = []
			@events = []
			@state_buffer = nil
		end
		
		# Adds objects to the game
		#
		# GameObjects do this for you
		#--
		# Adds the new objects to @objs2 so we don't add an object while iterating over it
		def add obj
			@objs2 += [obj] 
		end
		
		# Main Loop
		def run
			loop do
				update
				draw
				@tick = @clock.tick.seconds
			end
		end
		
		# * Cleans up objects + their events, if their life == 0
		# * Handles and delegates events to objects
		# * Runs each objects update function
		def update
			@current_state.objs.each do |obj|
				if obj.life <= 0
					obj.destroy
					@current_state.objs.delete obj
					@current_state.events.delete_if { |x| x.owner == obj }
				end
			end
			
			@current_state.objs.each do |obj|
				@current_state.objs[@current_state.objs.index(obj)+1..-1].each do |obj2|
					unless collision_between(obj, obj2)
						next
					end
					obj.collision obj2
					obj2.collision obj
				end
			end
		
			@queue.each do |ev|
				@events.each { |event| if ev.class == event.type ; event.call ev ; end }
				@current_state.events.each { |event| if ev.class == event.type ; event.call ev ; end }
			end
		
			@current_state.objs.each do |obj|
				obj.update
			end
			
			@current_state.update
			
			unless @objs2.empty?
				@current_state.objs += @objs2
				@current_state.objs.sort! { |a,b| (a.depth or 0) <=> (b.depth or 0) } # Sort by depth
				@objs2 = []
			end
			
			if @state_buffer != nil
				@state_buffer.call
				@state_buffer = nil
			end
		end
		
		# Draws the screen
		def draw
			@screen_surf.fill @current_state.bg_color
			
			@current_state.objs.each do |obj|
				obj.draw
			end
			
			@screen_surf.blit @screen, [0,0]
		
			@screen.flip
		end
		
		# Tell all the objs that the state is changing
		def notify_of_state_change
			@current_state.objs.each do |obj|
				obj.state_change
			end
		end
		
		# Switches the state and destroys the current state
		#
		# Takes a state class (initialized) as an argument
		def switch_state state
			@state_buffer = Proc.new do
				notify_of_state_change
				@objs2 = []
				@current_state = state
				@current_state.setup
				notify_of_state_change
			end
		end
		
		# Pops a state off the state stack and makes it the current state. (This destroys the current state)
		def pop_state	
			@state_buffer = Proc.new do
				notify_of_state_change
				@objs2 = []
				@current_state = @states.pop
				notify_of_state_change
			end
		end
		
		# Pushes a new state onto the state stack
		#
		# Takes a state class (initialized) as an argument
		def push_state state
			@state_buffer = Proc.new do
				notify_of_state_change
				@states.push @current_state
				@current_state = state
				@current_state.setup
				notify_of_state_change
			end
		end
		
		# Returns true if there is a collision
		# false is there isn't
		#
		# Works on Engine::GameObject instances
		def collision_between obj1, obj2
			if obj1.y + obj1.height < obj2.y ; return false ; end
			if obj1.y > obj2.y + obj2.height ; return false ; end
			if obj1.x + obj1.width < obj2.x ; return false ; end
			if obj1.x > obj2.x + obj2.width ; return false ; end
			return true
		end
	end
	
	# Almost all objects should inherit from this
	#
	# All GameObjects understand the concepts of:
	# * Life - when this reaches 0 the GameObject is deleted by the Engine
	# * x and y positions on the screen
	# * width and height - Used for collision detection
	# * Depth - What's drawn on top of what. Lower the number, the lower it's drawn. Default is zero
	#
	# Take a careful look at the settings GameObject provides,
	# nowhere will the documentation repeat the basic options, so
	# you have to remember them
	class GameObject
		include EventOwner
		include Defer
		attr_accessor :x, :y, :width, :height, :depth
		# When life reaches zero, it is destroyed by the game engine
		attr_accessor :life
		
		# Creates a new GameObject.
		#
		# Parameters are in hash format (i.e. GameObject.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * x position (:x)
		# * y position (:y)
		# * width (:width)
		# * height (:height)
		# * Life (:life)
		# * Depth (:depth)
		def initialize settings={:x => 0, :y => 0, :width => 0, :height => 0, :life => 1, :depth => 0}
			s = {:x => 0, :y => 0, :width => 0, :height => 0, :life => 1, :depth => 0}.merge! settings
			Util.hash_to_var(s, [:x, :y, :width, :height, :life, :depth], self)
			@@game.add self
		end
		
		# Object's logic goes here
		def update
		end
		
		# Called every frame, only draw in here, no game logic
		def draw
		end
		
		# Method run when object is destroyed	
		def destroy
		end
		
		# Gives GameObjects access to the Game object
		def self.add_to_game game
			@@game = game
			@@screen = game.screen_surf
		end
		
		# Method run when a collision occurs
		def collision obj
		end
		
		# returns the horizantal distance if you moved at that angle, for that distance
		def x_offset angle, distance
			distance * Math.sin(angle * Math::PI/180)
		end
		
		# returns the vertical distance if you moved at that angle, for that distance
		def y_offset angle, distance
			distance * Math.cos(angle * Math::PI/180) * -1
		end
		
		# Centers the object in the middle of the screen
		def center
			center_x
			center_y
		end
		
		# Centers along the x axis
		def center_x
			@x = @@screen.width/2-@width/2
		end
		
		# How far away a GameObject is from being
		# directly in the center of the screen on the x axis
		def center_x_diff
			x = @@screen.width/2-@width/2
			return x-@x
		end

		# How far away a GameObject is from being
		# directly in the center of the screen on the y axis
		def center_y_diff
			y = @@screen.height/2-@height/2
			return y-@y
		end
		
		# Centers along the y axis
		def center_y
			@y = @@screen.height/2-@height/2
		end
		
		# Find distance between two objects (a^2 + b^2 = c^2)
		def distance obj
			a = obj.x-@x
			b = obj.y-@y
			c = Math.sqrt(a**2 + b**2)	
		end
		
		# Check if self is on screen
		def on_screen?
			# A ScapeGoat the size of the screen, used in GameObject#on_screen?
			@@screen_goat ||= Engine::ScapeGoat.new(:width => @@screen.width, :height => @@screen.height)
			@@game.collision_between(self, @@screen_goat)
		end
		
		# Method called when @@game changes state
		def state_change
		end
	end
	
	# For when you need something that won't last long, but still looks like a GameObject
	#
	# (useful for certain collision-detection situations)
	class ScapeGoat < Engine::GameObject
		def initialize settings={:width => 1, :height => 1}
			s = {:width => 1, :height => 1}.merge!(settings)
			super(s)
		end
		
		def update
			@life = 0
		end
	end
	
	# A base class for all GameObjects that will be drawn
	#
	# Used internally by the Engine::Box class, the 
	# Engine::Image class, and the Engine::Text.
	#
	# Feel free to base your own classes on this as well!
	class Drawable < Engine::GameObject
		attr_accessor :surface, :angle, :zoom, :aa
		
		# Creates a new Drawable primitive
		#
		# Parameters are in hash format (i.e. Drawable.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * Rubygame::Surface (:surface)
		# If Drawable is to be rotated/zoomed:
		# * Angle (:rot_angle)
		# * Zoom (:zoom)
		# * Anti-Alias (:aa)
		def initialize settings={:angle => 0, :zoom => 1, :aa => true, :surface => Rubygame::Surface.new([20,20])}
			s = 				{:angle => 0, :zoom => 1, :aa => true, :surface => Rubygame::Surface.new([20,20])}.merge!(settings)
			s[:width] ||= s[:surface].width
			s[:height] ||= s[:surface].height
			super s
			Util.hash_to_var(s, [:surface, :zoom, :aa, :angle], self)
			@surface = @surface.to_display_alpha
			@real_width = @width
			@real_height = @height
		end
		
		def draw
			if @angle == 0
				@surface.rotozoom(@angle,@zoom,@aa).blit @@screen, [@x, @y]
				@real_width = @surface.width
				@real_height = @surface.height
			else
				surf = @surface.rotozoom(-@angle,@zoom,@aa)
				new_x = @x.to_f+@width/2-surf.width/2
				new_y = @y.to_f+@height/2-surf.height/2
				surf.blit @@screen, [new_x, new_y]
				@real_width, @real_height = surf.size
			end
		end
	end
	
	# A Simple 2D box class
	class Box < Engine::Drawable
		# Creates a new Box
		#
		# Parameters are in hash format (i.e. Box.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * Box Width (:width)
		# * Box Height (:height)
		#
		# Engine::Box inherits from Engine::Drawable 
		# check there to see more useful parameters...
		def initialize settings={:width => 20, :height => 20, :color => [255, 255, 255]}
			s = 		{:width => 20, :height => 20, :color => [255, 255, 255]}.merge!(settings)
			s[:surface] = Rubygame::Surface.new [s[:width], s[:height]]
			s[:surface] = s[:surface].to_display_alpha
			s[:surface].fill s[:color]
			super s
			@color = s[:color]
		end
		
		def color
			@color
		end
		
		def color= opt
			@color = opt
			@surface.fill @color
		end
	end
	
	# A simple image class
	class Image < Engine::Drawable
		# Creates a new Image
		#
		# Parameters are in hash format (i.e. Image.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * Image File or rubygame Surface (:image) *REQUIRED*
		#
		# Engine::Box inherits from Engine::Drawable 
		# check there to see more useful parameters...
		def initialize settings={}
			if settings[:image] == nil
				puts "Image prameter not passed to Image.new\nFAIL."
			end
			settings[:surface] = Rubygame::Surface.load settings[:image] if settings[:image].class == String
			settings[:surface] = settings[:image] if settings[:image].class == Rubygame::Surface
			settings[:width] = settings[:surface].width
			settings[:height] = settings[:surface].height
			super settings
		end
	end
	
	# A class used to display texts
	class Text < Engine::Drawable
		@@default_font = "FreeSans.ttf"
		
		# Creates a new Text object
		#
		# Parameters are in hash format (i.e. Text.new(:x => 30, :y => 500) )
		#
		# Takes:
		# * the text to display (:text)
		# * Color (:color)
		# * Anti-Aliasing when rendering the text (true or false) (:taa)
		# * Font Size (:size)
		# * Font file to use (must be ttf) (:font)
		#
		# Engine::Box inherits from Engine::Drawable 
		# check there to see more useful parameters...
		def initialize settings={:text => "TEST STRING", :color => [255, 255, 255], :taa => true, :size => 20, :font => @@default_font, :aa => false}
			s = 				{:text => "TEST STRING", :color => [255, 255, 255], :taa => true, :size => 20, :font => @@default_font, :aa => false}.merge! settings
			@font = Rubygame::TTF.new s[:font], s[:size]
			s[:width] = @font.size_text(s[:text])[0]
			s[:height] = @font.size_text(s[:text])[1]
			#s[:surface] = rerender_text#@font.render(s[:text], s[:taa], s[:color])
			super s
			
			Util.hash_to_var(s, [:text, :color, :taa], self)
			rerender_text
		end
		
		def rerender_text
			@width = @font.size_text(@text)[0]
			@height = @font.size_text(@text)[1]
			if !@text.strip.empty?
				@surface = @font.render(@text, @taa, @color)
			else
				@surface = Rubygame::Surface.new [1,1]
			end
		end
		
		def text
			@text
		end
		
		def text= string
			@text = string
			rerender_text
		end
		
		def taa
			@taa
		end
		
		def taa= opt
			@taa = opt
			rerender_text
		end
		
		def color
			@color
		end
		
		def color= opt
			@color = opt
			rerender_text
		end
	end
	
	# All game states should inherit from this class
	#
	# When defining your own state, all code should be in the setup method.
	# You should not overide anything unless you know what you are doing.
	#
	# Example:
	#  class MyState < Engine::State
	#  	def setup
	#  		mybox = Engine::Box.new :width => 30, :height => 30, :x => 200, :y => 400
	#  	end
	#  end
	class State
		include EventOwner
		include Defer
		# Events in the state
		attr_accessor :events
		# Objects in the state
		attr_accessor :objs
		# Background Color
		attr_accessor :bg_color
		
		# initializes the @events and @objs methods
		#
		# DO NOT OVERIDE THIS METHOD
		def initialize
			@events = []
			@objs = []
			@bg_color = [0,0,0]
		end
		
		# Gives state objects access to the game class
		def self.add_to_game game
			@@game = game
			@@screen = game.screen_surf
		end
		
		# Code that is run when a state takes the stage
		# override this method in your own states
		def setup
		end
		
		# If you want your state to run some code every update
		#
		# This helps keep down on useless objects =)
		def update
		end
	end
	
	# Utilities for internal use in the game engine
	class Util
		# Goes through a hash, and sets instance variables
		def self.hash_to_var(hash, filter, obj)
			filter.each do |var|
				obj.send :instance_variable_set, :"@#{var}", hash[var]
			end
		end
	end
	
	# A mix-in module for objects that can have events
	# (GameObject, State, Game)
	#
	# You can call it's methods to add events that you
	# want to respond to
	module EventOwner
		# Generic event handler, give us the type of
		# event (Rubygame::KeyDownEvent, for example)
		# and we'll call your code when it happens!
		def event type, &block
			ev = Event.new(type, block, self)
			if self.class != Game
				@@game.current_state.events += [ev]
			else
				@events += [ev]
			end
			return ev
		end
		
		# Respond to the a certain key getting pressed
		def key_press key, &block
			event(Rubygame::Events::KeyPressed) do |ev|
				if ev.key == key
					block.call ev
				end
			end
		end
		
		# Respond to the a certain key getting released
		def key_release key, &block
			event(Rubygame::Events::KeyReleased) do |ev|
				if ev.key == key
					block.call ev
				end
			end
		end
		
		# Respond to the a certain mouse button getting pressed
		def mouse_press button=:mouse_left, &block
			event(Rubygame::Events::MousePressed) do |ev|
				if ev.button == button
					block.call ev
				end
			end
		end
		
		# Respond to the a certain mouse button getting released
		def mouse_release button=:mouse_left, &block
			event(Rubygame::Events::MouseReleased) do |ev|
				if ev.button == button
					block.call ev
				end
			end
		end
		
		# Respond to the mouse moving
		def mouse_motion &block
			event(Rubygame::Events::MouseMoved) do |ev|
				block.call ev
			end
		end
		
		# Respond while a key is pressed
		def while_key_pressed key, &block
			slave = Slave.new block
			key_press(key) do |ev|
				slave.active = true
			end
			key_release(key) do |ev|
				slave.active = false
			end
			# The following is a completely hack-ish way
			# of getting the slave's @active right when
			# state changes happen. We have to do it this
			# way because Rubygame doesn't have a native
			# get_key_state method or equivilent
			def slave.key= key
				@key = key
			end
			slave.key = key
			def slave.state_change
				key_down = SDL.GetKeyState[eval("Rubygame::K_#{@key.to_s.upcase}")]
				if key_down == 0
					@active = false
				elsif key_down == 1
					@active = true
				end
			end
		end
		
		# Respond while a key is released
		def while_key_released key, &block
			slave = Slave.new block
			slave.active = true
			key_press(key) do |ev|
				slave.active = false
			end
			key_release(key) do |ev|
				slave.active = true
			end
			# The following is a completely hack-ish way
			# of getting the slave's @active right when
			# state changes happen. We have to do it this
			# way because Rubygame doesn't have a native
			# get_key_state method or equivilent
			def slave.key= key
				@key = key
			end
			slave.key = key
			def slave.state_change
				key_down = SDL.GetKeyState[eval("Rubygame::K_#{@key.to_s.upcase}")]
				if key_down == 0
					@active = true
				elsif key_down == 1
					@active = false
				end
			end
		end
		
		# Respond to the mouse being pressed on an object
		def mouse_pressed_on button=:mouse_left, obj=self, &block
			event(Rubygame::Events::MousePressed) do |ev|
				if ev.button == button
					if @@game.collision_between(Mouse.new(ev.pos), obj)
						block.call ev
					end
				end
			end
		end
	
		# Respond to the mouse being released on an object
		def mouse_released_on button=:mouse_left, obj=self, &block
			event(Rubygame::Events::MouseReleased) do |ev|
				if ev.button == button
					if @@game.collision_between(Mouse.new(ev.pos), obj)
						block.call ev
					end
				end
			end
		end
		
		# Respond to the mouse hovering over an object
		def mouse_hovering_over obj=self, &block
			mouse_motion do |ev|
				if @@game.collision_between(Mouse.new(ev.pos), obj)
					block.call ev
				end
			end
		end
		
		# Respond to the mouse not hovering over an object
		def mouse_not_hovering_over obj=self, &block
			mouse_motion do |ev|
				if !@@game.collision_between(Mouse.new(ev.pos), obj)
					block.call ev
				end
			end
		end
	
		# Deletes a specified event
		def delete_event ev
			@@game.events.delete ev
			@@game.current_state.events.delete ev
		end
		
		# Gives EventOwner access to the Game
		def self.add_to_game game
			@@game = game
		end
		
		# This class is used interally by the Game class
		# and the EventOwner module
		#
		# It holds the type of event, the code to run
		# when that event is encountered, and the
		# owner of the code
		class Event
			attr_reader :type, :key, :owner
		
			# Creates a new event object
			#
			# Takes:
			# * The key or button we're working with
			# * The code to be run when the event happens
			# * The object that owns the event
			# * Whether it is active (i.e. for a while_key_down event)
			def initialize type, code, owner
				@type = type
				@code = code
				@owner = owner
			end
		
			# Runs the code specified in the event's creation
			def call *args
				@code.call *args
			end
		end
		
		# Runs while_key_down and while_key_up events
		#
		# Used internally, probably of no use elsewhere
		class Slave < Engine::GameObject
			attr_accessor :active
			def initialize code
				super(:x => 0, :y => 0, :width => 0, :height => 0)
				@code = code
				@active = false
			end
			
			def update
				@code.call if @active
			end
		end
		
		# Looks like an Engine::GameObject
		# but is just used for collision
		# detection with the mouse
		class Mouse
			attr_accessor :x, :y, :width, :height
			def initialize pos
				@x = pos[0]
				@y = pos[1]
				@width = @height = 1
			end
		end
	end
	
	# A module for defering bits of code until later
	module Defer
		# Class that does the actual work of defering the code
		class Deferer < GameObject
			def initialize
				super
				@time = 0
				@defered = {}
			end
		
			def update
				@time += 1
				if @defered[@time] != nil
					@defered[@time].each do |action|
						action.call
					end
					@defered.delete @time
				end
			end
		
			def add action, time
				if @defered[@time+time].class == Array
					@defered[@time+time] += [action]
				else
					@defered[@time+time] = [action]
				end
			end
		end
	
		# Adds code to be defered. Time is in
		# measured in game updates
		def defer action, time
			@@_deferer ||= Deferer.new
			@@_deferer.add action, time
		end
	end
end
