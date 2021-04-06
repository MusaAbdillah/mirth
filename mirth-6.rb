require "rack"
require "rack/handler/puma"
require "yaml/store"
require "sqlite3"

app = -> (environment) {
	request  = Rack::Request.new(environment)
	response = Rack::Response.new(environment)

	store = YAML::Store.new("mirth.yml")
	database = SQLite3::Database.new("mirth.sqlite3", results_as_hash: true)

	if request.get? && request.path == "/show/birthdays"
		# Endpoint show birthdays
		response.write("<ul>\n")
		response.content_type = "text/html; charset=UTF-8"
			all_birthdays =  database.execute("SELECT * FROM birthdays")
			store.transaction do
				all_birthdays = store[:birthdays]
			end

		
			all_birthdays.each do |birthday|
		      response.write("<li> #{birthday[:name]}</b> was born on #{birthday[:date]}!</li>\n")
		    end
	    response.write("</ul>\n")

		response.write <<~STR
			<form action="/add/birthday" method="post" enctype="application/x-www-form-urlencoded">
				<p><label>Name <input type="text" name="name"></label></p>
		        <p><label>Birthday <input type="date" name="date"></label></p>
		        <p><button>Submit birthday</button></p>
			</form>
		STR
	elsif request.post? && request.path == "/add/birthday"
		# Endpoint add birthday
		# Instead of decoding the body, we can 
		# use #params to get the decoded body
		new_birthday = request.params.transform_keys(&:to_sym)
		content_type = "text/html"

		query = "INSERT INTO birthdays VALUES (?, ?)"
		database.execute(query, new_birthday["name"], new_birthday["date"])
		store.transaction do 
			store[:birthdays] << new_birthday
		end
		response.redirect("/show/birthdays", 303)
	else
		status = 200
		response.content_type = "text/plain; charset=UTF-8"
		response.write("✅ Received a #{request.request_method} request to #{request.path}")
	end

	# Return 3-element Array 
	# headers = { 
	# 	'Content-Type' => "#{content_type}; charset=#{response_message.encoding.name}", 
	# 	"Location" => "/show/birthdays" 
	# }
	# body = [response_message]

	# [status, headers, body]
	response.finish
}

Rack::Handler::Puma.run(app, :Port => 1337, :Verbose => true)
