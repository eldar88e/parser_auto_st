# frozen_string_literal: true

module Hamster
  module HamsterTools
    def check_encrypt_decrypt_options
      hash = {}
      begin
        File.read('secrets/master.key')
      rescue
        raise "File 'secrets/master.key' must exist for 'encrypt' or 'decrypt' arguments as well as most other arguments. Please download it"\
        " and place it in the 'secrets' folder, you can find it here - https://locallabs.slack.com/archives/G01CY84KMT6/p1682986459429189"
      end

      if @arguments[:encrypt] && !@arguments[:decrypt]        
        source_path = @arguments[:encrypt].sub(/^\//,'')
        destination_path = "secrets/#{File.basename(@arguments[:encrypt].sub(/^\//,''))}.enc"
        check_source_and_destinations(hash, source_path, destination_path)
      elsif @arguments[:decrypt] && !@arguments[:encrypt]
        source_path = "secrets/#{@arguments[:decrypt]}"
        destination_path = @arguments[:to] ? @arguments[:to].sub(/^\//,'') : "/"
        check_source_and_destinations(hash, source_path, destination_path)
      else
        raise "Option conflict, you can't run both 'encrypt' and 'decrypt' options at the same time."
      end
      hash
    end

    def check_source_and_destinations(hash, source_path, destination_path)
      check_source_file(hash, source_path)
      check_dest = check_destination_file(hash, destination_path)
      if check_dest == "Invalid input. Command canceled." || check_dest == "Command canceled."
        puts check_dest
        exit 0
      end
      check_key_file(hash)
    end

    def check_source_file(hash, source_path)
      begin
        hash.store((@arguments[:encrypt] ? :encrypt : :decrypt),File.read(source_path))
      rescue
        raise "The file path must be valid for '#{(@arguments[:encrypt] ? 'encrypt' : 'decrypt')}'."\
        " File path '#{source_path}' doesn't exist."
      end
    end

    def check_destination_file(hash, destination_path)
      if @arguments[:decrypt] && @arguments[:to] && @arguments[:to] != "/"
        unless @arguments[:to].include?(@arguments[:decrypt].gsub(/.+(\..*)\.enc$/,'\1'))
          raise "The file in '--to' path must be the same type of file (minus the '.enc') as the file in the '--decrypt' option."

          return
        end
      end

      begin
        destination_path = @arguments[:decrypt].gsub(/(\/|\.enc)/,'') if destination_path=="/"
        File.read(destination_path)
      rescue
        hash.store(:to,destination_path) if @arguments[:decrypt]
      else
        puts "File \"#{destination_path}\" already exists, are you sure you want to overwrite it? (Y/N)"
        i = 0
        while i <= 2
          input = IO.console.gets
          input = input.chomp unless input.nil? || input.empty?
          if input =~ /^y(es)?$/i
            hash.store(:to,destination_path) if @arguments[:decrypt]
            puts "File being overwritten..."
            break
          elsif input =~ /^n(o)?$/i
            return "Command canceled."
          else
            puts "Invalid input, please try again. Are you sure you want to overwrite it? (Y/N)" unless i == 2
          end
          i += 1
        end
        return "Invalid input. Command canceled." if i==3
      end
    end

    def check_key_file(hash)
      if @arguments[:with]
        begin
          hash.store(:with, File.read("secrets/#{@arguments[:with]}.key"))
        rescue
          raise "Secret key does not exist 'secrets/#{@arguments[:with]}.key', "\
                "--with option must be name of secret key in '/secrets'"
        end
      else
        hash.store(:with, File.read("secrets/master.key").strip)
      end
    end

    def decrypt_file(options)
      begin
        raise "File is not encrypted (.enc), so it can't be decrypted." unless @arguments[:decrypt] =~ /\.enc$/
        secret_key = options[:with]
        encryptor = ActiveSupport::MessageEncryptor.new(secret_key)
        decrypted = encryptor.decrypt_and_verify(options[:decrypt])
        file_write_path = options[:to]
        FileUtils.mkdir_p(File.dirname(file_write_path))
        File.write(file_write_path, decrypted)
        return puts "Operation successful."
      rescue => e
        raise "Error decrypting file '#{@arguments[:decrypt]}': #{e.message =~ /InvalidSignature/ ? "Wrong secret key - #{e.message}" : e.message}"
      end
    end

    def encrypt_file(options)
      begin
        secret_key = options[:with]
        encryptor = ActiveSupport::MessageEncryptor.new(secret_key)

        encrypted_file = encryptor.encrypt_and_sign(options[:encrypt])

        encrypt_path = "secrets/#{File.basename(@arguments[:encrypt].sub(/^\//,''))}.enc"
        File.write(encrypt_path, encrypted_file)
        return puts "Operation successful."
      rescue => e
        raise "Error encrypting file '#{@arguments[:encrypt]}': #{e.message}"
      end
    end

    def check_key_name
      valid_regex = /^[a-zA-Z0-9_\-.]+$/
      
      raise "You cannot regenerate the master.key, you must download it here - https://locallabs.slack"\
      ".com/archives/G01CY84KMT6/p1682986459429189." if @arguments[:generate_key]=="master"

      if @arguments[:generate_key] =~ valid_regex
        begin
          if File.read("secrets/#{@arguments[:generate_key]}.key")
            puts "File \"secrets/#{@arguments[:generate_key]}.key\" already exists, are you sure you want to overwrite it? (Y/N)"
            i = 0
            while i <= 2
              input = IO.console.gets.chomp
              if input =~ /^y(es)?$/i
                return "exists"
              elsif input =~ /^n(o)?$/i
                return "canceled"
              else
                puts "Invalid input, please try again. Are you sure you want to overwrite it? (Y/N)" unless i == 2
              end
              i += 1
            end
            return "Invalid input. Command canceled."
          end
        rescue
          return true
        end
      else
        return false
      end
    end
  end
end
