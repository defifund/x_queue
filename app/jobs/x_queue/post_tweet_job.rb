# frozen_string_literal: true

module XQueue
  class PostTweetJob < ActiveJob::Base
    queue_as { XQueue.configuration.queue_name }

    def perform(tweet_id, reply_to_tweet_id: nil)
      tweet = XQueue::Tweet.find(tweet_id)
      return unless tweet.scheduled?

      client = XQueue::Client.new(
        access_token: tweet.account.access_token,
        access_token_secret: tweet.account.access_token_secret
      )

      response = client.post(tweet.content, reply_to_tweet_id: reply_to_tweet_id)
      posted_tweet_id = response.dig("data", "id")
      tweet.update!(status: :posted, posted_at: Time.current, x_tweet_id: posted_tweet_id)

      if (next_tweet = tweet.next_in_thread)
        delay = rand(XQueue.configuration.thread_delay_range).minutes
        XQueue::PostTweetJob.set(wait: delay).perform_later(next_tweet.id, reply_to_tweet_id: posted_tweet_id)
      end
    rescue => e
      tweet&.update!(status: :failed)
      Rails.logger.error("[XQueue] Failed to post tweet ##{tweet_id}: #{e.message}")
    end
  end
end
