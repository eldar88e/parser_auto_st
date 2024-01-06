require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:bot]
    manager.bot
  end
rescue => error
  puts error.backtrace
  Hamster.logger.error error.message
  Hamster.report message: error.message
end