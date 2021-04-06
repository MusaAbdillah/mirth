require "socket"
require "yaml/store"

server = TCPServer.new(1337)

# Default data that are not persistent
store = YAML::Store.new("mirth.yml")

loop do 
	client = server.accept
	
	request_line = client.readline

	# Break down the HTTP request from client
	method_token, target, version_number = request_line.split

	case [method_token, target]
	when ["GET", "/show/birthdays"]
		# Endpoint to show birtdays
		response_status_code="200 OK"
		response_message = ""
		content_type = "text/html"

		all_birthdays =  {}
		store.transaction do
			all_birthdays = store[:birthdays]
		end

	
		all_birthdays.each do |birthday|
	      response_message << "<li> #{birthday[:name]}</b> was born on #{birthday[:date]}!</li>\n"
	    end

		response_message << <<~STR
			<form action="/add/birthday" method="post" enctype="application/x-www-form-urlencoded">
				<p><label>Name <input type="text" name="name"></label></p>
		        <p><label>Birthday <input type="date" name="date"></label></p>
		        <p><button>Submit birthday</button></p>
			</form>
		STR

	when ["POST", "/add/birthday"]
		# Endpoint to add birthday
		response_status_code="303 See Other"
		response_message = ""
		content_type = "text/html"

		# Break apart header fields to get the 
		# Content-Length which will help us get the body 
		# of the message
		all_headers = {}
		while true 
			line = client.readline
			break if line == "\r\n"
			header_name, value = line.split(": ")
			puts "==> header_name #{header_name}"
			puts "==> value #{value}"
			all_headers[:header_name] = value
		end
		body = client.read(all_headers['Content-Length'].to_i)

		# Use Ruby's built in decoder library
		# to decode the body into a Hash object
		require 'uri'
		new_birthday = URI.decode_www_form(body).to_h
		puts new_birthday
		puts "new_birthday"
		all_birthdays << new_birthday.transform_keys(&:to_sym)
	else
		response_status_code="200 OK"
		response_message = "✅ Received a #{method_token} request to #{target} with #{version_number}"
		content_type = "text/plain"
	end

	puts response_message

	http_response = <<~MSG
		"#{version_number} #{response_status_code}"
		Content-Type: #{content_type}; charset=#{response_message.encoding.name}
		Location: /show/birthdays

		#{response_message}
	MSG


	client.puts http_response
	client.close

end