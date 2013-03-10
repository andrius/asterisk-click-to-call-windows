#!/usr/bin/ruby

require 'yaml'
require 'openssl'
require 'digest/sha1'
begin
  require 'win32ole'
  $windows_os = true
rescue LoadError
  $windows_os = false
end
require 'uri'
require 'cgi'
require 'net/http'

log_file = File.open("/callto.log", "w+")

begin
  if $windows_os then
    user_info = WIN32OLE.new("Wscript.Network")
    config_directory = "C:\\Documents\ And\ Settings\\#{user_info.username}"
    config = YAML::load_file "#{config_directory}\\callto.yml"
  else
    config = YAML::load_file "callto.yml"
  end

  log_file.puts config.inspect

  c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
  c.encrypt
  # your pass is what is used to encrypt/decrypt
  c.key = key = Digest::SHA1.hexdigest(config[:password])
  c.iv = iv = c.random_iv
  e = c.update("ARGV[0]")
  e << c.final
  esc = CGI.escape(e)
  log_file.puts "source: #{ARGV[0]}}\n"
  log_file.puts "encrypted: #{e}\n"
  log_file.puts "escaped: #{esc}\n"

  esc = CGI.escape(ARGV[0])

  res = Net::HTTP.get_response(config[:host], "#{config[:uri]}?#{config[:user]}=#{esc}", config[:port])
  log_file.puts res.inspect, res.body.inspect


rescue => err
  log_file.puts err.inspect, '-----'
ensure
  log_file.close
end

