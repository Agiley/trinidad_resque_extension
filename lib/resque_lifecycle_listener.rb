require File.expand_path('../resque_ext', __FILE__)

module Trinidad
  module Extensions
    module Resque
      require 'rake'
      require 'resque/tasks'

      class ResqueLifecycleListener
        include Trinidad::Tomcat::LifecycleListener

        def initialize(options)
          @options = options
        end

        def lifecycle_event(event)
          case event.type
          when Trinidad::Tomcat::Lifecycle::BEFORE_START_EVENT
            start_workers
          when Trinidad::Tomcat::Lifecycle::BEFORE_STOP_EVENT
            stop_workers
          end
        end

        def start_workers
          Thread.new do
            task = 'resque:work'

            if @options[:count]
              ENV['COUNT'] = @options[:count]
              task = 'resque:workers'
            end

            ENV['QUEUES'] ||= @options[:queues]

            ::Resque.redis = @options[:redis_host]

            load @options[:setup] if @options[:setup]
            Rake::Task[task].invoke
          end
        end

        def stop_workers
          ::Resque.workers.each { |w| w.shutdown! }
        end
      end
    end
  end
end