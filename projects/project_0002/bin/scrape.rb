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
  elsif options[:export_google]
    manager.export_google
  end
rescue => error
  puts error.backtrace
  Hamster.logger.error error.message
  Hamster.report message: error.message
end