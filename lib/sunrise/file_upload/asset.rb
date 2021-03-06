module Sunrise
  module FileUpload
    module Asset
      extend ActiveSupport::Concern

      included do
        belongs_to :assetable, polymorphic: true

        # Store options for image manipulation
        attr_reader :cropper_geometry, :rotate_degrees

        delegate :url, :original_filename, to: :data

        class_attribute :thumb_size, :max_size
        self.thumb_size = :thumb
        self.max_size = 2

        before_save :reprocess

        alias_attribute :filename, :original_filename
        alias_attribute :size, :data_file_size
        alias_attribute :content_type, :data_content_type
      end

      module ClassMethods

        def sunrise_uploader(uploader=nil, options={}, &block)
          options = {mount_on: :data_file_name}.merge(options)

          mount_uploader(:data, uploader, options, &block)

          validates_processing_of :data
        end

        def validates_filesize_of(*attr_names)
          validates_with Sunrise::FileUpload::FileSizeValidator, _merge_attributes(attr_names)
        end

        def move_to(index, id)
          update_all(['sort_order = ?', index], ['id = ?', id.to_i])
        end

        def ext_list
          return unless uploaders[:data]
          uploaders[:data].new.extension_white_list
        end

        def clean!
          where(:created_at <= 1.week.ago).where('assetable_id IS NULL OR assetable_id = 0').destroy_all
        end
      end

      def thumb_url
        data.url(self.thumb_size) if image?
      end

      def format_created_at
        I18n.l(created_at, format: '%d.%m.%Y %H:%M')
      end

      def human_name
        original_name.presence || data_file_name
      end

      def as_json(options = nil)
        options = {
            only: [:id, :guid, :assetable_id, :assetable_type, :user_id,
                   :data_file_size, :data_content_type, :is_main, :original_name],
            root: 'asset',
            methods: [:filename, :url, :thumb_url, :width, :height]
        }.merge(options || {})

        super
      end

      def has_dimensions?
        respond_to?(:width) && respond_to?(:height)
      end

      def image?
        %w(image/jpeg image/png image/gif image/jpg image/pjpeg image/tiff image/x-png).include?(self.data_content_type)
      end

      def main!
        self.class.update_all('is_main=0', ['assetable_type=? AND assetable_id=? AND type=?', assetable_type, assetable_id, type])
        update_column(:is_main, true)
        refresh_assetable
        self
      end

      def rotate!
        rename!
        self.rotate_degrees = 90
        save!
        refresh_assetable
        self
      end

      def crop!(geometry)
        rename!
        self.cropper_geometry = geometry
        save!
        refresh_assetable
        self
      end

      def rename!
        rename
        save!
      end

      def rename
        file = data.file
        path = data.path
        ext = File.extname(path)
        new_path = File.join(File.dirname(path), "#{File.basename(path).chomp(ext)}_#{rand(99)}#{ext}")
        new_file = ::CarrierWave::SanitizedFile.new file.move_to(new_path)
        data.cache!(new_file)
      end

      def refresh_assetable
        return unless assetable.try(:persisted?)
        assetable.touch
        assetable.tire.update_index if assetable.respond_to?(:tire)
        true
      end

      def full_url(*args)
        host = Rails.application.config.action_mailer.default_url_options[:host] || 'www.example.com'
        "//#{host}#{data.url(*args)}"
      end

      def cropper_geometry=(value)
        geometry = (value || '').to_s.split(',')

        unless geometry.map(&:blank?).any?
          @cropper_geometry_changed = true
          @cropper_geometry = geometry
        end
      end

      def cropper_geometry_changed?
        @cropper_geometry_changed === true
      end

      def rotate_degrees=(value)
        unless value.blank?
          @rotate_degrees_changed = true
          @rotate_degrees = value.to_s
        end
      end

      def rotate_degrees_changed?
        @rotate_degrees_changed === true
      end

      protected

      def reprocess
        if cropper_geometry_changed? || rotate_degrees_changed?
          data.cache_stored_file!
        end
      end

    end
  end
end