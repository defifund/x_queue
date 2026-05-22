# frozen_string_literal: true

module XQueue
  class Scheduler
    # Schedule independent tweets (each posted separately with delays).
    #
    #   XQueue::Scheduler.tweets(
    #     texts: ["tweet 1", "tweet 2"],
    #     account: account,
    #     source: article,        # optional, polymorphic
    #     at: article.published_at # optional, explicit target time
    #   )
    #
    # `at:` and `not_before:` express different intents:
    #   - `at:` — schedule at this exact time (only coerced forward to now
    #     if it is in the past). The account's existing queue is ignored.
    #   - `not_before:` — earliest allowed time; the scheduler still appends
    #     after the account's last scheduled tweet, whichever is later.
    # If neither is given, the first tweet is queued right after the
    # account's current tail.
    def self.tweets(texts:, account:, source: nil, not_before: nil, at: nil)
      return 0 if texts.blank?

      config = XQueue.configuration
      scheduled_at = pick_start(account, not_before: not_before, at: at)

      texts.each do |text|
        Tweet.create!(
          content: text,
          account: account,
          source: source,
          status: :scheduled,
          scheduled_at: scheduled_at
        )
        scheduled_at += rand(config.delay_range).minutes
      end

      texts.size
    end

    # Schedule a thread (tweets posted as replies in sequence).
    #
    #   XQueue::Scheduler.thread(
    #     texts: ["1/3 ...", "2/3 ...", "3/3 ..."],
    #     account: account,
    #     source: article,         # optional
    #     at: article.published_at # optional, explicit target time
    #   )
    #
    # All tweets in a thread share one `scheduled_at`; the posting worker
    # applies `thread_delay_range` between replies at runtime.
    # See `.tweets` for the difference between `at:` and `not_before:`.
    def self.thread(texts:, account:, source: nil, not_before: nil, at: nil)
      return 0 if texts.blank?

      thread_id = SecureRandom.uuid
      scheduled_at = pick_start(account, not_before: not_before, at: at)

      texts.each_with_index do |text, i|
        Tweet.create!(
          content: text,
          account: account,
          source: source,
          status: :scheduled,
          scheduled_at: scheduled_at,
          thread_id: thread_id,
          thread_position: i + 1
        )
      end

      texts.size
    end

    def self.pick_start(account, not_before:, at:)
      return [at, Time.current].max if at

      next_slot(account, not_before: not_before)
    end

    def self.next_slot(account, not_before: nil)
      config = XQueue.configuration
      last_time = Tweet.where(account: account)
        .where(status: [:scheduled, :posted])
        .order(scheduled_at: :desc)
        .pick(:scheduled_at)

      base = last_time ? last_time + rand(config.delay_range).minutes : Time.current
      [base, Time.current, not_before].compact.max
    end

    private_class_method :pick_start, :next_slot
  end
end
