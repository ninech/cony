# :rabbit: Cony [![Build Status](https://travis-ci.org/ninech/cony.svg)](https://travis-ci.org/ninech/cony) [![Code Climate](https://codeclimate.com/github/ninech/cony.png)](https://codeclimate.com/github/ninech/cony)

Cony sends notifications about the lifecycle of your models via AMQP.


## Setup

### Rails 3 & 4

In Rails 3 and 4, add this to your Gemfile and run the bundle command.

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

### Using an existing Bunny connection

You can share your already established `Bunny::Session` with Cony.

```ruby
Cony::AMQPConnection.instance.connection = your_connection
```

Cony will only accept the given connection if it's current connection is closed or if there is no current
connection. There will be an error if Cony already has a connection!
This restriction is imposed because else Cony might leak connections.

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

