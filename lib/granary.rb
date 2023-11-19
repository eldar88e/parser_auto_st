# frozen_string_literal: true

module Hamster
  module Granary
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def store(values)
        self.create!(values)
      rescue ActiveRecord::RecordNotUnique
        # To prevent not unique error
      end
      
      def list
        hash = {}
        self.columns.map { |column| hash[column.name.to_sym] = nil }
        hash
      end
      
      def flail
        list.map { |key, _| yield key } .to_h.compact
      end
    end
    
  end
end
