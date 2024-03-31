# frozen_string_literal: true

module Hamster
  def self.close_connection(model)
    return unless model.ancestors.map(&:name).include?('ActiveRecord::Base')
    
    model.connection.close if model.connected?
    #model.flush_idle_connections!
    model.connection_handler.flush_idle_connections!
  end
end
