module Cony
  class ValidConnectionAlreadyDefined < StandardError
    def initialize
      super 'A connection has already been set.'
    end
  end
end
