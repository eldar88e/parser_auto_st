# frozen_string_literal: true

module Hamster
  
  # Mixin class needed to organize access to command-line arguments, classes and methods working with file system
  class Harvester
    attr_reader :logger
    # @return [Hash] contains command-line arguments
    def commands
      @_commands_
    end

    def settings
      @settings_
    end
    
    # @return [String] path Hamster storehouse directory
    def storehouse
      @_storehouse_
    end
    
    # @return [Peon] an instance of Peon
    def peon
      @_peon_
    end

    def json_saver
      @_json_saver_
    end
    
    private
    
    def initialize(*_)
      @_storehouse_ = "#{ENV['HOME']}/my_parsing/project_#{Hamster.project_number}/"
      @_peon_       = Hamster::Harvester::Peon.new(storehouse)
      @_json_saver_ = Hamster::Harvester::JsonSaver.new(storehouse)
      @_commands_   = Hamster.commands
      @_commands_[:debug] ||= ENV.fetch('DEBUG', false)
      @logger    = Hamster.logger
      @settings_ = nil # Hamster.settings
    end
  end
end
