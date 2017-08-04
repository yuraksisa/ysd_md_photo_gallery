module Adapters
  class BaseAdapter
    protected
    #
    # Get the server name folder to store the images
    #
    def self.server_name_folder
      if RequestStore.store[:media_server_name_folder]
        do_apply_server_name_folder = SystemConfiguration::Variable.get_value('media.use_server_name_folder','false').to_bool
        if do_apply_server_name_folder
          return RequestStore.store[:media_server_name_folder]
        end
      end
    end
  end
end