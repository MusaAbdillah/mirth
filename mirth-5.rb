require "rack"
require "rack/handler/puma"
require "yaml/store"

app = -> (environment) {
	request = Rack::Request.new(environment)

	store = YAML::Store.new("mirth.yml")

	if request.get? && request.path == "/show/birthdays"
		# Endpoint show birthdays
		status = 200
		content_type = "text/html"
		response_message = "<ul>\n"
			all_birthdays =  {}
			store.transaction do
				all_birthdays = store[:birthdays]
			end

		
			all_birthdays.each do |birthday|
		      response_message << "<li> #{birthday[:name]}</b> was born on #{birthday[:date]}!</li>\n"
		    end
	    response_message << "</ul>\n"

	    puts "all_birthdays"
	    puts all_birthdays
	    puts response_message
	    puts "all_birthdays"

		response_message << <<~STR
			<form action="/add/birthday" method="post" enctype="application/x-www-form-urlencoded">
				<p><label>Name <input type="text" name="name"></label></p>
		        <p><label>Birthday <input type="date" name="date"></label></p>
		        <p><button>Submit birthday</button></p>
			</form>
		STR
	elsif request.post? && request.path == "/add/birthday"
		# Endpoint add birthday
		status = 303
		content_type = "text/html"
		response_message = ""

		# Instead of decoding the body, we can 
		# use #params to get the decoded body
		new_birthday = request.params
		puts "new_birthday"
		puts new_birthday
		puts "new_birthday"

		store.transaction do 
			store[:birthdays] << new_birthday.transform_keys(&:to_sym)
		end
	else
		status = 200
		content_type = "text/plain"
		response_message = "✅ Received a #{request.request_method} request to #{request.path}"
	end

	# Return 3-element Array 
	headers = { 
		'Content-Type' => "#{content_type}; charset=#{response_message.encoding.name}", 
		"Location" => "/show/birthdays" 
	}
	body = [response_message]

	[status, headers, body]
}

Rack::Handler::Puma.run(app, :Port => 1337, :Verbose => true)
