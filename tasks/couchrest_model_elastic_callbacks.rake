require 'couchrest_model'

namespace :couchrest do
  desc 'Initialize Elasticsearch river'
  task :init_elasticsearch_river => :environment do
    # Load up the models first so that the callbacks are added
    Dir[Rails.root + 'app/models/**/*.rb'].each { |model_path| require model_path }
    # Run callbacks
    num_callbacks = CouchrestModelElastic::CouchModelSearchable::SearchConfig.setup_callbacks.run!
    puts "#{num_callbacks} Elasticsearch Rivers initialized"
  end

  # Run our task after these tasks
  [:migrate, :migrate_with_proxies].each do |task_to_run_after|
    task(task_to_run_after).enhance do
      Rake::Task['couchrest:init_elasticsearch_river'].invoke
    end
  end
end
