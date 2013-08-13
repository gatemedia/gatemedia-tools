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

  def self.use gem_name, location
    case location
    when :local
      if Gemfile::is_private? gem_name
        path = "#{GATEMEDIA_PRIVATE_GEMS_ROOT}/#{gem_name}"
      else
        path = "#{GATEMEDIA_PUBLIC_GEMS_ROOT}/#{gem_name}"
      end
      puts "Point '#{gem_name}' to local clone @ #{path}".green
      `bundle config local.#{gem_name} #{path}`
    when :remote
      puts "Point '#{gem_name}' to remote repository".red
      `bundle config --delete local.#{gem_name}`
    end
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
      refresh_bundle Gemfile::github_gems.collect { |gem_name|
        point gem_name, :local
      }
    end

    def use_remotes
      refresh_bundle Gemfile::github_gems.collect { |gem_name|
        point gem_name, :remote
      }
    end

    def point gem_name, location
      unless Bundle::local_gems.include? gem_name
        Bundle::use gem_name, location
        true
      else
        false
      end
    end

    def refresh_bundle changes
      if changes.include? true
        puts "Refresh bundle".blue
        puts `bundle --binstubs`
      end
    end
  end
end
