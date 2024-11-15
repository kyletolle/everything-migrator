# frozen_string_literal: true

require_relative "migrator/version"
require 'yaml'
require 'fileutils'
require 'date'  # Ensure Date class is loaded for YAML processing

module Everything
  class Migrator
    def initialize(root_path)
      @root_path = root_path || Dir.pwd
    end

    # Convert dash-case to Title Case
    def title_case(name)
      name.split('-').map(&:capitalize).join(' ')
    end

    # Migrate a single piece folder
    def migrate_piece(piece_name, keep_in_subfolder = false)
      begin
        puts "Migrating piece: #{piece_name}, keep_in_subfolder=#{keep_in_subfolder}"
        piece_folder = piece_name
        piece_path = File.join(@root_path, piece_folder)

        working_md_name = 'index.md'
        working_md_path = File.join(piece_path, working_md_name)
        index_yaml_path = File.join(piece_path, 'index.yaml')

        if File.exist?(working_md_path)
          # Determine the new name for the md file
          # Convert kebab-case to Title Case for the filename
          title_name = title_case(piece_folder)
          new_md_name = "#{title_name}.md"
          new_md_path = File.join(piece_path, new_md_name)

          # Rename the md file to the new name
          FileUtils.mv(working_md_path, new_md_path)
          puts "Renamed #{working_md_name} to #{new_md_name}"
          working_md_name = new_md_name
          working_md_path = new_md_path

          # If yaml exists, convert it to front matter
          if File.exist?(index_yaml_path)
            # Allow Date class in YAML loading
            yaml_content = YAML.safe_load_file(index_yaml_path, permitted_classes: [Date])
            yaml_front_matter = YAML.dump(yaml_content)

            md_content = File.read(working_md_path)
            File.open(working_md_path, 'w') do |file|
              file.puts("#{yaml_front_matter}---\n")
              file.puts(md_content)
            end
            File.delete(index_yaml_path)
            puts "Converted #{index_yaml_path} to front matter"
          end
        end

        if keep_in_subfolder
          puts "Keeping #{working_md_name} in subfolder"
          return;
        end

        # Move the new md file to the root level
        FileUtils.mv(working_md_path, @root_path) if File.exist?(working_md_path)
        puts "Moved #{working_md_name} to root level"

        # Move any other files to root level
        Dir.glob(File.join(piece_path, '*')).each do |file|
          next if file.end_with?('index.md') || file.end_with?('index.yaml')
          FileUtils.mv(file, @root_path)
        end
        puts "Moved other files to root level"

        # Remove the empty folder
        Dir.rmdir(piece_path) if Dir.empty?(piece_path)
        puts "Removed empty folder: #{piece_folder}"
      rescue StandardError => e
        puts "Error migrating piece: #{piece_name}"
        puts e.message
        return
      end
    end

    # Migrate all pieces or a single specified piece
    def migrate_pieces_v1_to_v2(keep_in_subfolder = false, skip_pieces = [])
      puts "Migrating `everything` project from piece version 1 to piece version 2 structure..."
      puts "Options: keep_in_subfolder=#{keep_in_subfolder}, skip_pieces=#{skip_pieces}"

      # Process all pieces in the root path
      Dir.foreach(@root_path) do |piece_folder|
        next if piece_folder == '.' || piece_folder == '..' || piece_folder.start_with?('_')
        next if skip_pieces.include?(piece_folder)

        piece_path = File.join(@root_path, piece_folder)
        next unless File.directory?(piece_path)
        piece_name = piece_folder

        begin
          migrate_piece(piece_name, keep_in_subfolder)
        rescue StandardError => e
          puts "Error migrating piece as part of batch: #{piece_folder}"
          puts e.message
        end
      end

      puts "Migration complete!"
    end
  end
end
