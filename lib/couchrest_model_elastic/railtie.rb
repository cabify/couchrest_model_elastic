module CouchrestModelElastic
  class CouchrestModelElasticRailtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '../../tasks/*.rake')].each { |task| load task }
    end
  end
end