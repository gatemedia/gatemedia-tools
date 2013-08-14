require 'colored'

module Gem
  class Bundle

    def initialize
      @gatemedia_gems_root = nil
      @local_gems = `bundle config --no-color`.split("\n").keep_if { |line| is_local line }.collect { |line| gem_name line }
    end

    def point gem_name, private_gem, location
      return false if gem_name == 'gatemedia-tools'
      if (location == :local and not @local_gems.include? gem_name) or (location == :remote and @local_gems.include? gem_name)
        use gem_name, private_gem, location
        true
      else
        puts "Gem ".blue + gem_name.blue.bold + " already #{location}".blue
        false
      end
    end

    def refresh changes
      if changes.include? true
        puts "Refresh bundle".blue
        puts `sh -c "bundle --binstubs"`
      end
    end

    def update gems
      puts "Updating gems:".blue
      puts "  #{gems.join "\n  "}".blue.bold
      puts `bundle update #{gems.join ' '}`
    end

    private

    def gem_name gem_line
      /local\.(.+)/.match(gem_line)[1]
    end

    def is_local gem_line
      gem_line.strip.start_with? 'local.'
    end

    def use gem_name, private_gem, location
      case location
      when :local
        setup_env
        if private_gem
          path = "#{@gatemedia_private_gems_root}/#{gem_name}"
        else
          path = "#{@gatemedia_public_gems_root}/#{gem_name}"
        end
        puts "Point '#{gem_name}' to local clone @ #{path}".green
        `bundle config local.#{gem_name} #{path}`
      when :remote
        puts "Point '#{gem_name}' to remote repository".red
        `bundle config --delete local.#{gem_name}`
      end
    end

    def setup_env
      if @gatemedia_gems_root.nil?
        @gatemedia_gems_root = ENV['GATEMEDIA_GEMS_ROOT'] || "/Users/#{ENV['USER']}/Code/GateMedia"
        @gatemedia_public_gems_root = ENV['GATEMEDIA_PUBLIC_GEMS_ROOT'] || "#{@gatemedia_gems_root}/public"
        @gatemedia_private_gems_root = ENV['GATEMEDIA_PRIVATE_GEMS_ROOT'] || "#{@gatemedia_gems_root}/private"

        puts "GateMedia gems root @ #{@gatemedia_gems_root}".blue
        puts "  public  gems root @ #{@gatemedia_public_gems_root}".blue
        puts "  private gems root @ #{@gatemedia_private_gems_root}".blue

        def check_directory_existence directory
          unless File.directory? directory
            puts "Gems root directory does not exists! (#{directory})".red
            exit 1
          end
        end

        check_directory_existence @gatemedia_private_gems_root
        check_directory_existence @gatemedia_public_gems_root
      end
    end
  end


  class Gemfile

    def github_gems
      gemfile_lines.keep_if { |line|
        is_github_gem line
      }.collect { |line|
        gem_name line
      }
    end

    def is_private? gem_name
      gemfile_lines.keep_if { |line|
        /gem\s+['"](.+?)['"].+GITHUB_TOKEN/.match line
      }.collect { |line|
        gem_name line
      }.include? gem_name
    end


    private

    def gemfile_lines
      open('Gemfile').readlines
    end

    def is_github_gem line
      /^gem\s+['"](.+?)['"].+github.+branch:/.match line.strip
    end

    def gem_name line
      /['"](.+?)['"]/.match(line.strip)[1]
    end
  end


  module Manager

    def self.use_locals
      bundle = Bundle.new
      gemfile = Gemfile.new
      bundle.refresh gemfile.github_gems.collect { |gem_name|
        bundle.point gem_name, gemfile.is_private?(gem_name), :local
      }
    end

    def self.use_remotes
      bundle = Bundle.new
      gemfile = Gemfile.new
      bundle.refresh gemfile.github_gems.collect { |gem_name|
        bundle.point gem_name, gemfile.is_private?(gem_name), :remote
      }
    end

    def self.update
      gemfile = Gemfile.new
      github_gems = gemfile.github_gems
      bundle = Bundle.new
      bundle.update github_gems
    end
  end
end
