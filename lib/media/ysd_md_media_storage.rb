require 'ysd_md_yito' unless defined?Yito::Model::Finder
module Media
  #
  # It represents a media storage and the credentials to access
  #	
  class Storage
    include DataMapper::Resource
    extend ::Yito::Model::Finder
    
    storage_names[:default] = 'media_storages'

    property :name, String, :length => 50, :key => true
    property :adapter, String, :length => 30              
    belongs_to :account, 'ExternalIntegration::ExternalServiceAccount', 
      :child_key => ['account_id'], :parent_key => ['id'], :required => false # The account to access

    #
    # Saves the media storage
    #
    def save
        
      if self.account and (not self.account.saved?)
        self.account = ExternalIntegration::ExternalServiceAccount.get(self.account.id)
      end
     
      super
    
    end    

    #
    # Gets the adapter to access the media storage
    #
    def get_adapter
      unless defined?(@_adapter)
        puts "creating adapter #{account.username} #{adapter}"
        #@_adapter = MediaIntegration::Adapters::PicasaAdapter.new(
        #	account.username, account.password) if self.adapter == 'picasa' and account
        @_adapter = MediaIntegration::Adapters::PicasaAdapter.new(
         account.username, ::CLIENT_ID, ::CLIENT_SECRET, ::REFRESH_TOKEN) if self.adapter == 'picasa' and account
        puts "created adapter #{account.username} #{adapter}"
      end
      @_adapter
    end

  end
end