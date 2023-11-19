# frozen_string_literal: true

module Hamster
  # @return [Hash] all the command-line arguments as Hash with symbolic and string keys both.
  def self.commands
    @arguments
  end
end
