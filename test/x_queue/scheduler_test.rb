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

    def test_tweets_with_at_uses_exact_time_when_queue_empty
      account = TestAccount.create!
      target = 6.hours.from_now.change(usec: 0)

      Scheduler.tweets(texts: ["a", "b"], account: account, at: target)

      tweets = Tweet.order(:scheduled_at).to_a
      assert_equal target, tweets.first.scheduled_at
      assert_equal target + 20.minutes, tweets.second.scheduled_at
    end

    def test_tweets_with_at_ignores_later_existing_queue
      account = TestAccount.create!
      later = 2.days.from_now.change(usec: 0)
      Tweet.create!(content: "later", account: account, status: :scheduled, scheduled_at: later)

      target = 6.hours.from_now.change(usec: 0)
      Scheduler.tweets(texts: ["new"], account: account, at: target)

      new_tweet = Tweet.where(content: "new").sole
      assert_equal target, new_tweet.scheduled_at
    end

    def test_tweets_with_at_in_the_past_coerced_to_now
      account = TestAccount.create!
      past = 2.hours.ago

      before = Time.current
      Scheduler.tweets(texts: ["x"], account: account, at: past)
      after = Time.current

      scheduled = Tweet.sole.scheduled_at
      assert scheduled >= before - 1.second, "expected scheduled_at >= now, got #{scheduled}"
      assert scheduled <= after + 1.second,  "expected scheduled_at near now, got #{scheduled}"
    end

    def test_thread_with_at_uses_exact_time
      account = TestAccount.create!
      later = 2.days.from_now.change(usec: 0)
      Tweet.create!(content: "later", account: account, status: :scheduled, scheduled_at: later)

      target = 6.hours.from_now.change(usec: 0)
      Scheduler.thread(texts: ["1/2", "2/2"], account: account, at: target)

      thread_tweets = Tweet.where.not(thread_id: nil).order(:thread_position).to_a
      assert_equal target, thread_tweets.first.scheduled_at
      assert_equal target, thread_tweets.second.scheduled_at
    end
  end
end
