require 'singleton' unless defined?Singleton
module Adapters

  class Factory
  	include Singleton

    def create_adapter(adapter_type)

      case adapter_type
      when 'filesystem'
      	# Todo (cloud or not cloud)
        FileSystemAdapter.new(File.join(File.expand_path($0).gsub($0,''), 'public', 'uploads'))
      when 's3'
      	S3Adapter.new(SystemConfiguration::SecureVariable.get_value('aws_api_key'),
      		          SystemConfiguration::SecureVariable.get_value('aws_secret_key'),
      		          SystemConfiguration::SecureVariable.get_value('bucket'))
      end	

    end	

  end

end