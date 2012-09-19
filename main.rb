# -*- coding: utf-8 -*-

if RUBY_VERSION < '1.9.2'
  require 'client'
else
  require_relative 'client'
end

if ARGV.size < 1
  puts 'usage: ruby main.rb HOSTNAME [PORT]'
  exit
end
HOST = ARGV[0]
PORT = ARGV[1] ? ARGV[1].to_i : 3478

client = Client.new(HOST, PORT)
client.run
