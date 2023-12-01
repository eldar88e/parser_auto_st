# frozen_string_literal: true
require_relative '../models/setting'

module Hamster
  def self.settings
    Setting.first.attributes.to_a[1..-3].to_h
  end
end