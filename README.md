# :rabbit: Cony [![Build Status](https://travis-ci.org/ninech/cony.svg)](https://travis-ci.org/ninech/cony) [![Code Climate](https://codeclimate.com/github/ninech/cony.png)](https://codeclimate.com/github/ninech/cony)

Cony sends notifications about the lifecycle of your models via AMQP.

## Setup

### Rails

In Rubo on Rails add this to your Gemfile and run `bundle install`.

```ruby
gem 'cony'
```

To configure the AMQP-Settings, use an initializer (e.g.
`config/initializers/cony.rb`) with the following content.

```ruby
Cony.configure do |config|
  config.amqp = {
    host: 'localhost',
    exchange: 'organization.application',
    ssl: true,
    user: 'username',
    pass: 'secret',
  }
  config.test_mode = Rails.env.test?
  # config.durable = false
end
```

## Getting Started

To enable the notifications for a model, you just need to include the
corresponding class. For `ActiveRecord` use the following snippet.

```ruby
class ExampleModel < ActiveRecord::Base
  include Cony::ActiveRecord
end
```

## Message Format

The routing key for the messages have a format of
`model_name_with_underscore.mutation.event_type`.

It will append the id of the model and the detected changes to the payload of the message.

### Create

A create for a `Example::Model` model will have a routing key of
`example/model.mutation.created`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": [
    { "name": { "old": null, "new": "value" } },
    { "description": { "old": null, "new": "value" } }
  ],
  "event": "created",
  "model": "Example::Model",
}
```

### Update

An update for a `Example::Model` model will have a routing key of
`example/model.mutation.updated`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": [
    { "name": { "old": "old-value", "new": "new-value" } }
  ],
  "event": "updated",
  "model": "Example::Model",
}
```

### Destroy

A destroy event for a `Example::Model` model will have a routing key of
`example/model.mutation.destroyed`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": [
    { "name": { "old": "value", "new": null } }
  ],
  "event": "destroyed",
  "model": "Example::Model",
}
```

## About

This gem is currently maintained and funded by [nine](https://nine.ch).
