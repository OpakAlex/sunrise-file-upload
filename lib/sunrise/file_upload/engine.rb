require 'rails'
require 'sunrise-file-upload'

module Sunrise
  module FileUpload
    class Engine < ::Rails::Engine
      # Initialize Rack file upload
      config.app_middleware.use Sunrise::FileUpload::Manager, :paths => "/sunrise/fileupload"
    
      config.before_initialize do
        ActiveSupport.on_load :active_record do
          ::ActiveRecord::Base.send :include, Sunrise::FileUpload::ActiveRecord
        end
      end
    end
  end
end

unless "".respond_to?(:each)
  String.class_eval do
    def each &block
      self.lines &block
    end
  end
end