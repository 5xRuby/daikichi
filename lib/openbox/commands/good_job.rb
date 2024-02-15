# frozen_string_literal: true

module Openbox
  module Commands
    class GoodJob < Openbox::Command
      def execute
        Openbox.database.ensure_connection!
        invoke Migrate unless ENV['AUTO_MIGRATION'].nil?
        exec('bundle exec good_job')
      end
    end
    if Openbox.runtime.has?('good_job')
      Openbox::Entrypoint.register(GoodJob, 'good_job', 'good_job',
                                   'Run rails good_job')
    end
  end
end
