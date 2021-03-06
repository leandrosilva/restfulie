require 'net/http'
require 'uri'
require 'hashi'

require 'restfulie/media_type'
require 'restfulie/client/base'
require 'restfulie/client/entry_point'
require 'restfulie/client/helper'
require 'restfulie/client/instance'
require 'restfulie/client/request_execution'
require 'restfulie/client/state'

module Restfulie
  
  # Extends your class to support restfulie-client side's code.
  # This will extends Restfulie::Client::Base methods as class methods,
  # Restfulie::Client::Instance as instance methods and Restfulie::Unmarshalling as class methods.
  def uses_restfulie
    extend Restfulie::Client::Base
    include Restfulie::Client::Instance
    extend Restfulie::Unmarshalling
  end
  
end

Object.extend Restfulie

require 'restfulie/unmarshalling'
