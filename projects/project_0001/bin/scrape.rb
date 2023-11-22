require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    manager.store
  end
rescue => error
  puts error.backtrace
  Hamster.report message: error.message
  Hamster.logger.error error
end