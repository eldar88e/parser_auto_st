# frozen_string_literal: true


module Hamster
  private

  def self.grab
    @project_number = project_number
    @logger         = logger

    single   = !@arguments[:single].nil?
    instance = @arguments[:instance]
    number   = single ? @project_number : "#{@project_number}-#{instance}"

    load file

    log "Project #{number} was run.", :green

    begin
      scrape(@arguments)
    rescue Interrupt || SystemExit
      log "\nProject #{number} was interrupted by user.", :yellow
      exit 0
    rescue Exception => e
      log @debug ? e.full_message : e
      exit 1
    end

    # close_connection
    log "Project #{number} has done.", :green
    exit 0
  end
end
