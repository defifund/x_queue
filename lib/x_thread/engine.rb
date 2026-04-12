# frozen_string_literal: true

module XThread
  class Engine < ::Rails::Engine
    isolate_namespace XThread

    initializer "x_thread.active_record" do
      ActiveSupport.on_load(:active_record) do
        require "x_thread/client"
        require "x_thread/scheduler"
      end
    end
  end
end
