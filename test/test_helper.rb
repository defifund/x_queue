# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "active_record"
require "active_job"
require "minitest/autorun"
require "x_queue"
require "x_queue/scheduler"
require "x_queue/client"
require_relative "../app/models/x_queue/tweet"
require_relative "../app/jobs/x_queue/post_tweet_job"

ActiveJob::Base.queue_adapter = :test

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.define do
  create_table :test_accounts, force: true do |t|
    t.timestamps
  end

  create_table :x_queue_tweets, force: true do |t|
    t.text :content
    t.integer :status, default: 0, null: false
    t.datetime :scheduled_at
    t.datetime :posted_at
    t.string :thread_id
    t.integer :thread_position
    t.string :x_tweet_id
    t.references :account, polymorphic: true
    t.references :source, polymorphic: true
    t.timestamps
  end
end

class TestAccount < ActiveRecord::Base
end

class XQueueTest < Minitest::Test
  def setup
    XQueue::Tweet.delete_all
    XQueue.reset_configuration!
    XQueue.configure do |config|
      config.delay_range = 20..20
      config.thread_delay_range = 1..1
    end
  end
end
