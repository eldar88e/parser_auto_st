# frozen_string_literal: true

module Hamster
  def self.wakeup(arguments = {})
    @debug = false
    if $0.end_with?("rspec")
      @arguments = arguments
    else
      parse_arguments
    end

    @debug = true if ENV.fetch('DEBUG', @arguments[:debug])

    Hamster.grab if @arguments[:grab]
    Hamster.dig if @arguments[:dig]
    #Hamster.do if @arguments[:do]
    Hamster.console if @arguments[:console] or @arguments[:c]
    Hamster.generate(@arguments) if @arguments[:generate] or @arguments[:g]
  end
end
