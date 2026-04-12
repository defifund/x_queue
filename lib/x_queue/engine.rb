# frozen_string_literal: true

module XQueue
  class Engine < ::Rails::Engine
    isolate_namespace XQueue

    initializer "x_queue.active_record" do
      ActiveSupport.on_load(:active_record) do
        require "x_queue/client"
        require "x_queue/scheduler"
      end
    end
  end
end
