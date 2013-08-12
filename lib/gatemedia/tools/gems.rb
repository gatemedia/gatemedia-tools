require 'colored'

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

    def self.use_local gem_name, path
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
end
