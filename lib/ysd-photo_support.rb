require 'json'
module PhotoCollection
  module ToJSON
  
    def to_json(*a)
      
      hash = {}
      
      self.instance_variables.each do |var|          
        hash[var.to_s.delete("@")] = self.instance_variable_get(var)
      end
      
      hash.to_json(*a)	
    
    end  
    
  end
end