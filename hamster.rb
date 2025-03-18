# frozen_string_literal: true

require 'active_record'
require 'active_support/all'
require 'active_support/message_encryptor'
require 'active_support/encrypted_file'
require 'colorize'
require 'csv'
require 'babosa'
require 'digest'
require 'dotenv'
require 'hashie'
require 'faraday'
require 'fileutils'
require 'nokogiri'
require 'mysql2'
require 'open-uri'
require 'pry'
require 'telegram/bot'
require 'emoji_regex'

Dotenv.load('.env')

require_relative 'lib/hamster'
require_relative 'lib/harvester'
require_relative 'lib/keeper'
require_relative 'lib/parser'
require_relative 'lib/scraper'
require_relative 'lib/storage'
require_relative 'lib/fake_agent'
require_relative 'lib/granary'

require_relative 'lib/specials/activerecord/mysql2_adapter_patch'
require_relative 'lib/specials/md5_hash'
require_relative 'lib/specials/aws_s3'
require_relative 'lib/specials/run_id'
require_relative 'lib/specials/number_in_words/numbers_in_words'

Hamster.wakeup
