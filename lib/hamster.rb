# frozen_string_literal: true

# Main class. Needed to create base file structure, launch projects and other stuff.
# Contains module HamsterTools
require_relative 'hamster_tools'    # extends class Hamster with several methods
# and following methods:
require_relative 'hamster/grab'     # launches projects
require_relative 'hamster/wakeup'   # gets command-line arguments and runs the method was called
require_relative 'hamster/console'  # launch console for the given project number
require_relative 'hamster/logger'   # create a new logger
require_relative 'hamster/loggable' # inject the logger object

module Hamster
  PROJECT_DIR_NAME = 'my_project'

  extend HamsterTools
end
