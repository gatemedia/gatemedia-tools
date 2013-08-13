
port = ENV['PORT']

desc "Run developement server on port #{port}"
task :run do
    unless port
        puts "Missing environment variable PORT...".red
        exit 1
    end
    `rm -rf tmp/cache; bin/unicorn_rails -p #{port}`
end
