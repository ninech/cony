# Cony

Cony sends notifications about the lifecycle of your models via AMQP.


## Setup

### Rails 3 & 4

In Rails 3 and 4, add this to your Gemfile and run the bundle command.

    gem 'cony'

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
