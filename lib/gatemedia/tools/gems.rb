require 'colored'

GATEMEDIA_GEMS_ROOT = ENV['GATEMEDIA_GEMS_ROOT'] || "/Users/#{ENV['USER']}/Code/GateMedia"
GATEMEDIA_PUBLIC_GEMS_ROOT = ENV['GATEMEDIA_PUBLIC_GEMS_ROOT'] || "#{GATEMEDIA_GEMS_ROOT}/public"
GATEMEDIA_PRIVATE_GEMS_ROOT = ENV['GATEMEDIA_PRIVATE_GEMS_ROOT'] || "#{GATEMEDIA_GEMS_ROOT}/private"

puts "GateMedia gems root @ #{GATEMEDIA_GEMS_ROOT}".blue
puts "  public  gems root @ #{GATEMEDIA_PUBLIC_GEMS_ROOT}".blue
puts "  private gems root @ #{GATEMEDIA_PRIVATE_GEMS_ROOT}".blue

def check_directory_existence directory
  unless File.directory? directory
    puts "Gems root directory does not exists! (#{directory})".red
    exit 1
  end
end

check_directory_existence GATEMEDIA_PRIVATE_GEMS_ROOT
check_directory_existence GATEMEDIA_PUBLIC_GEMS_ROOT


module Bundle

  def self.local_gems
    self.gem_lines.keep_if { |line| self.is_local line }.collect { |line| self.gem_name line }
  end

  def self.use_remote gem_name
    puts "Point '#{gem_name}' to remote repository".red
    `bundle config --delete local.#{gem_name}`
  end

  def self.use_local gem_name
    if Gemfile::is_private? gem_name
      path = "#{GATEMEDIA_PRIVATE_GEMS_ROOT}/#{gem_name}"
    else
      path = "#{GATEMEDIA_PUBLIC_GEMS_ROOT}/#{gem_name}"
    end
    puts "Point '#{gem_name}' to local clone @ #{path}".green
    `bundle config local.#{gem_name} #{path}`
  end


  private

  def self.gem_lines
    `bundle config --no-color`.split "\n"
  end

  def self.gem_name gem_line
    /local\.(.+)/.match(gem_line)[1]
  end

  def self.is_local gem_line
    gem_line.strip.start_with? 'local.'
  end
end


module Gemfile

  def self.github_gems
    self.gemfile_lines.keep_if { |line|
        self.is_github_gem line
    }.collect { |line|
        self.gem_name line
    }
  end

  def self.is_private? gem_name
    self.gemfile_lines.keep_if { |line|
        /gem\s+['"](.+?)['"].+GITHUB_TOKEN/.match line
    }.collect { |line|
        self.gem_name line
    }.include? gem_name
  end


  private

  def self.gemfile_lines
    open('Gemfile').readlines
  end

  def self.is_github_gem line
    /^gem\s+['"](.+?)['"].+github.+branch:/.match line.strip
  end

  def self.gem_name line
    /['"](.+?)['"]/.match(line.strip)[1]
  end
end


module Gem
  class Manager

    def use_locals
      dirties = Gemfile::github_gems.collect { |gem_name|
        self.use_local gem_name
      }
      if dirties.include? true
        puts "Refresh bundle".magenta
        puts `bundle --binstubs`
      end
    end
  
    def use_local gem_name
      dirtyBundler = false
      unless Bundle::local_gems.include? gem_name
          Bundle::use_local gem_name
          dirtyBundler = true
      end

      dirtyBundler
    end

    def use_remotes
      dirties = Gemfile::github_gems.collect { |gem_name|
        self.use_remote gem_name
      }
      if dirties.include? true
        puts "Refresh bundle".magenta
        puts `bundle --binstubs`
      end
    end

    def use_remote gem_name
      dirtyBundler = false
      if Bundle::local_gems.include? gem_name
          Bundle::use_remote gem_name
          dirtyBundler = true
      end

      dirtyBundler
    end
  end
end
