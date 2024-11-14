# frozen_string_literal: true

require_relative "migrator/version"
require 'yaml'
require 'fileutils'
require 'date'

module Everything
  class Migrator
    def initialize(root_path)
      @root_path = root_path || Dir.pwd
    end

    # Convert dash-case to Title Case
    def title_case(name)
      name.split('-').map(&:capitalize).join(' ')
    end

    def migrate_pieces_v1_to_v2
      puts "Migrating `everything` project from piece version 1 to piece version 2 structure..."

      Dir.foreach(@root_path) do |piece_folder|
        next if piece_folder == '.' || piece_folder == '..'

        piece_path = File.join(@root_path, piece_folder)
        next unless File.directory?(piece_path)

        index_md_path = File.join(piece_path, 'index.md')
        index_yaml_path = File.join(piece_path, 'index.yaml')

        if File.exist?(index_md_path)
          # Generate the new name based on the folder name
          new_md_name = "#{piece_folder}.md"
          new_md_path = File.join(@root_path, new_md_name)

          if File.exist?(index_yaml_path)
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

      puts "Migration complete!"
    end
  end
end
