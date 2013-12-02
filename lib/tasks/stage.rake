
def stage branch, options={}
    branches = `git branch`.split "\n"
    current_branch = branches.find { |b| b[0] == '*' }.split.last.to_sym

    changes = `git status -s`.rstrip
    unless changes.empty?
        puts 'You have pending changes, which will not be deployed!'.red
        puts changes.blue
        print 'Do you wish to continue? (yN) '
        case STDIN.getc.downcase
        when 'y'
            puts 'Continuing...'
        else
            puts 'Deployment aborted'.red
            return
        end
        `git stash save -a`
        puts 'Changes saved'
    end
    unless branch == current_branch
        puts "Switching to branch [#{branch}]"
        `git checkout #{branch}`
    end

    merge_source = options.fetch :merge, nil
    unless merge_source.nil?
        puts "Merge [#{merge_source}] to [#{branch}]"
        `git merge #{merge_source}`
        `git push`
    end

    puts "Deploying to #{branch} stage".green
    `git push sg-#{branch} #{branch}:master`
    `heroku config:set GIT_HASH=$(git rev-parse --verify HEAD) --app=sg-#{branch}`

    unless branch == current_branch
        puts "Switching back to branch [#{current_branch}]"
        `git checkout #{current_branch}`
    end
    unless changes.empty?
        `git stash pop`
        puts 'Changes restored'
    end
    puts "Deployment to #{branch} done".green

    exit # avoid double-run... weird!
end


namespace :stage do

    desc "Deploy to development stage"
    task :dev do
        stage :dev
    end

    desc "Deploy to production stage"
    task :prod do
        stage :master, merge: :dev
    end
end
