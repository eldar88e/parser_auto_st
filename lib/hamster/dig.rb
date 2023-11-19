# frozen_string_literal: true

module Hamster
  private
  
  def self.dig
    @project_number = @arguments[:dig]
    
    project_dirs  = {
      bin:    'bin/',
      lib:    'lib/',
      models: 'models/',
      sql:    'sql/'
    }
    project_files = {
      entry_point:  'scrape.rb',
      default_sql: 'default.sql',
      default_runs_sql:  'default_runs.sql',
      readme_file:  'README.md',
      place_keeper: '.gitkeep'
    }
    root_dir      = "projects/project_%04d/" % @project_number
    current_month = "\n_#{Date.today.strftime("%B %Y")}_\n"
    logging       = -> (path, &block) { block[path]; log "#{path} was created", :green, true }
    file_read     = -> (file_name) { File.read("templates/#{file_name}") }
    
    log "\n", nil, true
    project_dirs.values.each do |dir|
      logging.(root_dir + dir) { |path| FileUtils.mkdir_p(path) }
      
      case dir
      when project_dirs[:bin]
        logging.(root_dir + dir + project_files[:entry_point]) { |path| File.write(path, file_read[project_files[:entry_point]]) }
      when project_dirs[:sql]
        logging.(root_dir + dir + project_files[:default_sql]) { |path| File.write(path, file_read[project_files[:default_sql]]) }
        logging.(root_dir + dir + project_files[:default_runs_sql]) { |path| File.write(path, file_read[project_files[:default_runs_sql]]) }
      else
        logging.(root_dir + dir + project_files[:place_keeper]) { |path| FileUtils.touch(path) }
      end
    end
    
    logging.(root_dir + project_files[:readme_file]) { |path| File.write(path, file_read[project_files[:readme_file]] + current_month) }
    
    log "\nNow try to open '#{root_dir}/#{project_dirs[:bin]}/#{project_files[:entry_point]}' with your editor or IDE,"
    log 'write your code there and run it.'
  end
end
