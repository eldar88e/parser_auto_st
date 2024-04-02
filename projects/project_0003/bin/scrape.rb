require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:import]
    manager.import
  end
rescue => error
  puts error.full_message if commands[:debug]
  Hamster.logger.error error.message
  Hamster.report message: error.message
end