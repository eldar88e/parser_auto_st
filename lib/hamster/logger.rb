# frozen_string_literal: true

module Hamster
  def self.logger
    Hamster::Logger.instance
  end

  class Logger < ::Logger
    include Singleton

    def initialize
      s        = Storage.new
      commands = Hamster.commands
      log_dir  = "#{ENV['HOME']}/my_parsing/project_#{Hamster.project_number}/log"
      log_file =
        if commands[:clone]&.is_a?(String)
          "#{commands[:clone].gsub('/', '-')}.log" 
        else
          "#{Hamster::PROJECT_DIR_NAME}_#{Hamster.project_number.to_s.gsub('/', '-')}.log"
        end
      log_path = "#{log_dir}/#{log_file}"
      FileUtils.mkdir_p(log_dir)
      # 50MB limit on a log-file per a project for production and unlimited in debug mode
      if Hamster.commands[:debug]
        super(log_path, datetime_format: '%m/%d/%Y %H:%M:%S')
      else
        super(log_path, 10, 5 * 1024 * 1024, datetime_format: '%m/%d/%Y %H:%M:%S', level: :info)
      end
    end

    # Overriding to check the debug text in the console
    def debug(progname = nil, &block)
      super(progname, &block)
      puts progname.to_s.greenish
    end
  end
end
