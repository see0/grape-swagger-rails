require 'git'

namespace :swagger_ui do
  namespace :dist do
    desc "Update Swagger-UI from wordnik/swagger-ui."
    task :update do
      Dir.mktmpdir 'swagger-ui' do |dir|
        puts "Cloning into #{dir} ..."
        # clone wordnik/swagger-ui
        Git.clone 'git@github.com:swagger-api/swagger-ui.git', 'swagger-ui', path: dir
        # prune local files
        root = File.expand_path '../../..', __FILE__
        puts "Removing files from #{root} ..."
        repo = Git.open root
        # Javascripts
        puts "Copying Javascripts ..."
        FileUtils.rm_r "#{root}/app/assets/javascripts/grape_swagger_rails"
        FileUtils.cp_r "#{dir}/swagger-ui/dist/lib", "#{root}/app/assets/javascripts"
        FileUtils.mv "#{root}/app/assets/javascripts/lib", "#{root}/app/assets/javascripts/grape_swagger_rails"
        FileUtils.cp_r Dir.glob("#{dir}/swagger-ui/dist/swagger-ui.min.js"), "#{root}/app/assets/javascripts/grape_swagger_rails"
        FileUtils.cp Dir.glob("#{root}/lib/javascripts/*.js"), "#{root}/app/assets/javascripts/grape_swagger_rails"
        # Generate application.js

        javascript_files = Dir["#{root}/app/assets/javascripts/grape_swagger_rails/*.js"].map { |f|
            f.split('/').last
        } - ['application.js']

        File.open "#{root}/app/assets/javascripts/grape_swagger_rails/application.js", "w+" do |file|
          javascript_files.each do |filename|
                file.write "//= require ./#{File.basename(filename, '.*')}\n"
          end

          file.write "//= require_tree .\n"
        end
        # Stylesheets
        puts "Copying Stylesheets ..."
        repo.remove 'app/assets/stylesheets/grape_swagger_rails', recursive: true
        FileUtils.mkdir_p "#{root}/app/assets/stylesheets/grape_swagger_rails"
        FileUtils.cp_r Dir.glob("#{dir}/swagger-ui/dist/css/**/*"), "#{root}/app/assets/stylesheets/grape_swagger_rails"
        repo.add 'app/assets/stylesheets/grape_swagger_rails'
        # Generate application.js
        CSS_FILES = [
            'reset.css',
            'print.css',
            'style.css',
            'typography.css',
            'screen.css'
        ]
        css_files = Dir["#{root}/app/assets/stylesheets/grape_swagger_rails/*.css"].map { |f|
            f.split('/').last
        } - ['application.css']
        (css_files - CSS_FILES).each do |filename|
            puts "WARNING: add #{filename} to swagger_ui.rake"
        end
        (CSS_FILES - css_files).each do |filename|
            puts "WARNING: remove #{filename} from swagger_ui.rake"
        end
        # rewrite screen.css into screen.css.erb with dynamic image paths
        File.open "#{root}/app/assets/stylesheets/grape_swagger_rails/screen.css.erb", "w+" do |file|
            contents = File.read "#{root}/app/assets/stylesheets/grape_swagger_rails/screen.css"
            contents.gsub! /url\((\'*).*\/(?<filename>[\w\.]*)(\'*)\)/ do |match|
                "url(<%= image_path('grape_swagger_rails/#{$~[:filename]}') %>)"
            end
            file.write contents
            FileUtils.rm "#{root}/app/assets/stylesheets/grape_swagger_rails/screen.css"
        end

        File.open "#{root}/app/assets/stylesheets/grape_swagger_rails/typography.css.erb", "w+" do |file|
          contents = File.read "#{root}/app/assets/stylesheets/grape_swagger_rails/typography.css"
          contents.gsub! /url\((\'*).*\/(?<filename>[\w\.\-\?\#]*)(\'*)\)/ do |match|
            data = $~[:filename]
            if data.include? '?#'
              d = data.split("?#")
              "url(<%= font_path('grape_swagger_rails/#{d[0]}') %>?##{d[1]})"
            elsif data.include? '#'
              d = data.split("#")
              "url(<%= font_path('grape_swagger_rails/#{d[0]}') %>##{d[1]})"
            else
             "url(<%= font_path('grape_swagger_rails/#{$~[:filename]}') %>)"
            end
          end
          file.write contents
          FileUtils.rm "#{root}/app/assets/stylesheets/grape_swagger_rails/typography.css"
        end


        File.open "#{root}/app/assets/stylesheets/grape_swagger_rails/application.css", "w+" do |file|
            file.write "/*\n"
            CSS_FILES.each do |filename|
                file.write "*= require ./#{File.basename(filename, '.*')}\n"
            end
            file.write "*= require_self\n"
            file.write "*/\n"
        end
        # Images
        puts "Copying Images ..."
        # repo.remove 'app/assets/images/grape_swagger_rails', recursive: true
        FileUtils.mkdir_p "#{root}/app/assets/images/grape_swagger_rails"
        FileUtils.cp_r Dir.glob("#{dir}/swagger-ui/dist/images/**/*"), "#{root}/app/assets/images/grape_swagger_rails"

        #fonts
        puts "Copying Fonts ..."
        # repo.remove 'app/assets/fonts/grape_swagger_rails', recursive: true
        FileUtils.mkdir_p "#{root}/app/assets/fonts/grape_swagger_rails"
        FileUtils.cp_r Dir.glob("#{dir}/swagger-ui/dist/fonts/**/*"), "#{root}/app/assets/fonts/grape_swagger_rails"

        #add stuffs back
        repo.add 'app/assets'
      end
    end
  end
end
