# frozen_string_literal: true

module XThread
  class Configuration
    attr_accessor :api_key, :api_key_secret,
                  :delay_range, :thread_delay_range,
                  :queue_name

    def initialize
      @api_key = nil
      @api_key_secret = nil
      @delay_range = 20..40   # minutes between independent tweets
      @thread_delay_range = 1..5  # minutes between thread replies
      @queue_name = :default
    end
  end
end
