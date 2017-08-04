require 'RMagick'
require 'adapters/ysd-photo_adapter_factory'
require 'adapters/ysd-photo_base_adapter'
require 'adapters/ysd-photo_filesystem_adapter'
require 'adapters/ysd-photo_s3_adapter'
require 'media/ysd_md_album'
require 'media/ysd_md_album_cover'
require 'media/ysd_md_photo'
require 'ysd_md_fieldset_album'
require 'ysd_md_fieldset_photo'

module Media
  extend Yito::Translation::ModelR18

  def self.r18n
    check_r18n!(:media_r18n, File.expand_path(File.join(File.dirname(__FILE__), '..', 'i18n')))
  end

  MEDIUM_SIZE = 288
  SMALL_SIZE = 144
  TINY_SIZE = 72

  ADAPTERS = {'filesystem' => r18n.t.adapters.filesystem,
  	          's3' => r18n.t.adapters.s3}
end	