require 'java'

# Generic includes for using EJBs
java_import 'java.util.Properties'
java_import 'javax.naming.Context'
java_import 'javax.naming.InitialContext'
java_import 'java.io.FileInputStream'

# Module for calling EJBs from Ruby. To be used with JRuby.
# Example:
#   context = Rejb::context
#   ejb = context.get_service("ejb:myapp/myejbmodule//StatefulBean!org.myapp.ejb.Counter")
#   result = ejb.someMethod(parameters)
module Rejb

  # Class wraper for Java 'javax.naming.Context'
  class Context

    def initialize(context)
      @java_context = context
    end

    # Returns EJB with the specified JNDI name.
    def get_service(jndi_service_name)
      @java_context.lookup(jndi_service_name)
    end

    def close
      @java_context.close()
    end

  end # class Context


  # Returns context.
  def self.context(file_name = "jndi.yml")
    properties = properties(file_name)
    Rejb::Context.new(initial_context(properties))
  end


  # Sets JNDI properties to be used for getting an initial context.
  def self.properties(file_name)
    properties = Properties.new
    path = File.join(Rails.root, "config", file_name)
    
    if File.exist?(path)
      config = YAML.load_file(path)
      config["jndi_#{Rails.env}"].each do |key, value|
        properties.put(key, value)
      end
    else
      raise IOError, "File '#{path}' not found"
    end

    properties
  end


  # Returns initial context that can be used for looking up JNDI names.
  def self.initial_context(properties)
     InitialContext.new(properties)
  end

end