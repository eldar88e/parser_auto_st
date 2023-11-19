# frozen_string_literal: true

require_relative 'storage/use'

class Storage
  def initialize
    @arguments = @arguments || Hamster.parse_arguments
    #return if @arguments[:encrypt] || @arguments[:decrypt] || @arguments[:generate_key]

    #Storage.configure
  end
end
