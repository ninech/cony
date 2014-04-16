# Cony

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
    exchange: 'organization.application'
  }
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
`model_name_with_underscore.mutation.action`.

It will append the id of the model and the detected changes to the payload of the message.

### Create

A create for a `Example::Model` model will have a routing key of
`example/model.mutation.create`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": [
    { "name": { "old": null, "new": "value" } },
    { "description": { "old": null, "new": "value" } }
  ]
}
```


### Update

An update for a `Example::Model` model will have a routing key of
`example/model.mutation.update`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": [
    { "name": { "old": "old-value", "new": "new-value" } }
  ]
}
```


### Destroy

A destroy event for a `Example::Model` model will have a routing key of
`example/model.mutation.destroy`.

The sent JSON structure will look like this:

```json
{
  "id": 1337,
  "changes": []
}
```

