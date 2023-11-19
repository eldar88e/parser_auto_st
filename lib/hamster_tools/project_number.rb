# frozen_string_literal: true

module Hamster
  def self.project_number
    if @arguments[:grab]
      "%04d" % @arguments[:grab]
    elsif @arguments[:do]
      @arguments[:do]
    elsif @arguments[:console]
      "%04d" % @arguments[:console]
    elsif @arguments[:generate]
      "%04d" % @arguments[:generate]
    end
  end
end
