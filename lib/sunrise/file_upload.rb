module Sunrise
  module FileUpload
    mattr_accessor :base_path
    @@base_path = ''

    autoload :Http, 'sunrise/file_upload/http'
    autoload :Manager, 'sunrise/file_upload/manager'
    autoload :Request, 'sunrise/file_upload/request'
    autoload :ActiveRecord, 'sunrise/file_upload/active_record'
    autoload :Callbacks, 'sunrise/file_upload/callbacks'
    autoload :Asset, 'sunrise/file_upload/asset'
    autoload :AttachmentFile, 'sunrise/file_upload/attachment_file'
    autoload :FileSizeValidator, 'sunrise/file_upload/file_size_validator'
    autoload :Uploader, 'sunrise/file_upload/uploader'

    def self.guid
      ::SecureRandom.base64(15).tr('+/=', 'xyz').slice(0, 10)
    end

    def self.setup
      yield self
    end

  end
end

require 'sunrise/file_upload/engine'
