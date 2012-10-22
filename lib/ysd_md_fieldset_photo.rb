require 'ysd-plugins' unless defined?Plugins::ModelAspect

#
# It represents Photo information attached to a model
#
module FieldSet
  module Photo
      include ::Plugins::ModelAspect
      
      def self.included(model)
        model.property :photo_path, String, :field => 'photo_path', :length => 80
        model.property :photo_url_tiny, String, :field => 'photo_url_tiny', :length => 256
        model.property :photo_url_small, String, :field => 'photo_url_small', :length => 256
        model.property :photo_url_medium, String, :field => 'photo_url_medium', :length => 256
        model.property :photo_url_full, String, :field => 'photo_url_full', :length => 256
      end

  end #Photo
end #FieldSet
