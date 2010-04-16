#!/usr/bin/env ruby
require 'rubygems'
require 'rubygame'
require 'httparty'
require 'optparse'

require 'lib/engine'
require 'lib/map'
require 'lib/setup'
require 'lib/ingame'
include Engine
include Rubygame::Events

$id = ""

def safe_get url
	begin
		HTTParty.get("http://#{$ip}/" + url)
	rescue Errno::EADDRINUSE
		puts "Address already in use"
		retry
	rescue Errno::ECONNREFUSED
		puts "Connection refused"
	rescue
		puts "Fail, unknown or unexpected error"
	end
end

game = Game.new
game.event(QuitRequested) do
	exit
end

Text.send(:class_variable_set, :@@default_font, "media/FreeSans.ttf")

options = {}
optparse = OptionParser.new do |opts|
	options[:skip] = false
	opts.on('--skip', 'Skip character design screen') do
		options[:skip] = true
	end
	
	options[:ip] = "localhost:4567"
	opts.on('--ip ADDRESS', "Set the ip address of the server we're using") do |address|
		options[:ip] = address
	end
end
optparse.parse!

if options[:skip]
	game.switch_state InGame.new "Tyler", [255,255,255]
else
	game.switch_state Setup.new
end

$ip = options[:ip]

game.run
