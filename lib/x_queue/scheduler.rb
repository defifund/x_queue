# frozen_string_literal: true

module XQueue
  class Scheduler
    # Schedule independent tweets (each posted separately with delays).
    #
    #   XQueue::Scheduler.tweets(
    #     texts: ["tweet 1", "tweet 2"],
    #     account: account,
    #     source: article, # optional, polymorphic
    #     not_before: article.published_at # optional
    #   )
    def self.tweets(texts:, account:, source: nil, not_before: nil)
      return 0 if texts.blank?

      config = XQueue.configuration
      scheduled_at = next_slot(account, not_before: not_before)

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
    #     source: article, # optional
    #     not_before: article.published_at # optional
    #   )
    def self.thread(texts:, account:, source: nil, not_before: nil)
      return 0 if texts.blank?

      thread_id = SecureRandom.uuid
      scheduled_at = next_slot(account, not_before: not_before)

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

    def self.next_slot(account, not_before: nil)
      config = XQueue.configuration
      last_time = Tweet.where(account: account)
        .where(status: [:scheduled, :posted])
        .order(scheduled_at: :desc)
        .pick(:scheduled_at)

      base = last_time ? last_time + rand(config.delay_range).minutes : Time.current
      [base, Time.current, not_before].compact.max
    end

    private_class_method :next_slot
  end
end
