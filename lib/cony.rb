begin
  # activesupport 4
  require 'active_support/core_ext/object/deep_dup'
rescue LoadError
  # activesupport 3
  require 'active_support/core_ext/hash/deep_dup'
end
require 'active_support/configurable'

require 'cony/active_record'

module Cony
  include ActiveSupport::Configurable

  defaults = {
    durable: false
  }

  self.config.merge! defaults.deep_dup

end
