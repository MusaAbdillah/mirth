require "rack"
require "rack/handler/puma"
require "yaml/store"
require "sqlite3"

# Add the Rails libraries we need
require "action_controller"
require "active_record"
require "action_dispatch"
require "active_support"
require "logger"

# create establish_connection with ar with sqlite3 database
active_record = ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "/Users/musaabdillah/Musa/playground/mirth/mirth.sqlite3")

# show current log
ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)

# save log to file mirth.log
ActiveRecord::Base.logger = Logger.new("mirth.log")

# create active_record model for birthdays table
class Birthday < ActiveRecord::Base; end

# Ensure that action_controller reads view from root 
ActionController::Base.prepend_view_path(".")

class BirthdaysController < ActionController::Base

	def index 
		@all_birthdays = Birthday.all
	end

	def create
		Birthday.create(name: params["name"], date: params["date"])
		redirect_to(birthdays_path, status: :see_other)
	end

	def all_path
		render(plain: "✅ Received a #{request.request_method} request to #{request.path}")
	end
end

# Create route to manage routing endpoints
router = ActionDispatch::Routing::RouteSet.new

# Include url helpers module to use `birthdays_path`
BirthdaysController.include(router.url_helpers)

router.draw do 

	resources :birthdays

	match "*path", via: :all, to: "birthdays#all_path"
end


Rack::Handler::Puma.run(router, :Port => 1337, :Verbose => true)
