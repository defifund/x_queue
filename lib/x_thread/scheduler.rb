# frozen_string_literal: true

module XThread
  class Scheduler
    # Schedule independent tweets (each posted separately with delays).
    #
    #   XThread::Scheduler.tweets(
    #     texts: ["tweet 1", "tweet 2"],
    #     access_token: "...",
    #     access_token_secret: "...",
    #     source: article  # optional, polymorphic
    #   )
    def self.tweets(texts:, access_token:, access_token_secret:, source: nil)
      return 0 if texts.blank?

      config = XThread.configuration
      scheduled_at = next_slot(access_token)

      texts.each do |text|
        Tweet.create!(
          content: text,
          access_token: access_token,
          access_token_secret: access_token_secret,
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
    #   XThread::Scheduler.thread(
    #     texts: ["1/3 ...", "2/3 ...", "3/3 ..."],
    #     access_token: "...",
    #     access_token_secret: "...",
    #     source: article  # optional
    #   )
    def self.thread(texts:, access_token:, access_token_secret:, source: nil)
      return 0 if texts.blank?

      thread_id = SecureRandom.uuid
      scheduled_at = next_slot(access_token)

      texts.each_with_index do |text, i|
        Tweet.create!(
          content: text,
          access_token: access_token,
          access_token_secret: access_token_secret,
          source: source,
          status: :scheduled,
          scheduled_at: scheduled_at,
          thread_id: thread_id,
          thread_position: i + 1
        )
      end

      texts.size
    end

    def self.next_slot(access_token)
      config = XThread.configuration
      last_time = Tweet.where(access_token: access_token)
        .where(status: [:scheduled, :posted])
        .order(scheduled_at: :desc)
        .pick(:scheduled_at)

      base = last_time ? last_time + rand(config.delay_range).minutes : Time.current
      [base, Time.current].max
    end

    private_class_method :next_slot
  end
end
