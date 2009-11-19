require 'net/http'
require 'uri'
require 'restfulie_marshal'
require 'transition'

module Restfulie
 
  def move_to(name)
    transitions = self.class._transitions_for(self.status.to_sym)[:allow]
    raise "Current state #{status} is invalid in order to execute #{name}. It must be one of #{transitions}" unless transitions.include? name
    result = self.class._transitions(name).result
    self.status = result.to_s unless result.nil?
  end
  
end

module ActiveRecord
  class TransitionInjector
  
    def define_methods_for(type, name, result) 
      
      return nil if type.respond_to?(name)
      
      type.send(:define_method, name) do |*args|
        self.status = result.to_s unless result == nil
      end
      
      type.send(:define_method, "can_#{name}?") do
        transitions = self.class._transitions_for(self.status.to_sym)[:allow]
        transitions.include? name
      end
      
    end
  
  end
  
  class Base

    include Restfulie
    attr_accessor :_possible_states
    attr_accessor :_came_from
    
    def self._transitions_for(state)
      @@states[state]
    end
    
    def self._transitions(name)
      transitions[name]
    end
    
    def self.transitions
      @transitions ||= {}
    end
    @@states = {}
    
    @@transition_controller = TransitionInjector.new

    def self.state(name, options = {})
      if name.class==Array
        name.each do |simple|
          self.state(simple, options)
        end
      else
        options[:allow] = [options[:allow]] unless options[:allow].class == Array
        @@states[name] = options
      end
    end

    def self.transition(name, options = {}, result = nil, &body)
      transition = Transition.new(name, options, result, body)
      transitions[name] = transition
      
      @@transition_controller.define_methods_for(self, name, result)
      controller_name = (self.name + "Controller")
    end

    def self.add_states(result, states)
      result._possible_states = {}
      states.each do |state|
        result._possible_states[state["rel"]] = state
      end
      
      ## TODO KUNG result.extend Module
      def result.respond_to?(sym)
        has_state(sym.to_s) || super(sym)
      end

      def result.has_state(name)
        !@_possible_states[name].nil?
      end
      
      states.each do |state|
        add_state(state)
      end
      
      result
    end
    
    def self.add_state(state)
      name = state["rel"]
      self.module_eval do
        def current_method
          caller[0]=~/`(.*?)'/
          $1
        end
        def temp_method(options = {}, &block)
          name = current_method
          state = _possible_states[name]
          url = URI.parse(state["href"])
          
          method_from = { "delete" => Net::HTTP::Delete,
                          "put" => Net::HTTP::Put,
                          "get" => Net::HTTP::Get,
                          "post" => Net::HTTP::Post}
          defaults = {'destroy' => Net::HTTP::Delete,'delete' => Net::HTTP::Delete,'cancel' => Net::HTTP::Delete,
                    'refresh' => Net::HTTP::Get, 'reload' => Net::HTTP::Get, 'show' => Net::HTTP::Get, 'latest' => Net::HTTP::Get
                    }

          req_type = method_from[options[:method]] if options[:method]
          req_type ||= defaults[name]
          req_type ||= Net::HTTP::Post
          
          get = req_type==Net::HTTP::Get
          req = req_type.new(url.path)
          


          req.body = options[:data] if options[:data]
          req.add_field("Accept", "text/xml") if _came_from == :xml

          http = Net::HTTP.new(url.host, url.port)
          response = http.request(req)
          return yield(response) if !block.nil?
          if get
            case response.content_type
            when "application/xml"
              content = response.body
              hash = Hash.from_xml content
              return hash if hash.keys.length == 0
              raise "unable to parse an xml with more than one root element" if hash.keys.length>1
              key = hash.keys[0]
              type = key.camelize.constantize
              return type.from_xml(content)
            else
              raise :unknown_content_type
            end
          end
          response

        end
        alias_method name, :temp_method
        undef :temp_method
      end
    end  
      

    def self.from_web(uri)
      url = URI.parse(uri)
      req = Net::HTTP::Get.new(url.path)
      http = Net::HTTP.new(url.host, url.port)
      res = http.request(req)
      raise :invalid_request, res if res.code != "200"
      case res.content_type
      when "application/xml"
        self.from_xml res.body
      when "application/json"
        self.from_json res.body
      else
        raise :unknown_content_type
      end
    end

    # basic code from Matt Pulver
    # found at http://www.xcombinator.com/2008/08/11/activerecord-from_xml-and-from_json-part-2/
    # addapted to support links
    def self.from_hash( hash )
      h = {}
      h = hash.dup if hash
      links = nil
      h.each do |key,value|
        case value.class.to_s
        when 'Array'
          if key=="link"
            links = h[key]
            h.delete("link")
          else
            h[key].map! { |e| reflect_on_association(key.to_sym ).klass.from_hash e }
          end
        when /\AHash(WithIndifferentAccess)?\Z/
          if key=="link"
            links = [h[key]]
            h.delete("link")
          else
            h[key] = reflect_on_association(key.to_sym ).klass.from_hash value
          end
        end
        h.delete("xmlns") if key=="xmlns"
      end
      result = self.new h
      add_states(result, links) unless links.nil?
      result
    end

    def self.from_json( json )
      from_hash safe_json_decode( json )
    end

    # The xml has a surrounding class tag (e.g. ship-to),
    # but the hash has no counterpart (e.g. 'ship_to' => {} )
    def self.from_xml( xml )
      hash = Hash.from_xml xml
      head = hash[self.to_s.underscore]
      result = self.from_hash head
      return nil if result.nil?
      result._came_from = :xml
      result
    end
  end
end

def safe_json_decode( json )
  return {} if !json
  begin
    ActiveSupport::JSON.decode json
  rescue ; {} end
end
# end of code based on Matt Pulver's