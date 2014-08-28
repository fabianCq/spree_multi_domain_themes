module SpreeMultiDomainThemes
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_multi_domain_themes'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    rake_tasks do
      %w{precompile_multi_theme}.each { |r| load File.join([File.dirname(__FILE__) , "../../tasks/#{r}.rake"]) }
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../../lib/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    initializer "include theme path for rendering" do |app|
      ActionController::Base.class_eval do

        before_filter do
          # here we set the view paths and tell deface to also use the correct view_paths.
          # We activate the Deface railtie so that it reloads all it's overrides
          if Rails.env != 'production'
            set_view_paths
            Deface::TemplateHelper.view_paths = view_paths
            Deface::Railtie.activate
          end
        end

        def _prefixes_with_store_template
          _prefixes_without_store_template
          store_template = "spree/#{controller_name}/#{current_store.group}"
          @_prefixes.unshift(store_template) unless @_prefixes.include?(store_template)
          group_template = "spree/#{controller_name}/#{current_store.group}/#{current_store.code}"
          @_prefixes.unshift(group_template) unless @_prefixes.include?(group_template)
          @_prefixes
        end
        alias_method_chain :_prefixes, :store_template
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end