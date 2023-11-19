# frozen_string_literal: true

module Hamster
  module HamsterTools
    def file
      return if @project_number.nil?
      
      s   = Storage.new
      dir = Dir["projects/*"].find { |d| d[%r{projects/project_#{@project_number}.*}] }
      bin = "#{dir}/bin"
      entry_point = Dir.exist?(bin) ? bin : dir
      Dir["#{entry_point}/*"].find { |f| f[%r{#{entry_point}/\w*scrape.rb}] }
    end
  end
end
