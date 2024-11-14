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
    def migrate_piece(piece_path)
      piece_folder = File.basename(piece_path)

      index_md_path = File.join(piece_path, 'index.md')
      index_yaml_path = File.join(piece_path, 'index.yaml')

      if File.exist?(index_md_path)
        # Generate the new name based on the folder name
        new_md_name = "#{piece_folder}.md"
        new_md_path = File.join(@root_path, new_md_name)

        if File.exist?(index_yaml_path)
          # Allow Date class in YAML loading
          yaml_content = YAML.safe_load_file(index_yaml_path, permitted_classes: [Date])
          yaml_front_matter = YAML.dump(yaml_content)

          md_content = File.read(index_md_path)
          File.open(new_md_path, 'w') do |file|
            file.puts("#{yaml_front_matter}---\n")
            file.puts(md_content)
          end
          File.delete(index_yaml_path)
        else
          FileUtils.mv(index_md_path, new_md_path)
        end

        # Delete the original index.md explicitly
        File.delete(index_md_path) if File.exist?(index_md_path)

        # Convert to Title Case for the final filename
        title_name = title_case(piece_folder)
        final_md_name = "#{title_name}.md"

        # Avoid renaming if the only difference is in case
        unless new_md_name.downcase == final_md_name.downcase
          temp_name = "#{new_md_name}.tmp"
          FileUtils.mv(new_md_path, File.join(@root_path, temp_name))
          FileUtils.mv(File.join(@root_path, temp_name), File.join(@root_path, final_md_name))
        end
      end

      # Move any other files to root level
      Dir.glob(File.join(piece_path, '*')).each do |file|
        next if file.end_with?('index.md') || file.end_with?('index.yaml')
        FileUtils.mv(file, @root_path)
      end

      # Remove the empty folder
      Dir.rmdir(piece_path) if Dir.empty?(piece_path)
    end

    # Migrate all pieces or a single specified piece
    def migrate_pieces_v1_to_v2(single_piece_path = nil)
      puts "Migrating `everything` project from piece version 1 to piece version 2 structure..."

      if single_piece_path
        # Process a single specified piece
        migrate_piece(single_piece_path)
      else
        # Process all pieces in the root path
        Dir.foreach(@root_path) do |piece_folder|
          next if piece_folder == '.' || piece_folder == '..'

          piece_path = File.join(@root_path, piece_folder)
          next unless File.directory?(piece_path)

          begin
            migrate_piece(piece_path)
          rescue StandardError => e
            puts "Error migrating piece: #{piece_folder}"
            puts e.message
          end
        end
      end

      puts "Migration complete!"
    end
  end
end
