# frozen_string_literal: true

require_relative "x_thread/version"
require_relative "x_thread/configuration"
require_relative "x_thread/engine" if defined?(Rails::Engine)

module XThread
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
