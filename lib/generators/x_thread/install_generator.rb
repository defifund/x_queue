# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module XThread
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def copy_migration
        migration_template "create_x_thread_tweets.rb.erb",
          File.join(db_migrate_path, "create_x_thread_tweets.rb")
      end

      def copy_initializer
        template "initializer.rb.erb", "config/initializers/x_thread.rb"
      end

      private

      def db_migrate_path
        "db/migrate"
      end
    end
  end
end
