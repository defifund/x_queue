# frozen_string_literal: true

require "test_helper"

module XQueue
  class SchedulerTest < XQueueTest
    def test_tweets_schedules_first_tweet_no_earlier_than_not_before
      account = TestAccount.create!
      not_before = 2.days.from_now.change(usec: 0)

      count = Scheduler.tweets(
        texts: ["first", "second"],
        account: account,
        not_before: not_before
      )

      assert_equal 2, count
      tweets = Tweet.order(:scheduled_at).to_a
      assert_equal not_before, tweets.first.scheduled_at
      assert_equal not_before + 20.minutes, tweets.second.scheduled_at
    end

    def test_tweets_respects_existing_account_queue_after_not_before
      account = TestAccount.create!
      existing_time = 3.days.from_now.change(usec: 0)
      Tweet.create!(content: "existing", account: account, status: :scheduled, scheduled_at: existing_time)

      Scheduler.tweets(
        texts: ["next"],
        account: account,
        not_before: 1.day.from_now
      )

      assert_equal existing_time + 20.minutes, Tweet.order(:scheduled_at).last.scheduled_at
    end

    def test_thread_schedules_first_tweet_no_earlier_than_not_before
      account = TestAccount.create!
      not_before = 2.days.from_now.change(usec: 0)

      count = Scheduler.thread(
        texts: ["1/2", "2/2"],
        account: account,
        not_before: not_before
      )

      assert_equal 2, count
      tweets = Tweet.order(:thread_position).to_a
      assert_equal not_before, tweets.first.scheduled_at
      assert_equal not_before, tweets.second.scheduled_at
      assert_equal tweets.first.thread_id, tweets.second.thread_id
      assert_equal 1, tweets.first.thread_position
      assert_equal 2, tweets.second.thread_position
    end
  end
end
