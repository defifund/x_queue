# XQueue

A Rails engine for scheduling and posting tweet threads to X (Twitter).

Drop it into any Rails app — configure your API keys, schedule tweets or threads, and let the background jobs handle posting with automatic reply chaining.

## Installation

Add to your Gemfile:

```ruby
gem "x_queue"
```

Run the installer:

```bash
bundle install
bin/rails generate x_queue:install
bin/rails db:migrate
```

This creates:
- `config/initializers/x_queue.rb` — configuration file
- `db/migrate/xxx_create_x_queue_tweets.rb` — tweets table

## Configuration

```ruby
# config/initializers/x_queue.rb
XQueue.configure do |config|
  config.api_key        = Rails.application.credentials.dig(:x, :api_key)
  config.api_key_secret = Rails.application.credentials.dig(:x, :api_key_secret)

  # Optional
  config.delay_range        = 20..40  # minutes between independent tweets
  config.thread_delay_range = 1..5    # minutes between thread replies
  config.queue_name         = :default
end
```

## Usage

### Schedule independent tweets

Each tweet is posted separately, spaced out by `delay_range` minutes.

```ruby
XQueue::Scheduler.tweets(
  texts: ["First tweet", "Second tweet"],
  account: user_account,
  source: article,  # optional, any ActiveRecord model
  not_before: article.published_at # optional
)
```

### Schedule a thread

Tweets are posted as a reply chain. The first tweet posts at the scheduled time, then each subsequent tweet replies to the previous one.

```ruby
XQueue::Scheduler.thread(
  texts: [
    "1/3 Here's something interesting...",
    "2/3 Let me explain further...",
    "3/3 In conclusion..."
  ],
  account: user_account,
  source: article, # optional
  not_before: article.published_at # optional
)
```

`not_before` guarantees the first scheduled tweet is not earlier than a given
time. This is useful when tweets promote content that has a future
`published_at`.

### Polymorphic source

The `source` parameter accepts any ActiveRecord model. This lets you track which model generated the tweets:

```ruby
# In your model
class Article < ApplicationRecord
  has_many :tweets, as: :source, class_name: "XQueue::Tweet"
end
```

### Query tweets

```ruby
# All tweets for a source
XQueue::Tweet.where(source: article)

# Pending tweets
XQueue::Tweet.scheduled

# Failed tweets
XQueue::Tweet.failed
```

## How it works

```
Schedule → Create Tweet records (status: scheduled)
               ↓
         PostTweetJob fires at scheduled_at
               ↓
         Post to X API → update status to :posted
               ↓
         If thread → enqueue next tweet as reply
               ↓
         Repeat until thread complete
```

- Independent tweets: each gets its own job, spaced by `delay_range`
- Threads: first tweet triggers a chain — each job posts one tweet, then enqueues the next with `thread_delay_range` delay
- Failed tweets are marked `status: :failed` and logged

## License

MIT License. See [LICENSE](LICENSE).
