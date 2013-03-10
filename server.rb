#!/usr/bin/ruby

require 'webrick'
require 'yaml'
require 'openssl'
require 'digest/sha1'
require 'uri'
require 'cgi'


class VoIPCallBack < WEBrick::HTTPServlet::AbstractServlet

  def do_GET(request, response)

    puts request.unparsed_uri
    url, user, command = request.unparsed_uri.split(/\?|=/)
    callback user.to_s, command.to_s

    status, content_type, body = do_stuff_with(request)

    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end

  def callback(user, command)
    begin
      unless user.empty? || command.empty?
        users = YAML::load_file "users.yml"
        if users.has_key?(user)
          password, extension = users[user]
          #c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          ## your pass is what is used to encrypt/decrypt
          #c.key = key = Digest::SHA1.hexdigest(password)
          #c.iv = iv = c.random_iv
          #c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          #c.decrypt
          #c.key = key
          #c.iv = iv
          #d = c.update(CGI.unescape(command))
          #d << c.final
          d = CGI.unescape(command)
          puts "decrypted: #{d}, password #{password}, extension #{extension}\n"

          phone_number = '0000'
          phone_number = command.split('/')[-1] if command =~ /^\/callto:callto/
          puts phone_number
          `echo -e "Channel: Local/#{extension}@from-internal/n\nMaxRetries: 2\nRetryTime: 50\nWaitTime: 60\nContext: from-internal\nExtension: #{phone_number}\nPriority: 1\n" > /tmp/#{extension}-#{phone_number} && mv /tmp/#{extension}-#{phone_number} /var/spool/asterisk/outgoing`
        end
      end
    rescue => err
      puts err.inspect, err.backtrace
    end
  end

  def do_stuff_with(request)
    return 200, "text/plain", "your-data-received"
  end

end

if $0 == __FILE__ then
  server = WEBrick::HTTPServer.new(:Port => 2222, :BindAddress=>"0.0.0.0")
  server.mount "/call", VoIPCallBack
  trap "INT" do server.shutdown end
  server.start
end

