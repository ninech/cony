require 'active_support/configurable'

require 'cony/active_record'

module Cony
  include ActiveSupport::Configurable

  defaults = {
    durable: false
  }

  self.config.merge! defaults.deep_dup

end
