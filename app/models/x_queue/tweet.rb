# frozen_string_literal: true

module XQueue
  class Tweet < ActiveRecord::Base
    self.table_name = "x_queue_tweets"

    belongs_to :source, polymorphic: true, optional: true
    belongs_to :account, polymorphic: true, optional: true

    enum :status, {draft: 0, scheduled: 1, posted: 2, failed: 3}

    after_save :enqueue_post_job, if: -> { scheduled? && saved_change_to_status? && thread_lead? }

    def thread_lead?
      thread_id.nil? || thread_position == 1
    end

    def next_in_thread
      return nil unless thread_id
      self.class.find_by(thread_id: thread_id, thread_position: thread_position + 1)
    end

    private

    def enqueue_post_job
      XQueue::PostTweetJob
        .set(wait_until: scheduled_at, queue: XQueue.configuration.queue_name)
        .perform_later(id)
    end
  end
end
