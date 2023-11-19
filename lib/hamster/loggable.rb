# frozen_string_literal: true

module Hamster
  module Loggable
    module ClassMethods
      def logger
        @logger = Hamster.logger
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def logger
      @logger = Hamster.logger
    end
  end
end
