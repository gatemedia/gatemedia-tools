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
    def self.config
        `bundle config`.split "\n"
    end

    def self.gem_names lines
        lines.collect { |line| /local\.(.+)/.match(line)[1] }
    end

    def self.local_gems lines
        lines.keep_if { |line| line.start_with? 'local.' }
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
end

module Gemfile
    def self.lines
        open('Gemfile').readlines
    end

    def self.gem_names lines
        lines.collect { |line| /['"](.+?)['"]/.match(line.strip)[1] }
    end

    def self.github_gems lines
        lines.keep_if { |line| /gem\s+['"](.+?)['"].+github.+/.match(line.strip) }
    end

    def self.gems lines
        lines.keep_if { |line| line.strip.start_with? 'gem ' }
    end

    def self.is_private? gem_name
        self.gem_names(self.private_gems(self.lines)).include? gem_name
    end

    def self.private_gems lines
        lines.keep_if { |line| /^gem\s+.+@github\.com.+/.match(line) }
    end

    def self.comment_github_ref gem_name
        lines = self.lines.collect { |line|
            if /^# gem '#{gem_name}', git:.*/.match line
                line[2..-1]
            elsif /^gem '#{gem_name}', github:.*/.match line
                "# #{line}"
            else
                line
            end
        }
        open('Gemfile', 'w').write lines.join
    end

    def self.uncomment_github_ref gem_name
        lines = self.lines.collect { |line|
            if /^# gem '#{gem_name}', github:.*/.match line
                line[2..-1]
            elsif /^gem '#{gem_name}', git:.*/.match line
                "# #{line}"
            else
                line
            end
        }
        open('Gemfile', 'w').write lines.join
    end
end
