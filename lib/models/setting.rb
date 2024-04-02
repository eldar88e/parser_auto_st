class Setting < ActiveRecord::Base
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE'),
                       username: ENV.fetch('USERNAME'),
                       password: ENV.fetch('PASSWORD'))

  self.inheritance_column = :_type_disabled

  #ActiveRecord::Base.logger = Logger.new($stdout)
  #self.logger = Logger.new(STDOUT)
end
