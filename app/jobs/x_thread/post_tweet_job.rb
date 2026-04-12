# frozen_string_literal: true

module XThread
  class PostTweetJob < ActiveJob::Base
    queue_as { XThread.configuration.queue_name }

    def perform(tweet_id, reply_to_tweet_id: nil)
      tweet = XThread::Tweet.find(tweet_id)
      return unless tweet.scheduled?

      client = XThread::Client.new(
        access_token: tweet.access_token,
        access_token_secret: tweet.access_token_secret
      )

      response = client.post(tweet.content, reply_to_tweet_id: reply_to_tweet_id)
      posted_tweet_id = response.dig("data", "id")
      tweet.update!(status: :posted, posted_at: Time.current, x_tweet_id: posted_tweet_id)

      if (next_tweet = tweet.next_in_thread)
        delay = rand(XThread.configuration.thread_delay_range).minutes
        XThread::PostTweetJob.set(wait: delay).perform_later(next_tweet.id, reply_to_tweet_id: posted_tweet_id)
      end
    rescue => e
      tweet&.update!(status: :failed)
      Rails.logger.error("[XThread] Failed to post tweet ##{tweet_id}: #{e.message}")
    end
  end
end
