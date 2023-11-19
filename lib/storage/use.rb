# frozen_string_literal: true

class Storage
  def self.use(host:, db:)
    @arguments = @arguments || Hamster.parse_arguments
    return if @arguments[:encrypt] || @arguments[:decrypt] || @arguments[:generate_key]

    #@databases || self.configure
    #@databases[host].merge(database: db)
  end
  
  def self.[](host:, db:)
    self.use(host: host, db: db)
  end
end
