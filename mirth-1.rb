require "socket"

server = TCPServer.new(1337)

loop do 
	client = server.accept

	client.puts "What's your name?"
	input = client.gets
	puts "Received #{input.chomp} from a client socket on 1337"
	client.puts "Hi, #{input.chomp}! You've successfully connected to the server socket."

	request_line = client.readline
	puts "The HTTP request line looks like this."
	puts request_line
	
	puts "Closing client socket."
	client.puts "Good bye #{input}"
	client.close

end