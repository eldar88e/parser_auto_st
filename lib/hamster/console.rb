# frozen_string_literal: true
# hamster console command 
# ruby hamster.rb --console=NNNN
module Hamster
  private
  def self.console
    @project_number = project_number
    puts " --project argument missing".red if @project_number.nil?

    return if @project_number.nil?

    s   = Storage.new
    directory_path = Dir["#{s.project}s/*"].find { |d| d[@project_number] }

    puts "Project #{@project_number} not found".red if directory_path.nil?
    return if directory_path.nil?
    model_files = Dir["#{directory_path}/models/*.rb"]
    lib_files =  Dir["#{directory_path}/lib/*.rb"]

    (lib_files + model_files).each do |file|
      require_relative "../../#{file}"
    end

    ARGV.clear
    IRB.start
  end
end
