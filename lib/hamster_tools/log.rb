# frozen_string_literal: true

module Hamster
  module HamsterTools
    
    # prints passed string to STD_OUT, optionally the string can be colorized
    # @param [String] text A string that should be outputted
    # @param [Symbol] color Color which the string should be colorized
    # @param [Boolean] verbose Reserved
    def log(text, color = nil, verbose = false)
      text = color.nil? ? text : text.to_s.colorize(color)
      puts text if @debug || verbose
    end
  end
end
