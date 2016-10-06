begin
  # activesupport 4
  require 'active_support/core_ext/object/deep_dup'
rescue LoadError
  # activesupport 3
  require 'active_support/core_ext/hash/deep_dup'
end
require 'active_support/configurable'

require 'cony/active_record'

##
# To configure Cony:
# <code>
# Cony.configure do |config|
#   config.amqp = {
#     host: 'localhost',
#     exchange: 'organization.application',
#     ssl: true,
#     user: 'username',
#     pass: 'secret',
#   }
#   config.test_mode = Rails.env.test?
#   # config.durable = false
# end
# </code>
module Cony
  include ActiveSupport::Configurable

  defaults = {
    durable: false,
    test_mode: false,
  }

  self.config.merge! defaults.deep_dup

end
