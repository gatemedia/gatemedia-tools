
module GatemediaTools
  class Engine < ::Rails::Engine
  end

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/stage.rake'
    end
  end
end
