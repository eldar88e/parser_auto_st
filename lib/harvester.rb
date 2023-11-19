# frozen_string_literal: true

module Hamster
  
  # Mixin class needed to organize access to command-line arguments, classes and methods working with file system
  class Harvester
    attr_reader :logger
    # @return [Hash] contains command-line arguments
    def commands
      @_commands_
    end
    
    # @return [String] path Hamster storehouse directory
    def storehouse
      @_storehouse_
    end
    
    # @return [Peon] an instance of Peon
    def peon
      @_peon_
    end
    
    private
    
    def initialize(*_)
      s              = Storage.new
      @_storehouse_  = "#{ENV['HOME']}/my_parsing/project_#{Hamster.project_number}/"
      @_peon_        = Hamster::Harvester::Peon.new(storehouse)
      @_commands_    = Hamster.commands
      @logger        = Hamster.logger
    end
  end
end
