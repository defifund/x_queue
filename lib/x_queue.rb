# frozen_string_literal: true

require_relative "x_queue/version"
require_relative "x_queue/configuration"
require_relative "x_queue/engine" if defined?(Rails::Engine)

module XQueue
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
