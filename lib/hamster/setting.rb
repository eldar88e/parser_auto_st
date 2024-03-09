# frozen_string_literal: true
require_relative '../models/setting'

module Hamster
  def self.settings
    Setting.first.attributes
  end
end