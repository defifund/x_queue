# frozen_string_literal: true

require "x"

module XQueue
  class Client
    def initialize(access_token:, access_token_secret:)
      config = XQueue.configuration

      @client = X::Client.new(
        api_key: config.api_key,
        api_key_secret: config.api_key_secret,
        access_token: access_token,
        access_token_secret: access_token_secret
      )
    end

    def post(text, reply_to_tweet_id: nil)
      body = {text: text}
      body[:reply] = {in_reply_to_tweet_id: reply_to_tweet_id} if reply_to_tweet_id
      @client.post("tweets", body.to_json)
    end
  end
end
